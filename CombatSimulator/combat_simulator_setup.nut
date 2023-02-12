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
	},

	function queryData()
	{
		local ret = {
			AllUnits = this.querySpawnlistMaster(),
			AllFactions =  this.queryFactions(),
			AllBrothers =  this.queryBrothers(),
			AllSpawnlists = this.querySpawnlists(),
			AllBaseTerrains = this.queryTerrains(),
			AllLocationTerrains = this.queryTerrainLocations(),
			AllMusicTracks =this.queryTracklist(),
		}
		return ret;
	}

	function querySpawnlistMaster()
	{
		// clone it
		local ret = {};

		foreach (id, unit in ::Const.World.Spawn.Troops)
		{	
			ret[id] <- clone unit;
			ret[id].DisplayName <- ::Const.Strings.EntityName[unit.ID];
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
				DisplayName = bro.getName()
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
		return clone ::Const.World.TerrainTacticalTemplate
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
		p.Entities = [];
		p.CustomFactions <- {};
		p.CombatID = "CombatSimulator";
		p.Music = this.Const.Music[_data.Settings.MusicTrack];	

		// Use noble factions so that noble units dont break when they look for banner
		this.setupFactions(p);

		local hasBroInPlayerFaction = _data.Factions["faction-0"].Bros.len() > 0;
		if (hasBroInPlayerFaction)
			_data.Settings.SpectatorMode = false;
		p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.IsAutoAssigningBases = false;
		p.IsFogOfWarVisible = !_data.Settings.SpectatorMode;
		p.IsFleeingProhibited = _data.Settings.IsFleeingProhibited;

		p.IsUsingSetPlayers = hasBroInPlayerFaction;
		p.SpectatorMode <- _data.Settings.SpectatorMode;
		if (p.SpectatorMode)
		{
			this.getButton("UnlockCamera").setValue(true);
			this.getButton("FOV").setValue(false);
		}

		p.StartEmptyMode <- true;
		foreach (idx, faction in p.CustomFactions)
		{
			if (_data.Factions[idx].Spawnlists.len() != 0 || _data.Factions[idx].Units.len() != 0 || _data.Factions[idx].Bros.len() != 0)
			{
				p.StartEmptyMode <- false;
			}
			foreach(spawnlist in _data.Factions[idx].Spawnlists)
			{
				this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn[spawnlist.ID], spawnlist.Resources.tointeger() , faction.getID());
			}
			this.addUnitsToCombat(_data.Factions[idx].Units, p.Entities, faction.getID());
			this.addBrosToCombat(_data.Factions[idx].Bros, faction.m.CustomID == "faction-0" ? p.Players : p.Entities, faction.getID());
		}
		this.World.State.startScriptedCombat(p, false, false, true);
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
		foreach (bro in _units)
		{
			local bro = this.Tactical.getEntityByID(bro.ID);
			_into.push(bro)
		}
	}

	function setupEntity(_e)
	{
		local properties = this.Tactical.State.getStrategicProperties();
		if (properties.CombatID != "CombatSimulator") return;
		local faction = ::World.FactionManager.getFaction(_e.getFaction())

		if (faction.m.ControlUnits)
		{
			if(!_e.m.IsControlledByPlayer)
			{
				_e.m.old_AIAgent <- _e.m.AIAgent;
				_e.m.old_AIAgent.setActor(null);
				_e.m.AIAgent = this.new("scripts/ai/tactical/player_agent");
				_e.m.AIAgent.setActor(_e);
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
			}
		} 
		else
		{
			if("old_AIAgent" in _e.m)
			{
				_e.m.AIAgent = _e.m.old_AIAgent;
				_e.m.AIAgent.setActor(_e);
				delete _e.m.old_AIAgent
			}
			_e.m.IsControlledByPlayer <- false;
			_e.m.IsGuest <- false;
			_e.isPlayerControlled = function()
			{
				return this.getFaction() == this.Const.Faction.Player && this.m.IsControlledByPlayer;
			}
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
}