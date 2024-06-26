this.combat_simulator_setup <- {
	m = {
		CustomFactions = {
			"faction-0" : {
			    ID = "faction-0",
			    ControlUnits = false,
			},
			"faction-1" : {
			    ID = "faction-1",
			    ControlUnits = false,
			},
			"faction-2" : {
			    ID = "faction-2",
			    ControlUnits = false,
			},
			"faction-3" : {
			    ID = "faction-3",
			    ControlUnits = false,
			}
		}
		RosterID = ::Math.abs(toHash(::CombatSimulator.ID))
		Roster = null
	},

	function createRoster()
	{
		::World.deleteRoster(this.m.RosterID);
		this.m.Roster = ::World.createRoster(this.m.RosterID);
	}

	function getRoster()
	{
		return this.m.Roster;
	}

	function querySpawnlistMaster()
	{
		// clone it
		local ret = {};

		foreach (id, unit in ::Const.World.Spawn.Troops)
		{	
			ret[id] <- clone unit;
			ret[id].Key <- id;
			ret[id].DisplayName <- id;
			ret[id].Icon <- ::Const.EntityIcon[unit.ID];
		}
		return ret;
	}

	function queryFactions()
	{
		return clone ::Const.FactionType;
	}

	function queryBrothers()
	{
		local ret = {};
		local players = ::World.getPlayerRoster().getAll();
		foreach (bro in players)
		{
			ret[bro.getID().tostring()] <- {
				ID = bro.getID(),
				DisplayName = bro.getName(),
				Icon = bro.getBackground().getIcon()
			}
		}
		return ret;
	}

	function querySpawnlists()
	{
		local ret = {};
		foreach(id, list in ::Const.World.Spawn)
		{
			ret[id] <- {
				id = id,
				list = clone list
			}
		}
		return ret;
	}

	function queryTerrains()
	{
		local ret = ["flat_sand_combatsimulator", "flat_snow_combatsimulator", "flat_grass_combatsimulator"];
		ret.extend(clone ::Const.World.TerrainTacticalTemplate);
		return ret;
	}

	function queryTracklist()
	{
		return clone ::CombatSimulator.Const.TrackList
	}

	function queryTerrainLocations()
	{
		local ret = [];
		local locSplit, locFinal;
		foreach(key in ::IO.enumerateFiles("scripts/mapgen/templates/tactical/locations"))
		{
			locSplit = split(key, "/");
			locSplit = locSplit[locSplit.len()-1];
			locSplit = split(locSplit, "_");
			locFinal = locSplit.remove(0) + "." + locSplit.remove(0);
			while(locSplit.len() > 0)
			{
				locFinal += "_" + locSplit.remove(0)
			}
			ret.push(locFinal);
		}
		return ret;
	}

	function setupFight(_data)
	{
		this.createRoster();
		local old_spawnEntity = this.Tactical.spawnEntity;
		this.Tactical.spawnEntity = function(...)
		{
			if (typeof vargv[0] == "string")
			{
				vargv.insert(0, this);
				return old_spawnEntity.acall(vargv);
			}

			this.Tactical.addEntityToMap(vargv[0], vargv[1], vargv[2]);
			return vargv[0];
		}
		local p = this.Const.Tactical.CombatInfo.getClone();
		p.Tile = this.World.State.getPlayer().getTile();
		p.TerrainTemplate = _data.Settings.Terrain;
		if(_data.Settings.Map != "")
		{
			if(_data.Settings.Map != "tactical.arena_floor") p.IsAttackingLocation = true;
			p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
			p.LocationTemplate.Template[0] = _data.Settings.Map;
			p.LocationTemplate.OwnedByFaction = this.Const.Faction.Enemy;
			p.LocationTemplate.CutDownTrees <- _data.Settings.CutDownTrees;
			p.LocationTemplate.Fortification = _data.Settings.Fortification ? this.Const.Tactical.FortificationType.Palisade : this.Const.Tactical.FortificationType.None;
		}
		p.CombatID = "CombatSimulator";
		p.Music = this.Const.Music[_data.Settings.MusicTrack];	
		p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.IsAutoAssigningBases = false;
		p.IsFleeingProhibited = _data.Settings.IsFleeingProhibited;
		p.StartEmptyMode <- true;
		p.IsUsingSetPlayers = true;


		// Use noble factions so that noble units dont break when they look for banner
		p.CustomFactions <- {};
		this.setupFactions(p);

		if (_data.Settings.SpawnCompany)
		{
			this.addCompanyToBattle(p.Players, p.CustomFactions["faction-0"]);
			p.StartEmptyMode = false;
		}

		local controlUnits = false;
		foreach (idx, faction in p.CustomFactions)
		{
			if (faction.m.ControlUnits)
				controlUnits = true;
			if (p.StartEmptyMode && _data.Factions[idx].Spawnlists.len() != 0 || _data.Factions[idx].Units.len() != 0 || _data.Factions[idx].Bros.len() != 0)
			{
				p.StartEmptyMode = false;
			}
			foreach(spawnlist in _data.Factions[idx].Spawnlists)
			{
				this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn[spawnlist.ID], spawnlist.Resources.tointeger() , faction.getID());
			}
			this.addUnitsToCombat(_data.Factions[idx].Units, p.Entities, faction.getID());
			this.addBrosToCombat(_data.Factions[idx].Bros, p.Entities, faction.getID());
		}
		
		if (!controlUnits)
		{
			::CombatSimulator.Screen.getButton("UnlockCamera").setValue(true);
			::CombatSimulator.Screen.getButton("FOV").setValue(false);
			p.IsFogOfWarVisible = false;
		}
		this.World.State.startScriptedCombat(p, false, false, true);
	}

	function addCompanyToBattle(_broArray, _faction)
	{
		local num = 0;
		foreach( bro in ::World.getPlayerRoster().getAll() )
		{
			if (bro.getPlaceInFormation() > 17)
				continue;

			if (num++ >= this.World.Assets.getBrothersMaxInCombat())
				break;

			local broClone = this.cloneBro(bro);
			broClone.setFaction(_faction.getID())
			this.setupBro(broClone);
			_broArray.push(broClone);
		}
	}
	
	function setupFactions(_properties, _tacticalActive = false)
	{
		foreach(id, faction in this.m.CustomFactions)
		{
			_properties.CustomFactions[id] <- ::WeakTableRef(createFaction(_tacticalActive, faction));
		}
	}

	function createFaction(_tacticalActive, _faction)
	{
		local a = ::MSU.Array.rand(::Const.FactionArchetypes[0])
		local f = this.new("scripts/factions/noble_faction");
		local banner = this.Math.rand(2, 10);
		local name = this.Const.Strings.NobleHouseNames[this.Math.rand(0, this.Const.Strings.NobleHouseNames.len() - 1)];
		f.m.CustomID <- _faction.ID;
		f.setID( this.World.FactionManager.m.Factions.len());
		f.setName(name);
		f.setMotto("\"" + a.Mottos[this.Math.rand(0, a.Mottos.len() - 1)] + "\"");
		f.setDescription(a.Description);
		f.setBanner(banner);
		f.setDiscovered(true);
		f.m.PlayerRelation = _faction.ID == "faction-0" ? 100.0 : 0;
		f.m.ControlUnits <- _faction.ControlUnits
		f.updatePlayerRelation();
		this.World.FactionManager.m.Factions.push(f);
		// If spawn screen is used during a normal fight, we need to add these empty arrays
		if (_tacticalActive)
		{
			this.Tactical.Entities.m.Instances.push([]);
			this.Tactical.Entities.m.InstancesMax.push(0.0);
			local s = this.new("scripts/ai/tactical/strategy");
			s.setFaction(f);
			this.Tactical.Entities.m.Strategies.push(s);
		}
		return f;
	}

	function removeFactions()
	{
		if (this.World == null || this.World.FactionManager == null)
			return;

		for(local idx = this.World.FactionManager.m.Factions.len()-1; idx != 0; idx--)
		{
			local faction = this.World.FactionManager.m.Factions[idx];
			if(faction != null && "CustomID" in faction.m)
			{
				this.World.FactionManager.m.Factions.remove(idx);
			}
		}
	}

	function addUnitsToCombat(_units, _into, _faction)
	{
		foreach( t in _units )
		{
			t.Type = ::Const.World.Spawn.Troops[t.Type];
			t.Num = t.Num.tointeger();
			for( local i = 0; i < t.Num; i++ )
			{
				local unit = clone t.Type;
				unit.Faction <- _faction;
				unit.Name <- "";

				if (unit.Variant > 0)
				{
					if (!this.Const.DLC.Wildmen || (!t.Champion && this.Math.rand(1, 100) > unit.Variant))
					{
						unit.Variant = 0;
					}
					else
					{
						unit.Strength = this.Math.round(unit.Strength * 1.35);
						unit.Variant = this.Math.rand(1, 255);

						if ("NameList" in t.Type)
						{
							unit.Name = ::Const.World.Common.generateName(t.Type.NameList) + (t.Type.TitleList != null ? " " + t.Type.TitleList[this.Math.rand(0, t.Type.TitleList.len() - 1)] : "");
						}
					}
				}

				_into.push(unit);
			}
		}
	}

	function addBrosToCombat(_units, _into, _faction)
	{
		foreach (brother in _units)
		{
			for (local i = 0; i < brother.Num.tointeger(); ++i)
			{
				local bro = this.Tactical.getEntityByID(brother.ID);
				if (bro == null)
				{
					::logError("CombatSimulator: failed to find bro with ID " + brother.ID);
					continue;
				}
				local broClone = this.cloneBro(bro);
				local unit = {
					Faction = _faction,
					Type = "CombatSimBroClone",
					Variant = 0,
					Strength = 0,
					Num = 1,
					Row = bro.getPlaceInFormation() > 9 ? 1 : 0,
					NameList = ["abc"],
					TitleList = null,
				}
				unit.Script <- broClone;
				_into.push(unit)	
			}
		}
	}

	function cloneBro(_bro)
	{
		local roster = this.getRoster();
		local broClone = roster.create("scripts/entity/tactical/player_clone");
		local flags = ::new("scripts/tools/tag_collection")
		local serEm = ::CombatSimulator.Mod.Serialization.getSerializationEmulator("abc", flags)
		_bro.onSerialize(serEm);
		local deSerEm = ::CombatSimulator.Mod.Serialization.getDeserializationEmulator("abc", flags)
		deSerEm.loadDataFromFlagContainer();
		broClone.onDeserialize(deSerEm);

		broClone.getBackground().setAppearance();
		return broClone;
	}

	function setupEntity(_e)
	{
		if (!::CombatSimulator.isCombatSimulatorFight())
			return;
		if (::isKindOf(_e, "player_clone"))
			return this.setupBro(_e);
		local faction = ::World.FactionManager.getFaction(_e.getFaction())

		if (faction.m.ControlUnits)
		{
			if(!_e.m.IsControlledByPlayer)
			{
				_e.m.IsControlledByPlayer = true;
				_e.isPlayerControlled = function()
				{
					return true;
				}
				_e.m.IsGuest <- true;
				_e.isGuest <- function(){
					return this.m.IsGuest;
				}
				
				_e.onCombatStart <- function(){};
				this.addPlayerAgentToEntity(_e);
			}
		} 
		else
		{
			_e.m.IsControlledByPlayer <- false;
			_e.m.IsGuest <- false;
			_e.isPlayerControlled = function()
			{
				return this.getFaction() == this.Const.Faction.Player && this.m.IsControlledByPlayer;
			}
			this.removePlayerAgentFromEntity(_e);
		}
		// if("Tail" in _e.m)
		// {
		// 	_e.m.Tail.setFaction(this.Const.Faction.PlayerAnimals);
		// }

		if (faction.isAlliedWithPlayer())
		{
			// basically false turns them left for humans and right for beasts because rap pls
			// so it's wrong for humans, but we rely on onFactionChanged to change them back
			foreach(key in ::CombatSimulator.Const.SpriteList)
			{
				if (_e.hasSprite(key))
				{
					_e.getSprite(key).setHorizontalFlipping(true);
				}
			}
			_e.onFactionChanged();
		}
	}

	function addPlayerAgentToEntity(_entity)
	{
		if ("combatsim_AIAgent" in _entity.m)
			return;

		_entity.m.combatsim_AIAgent <- _entity.m.AIAgent.ClassNameHash;
		_entity.m.AIAgent.m.Actor = null;
		_entity.m.AIAgent = this.new("scripts/ai/tactical/player_agent");
		_entity.m.AIAgent.setActor(_entity);
	}

	function removePlayerAgentFromEntity(_entity)
	{
		if (!("combatsim_AIAgent" in _entity.m))
			return;

		_entity.m.AIAgent = ::new(this.IO.scriptFilenameByHash(_entity.m.combatsim_AIAgent));
		_entity.m.AIAgent.setActor(_entity);
		delete _entity.m.combatsim_AIAgent;
	}

	function setupBro(_bro)
	{
		local faction = ::World.FactionManager.getFaction(_bro.getFaction());
		if(faction.m.ControlUnits)
		{
			_bro.m.IsControlledByPlayer = true;
			if (_bro.m.AIAgent != null)
				_bro.m.AIAgent.m.Actor = null;
			_bro.m.AIAgent = this.new("scripts/ai/tactical/player_agent");
			_bro.m.AIAgent.setActor(_bro);
		}
		else
		{
			_bro.m.IsControlledByPlayer = false;
			if (_bro.m.AIAgent != null)
				_bro.m.AIAgent.m.Actor = null;
			_bro.m.AIAgent = this.new("scripts/ai/tactical/agents/charmed_player_agent");
			_bro.m.AIAgent.setActor(_bro);
		}
		return _bro;
	}

	function updatePlayerVisibility()
	{
		if (!::CombatSimulator.isCombatSimulatorFight() || !::MSU.Utils.getState("tactical_state").m.IsFogOfWarVisible)
			return;

		this.Tactical.fillVisibility(this.Const.Faction.Player, false);
		foreach (idx, faction in this.Tactical.State.getStrategicProperties().CustomFactions)
		{
			if (!faction.m.ControlUnits)
				continue;
			local units = this.Tactical.Entities.getInstancesOfFaction(faction.getID());

			foreach( i, unit in units )
			{
				if (faction.m.ControlUnits)
					unit.updateVisibility(unit.getTile(), unit.m.CurrentProperties.getVision(), this.Const.Faction.Player);
			}
		}
	}

	function updateFactionProperty(_data)
	{
		local id = _data[0];
		local property = _data[1];
		local value = _data[2];
		this.m.CustomFactions[id][property] = _data[2];
		if (property == "ControlUnits" && ::MSU.Utils.getActiveState().ClassName == "tactical_state")
		{
			local faction = this.Tactical.State.getStrategicProperties().CustomFactions[id];
			faction.m.ControlUnits <- value;
			foreach(unit in this.Tactical.Entities.getInstancesOfFaction(faction.getID()))
			{
				this.setupEntity(unit);
			}
		}
	}

	function cleanupAfterFight()
	{
		::CombatSimulator.Screen.resetButtonValues();		
		this.removeFactions();
		if (this.m.Roster != null)
			this.m.Roster.clear();
	}
}