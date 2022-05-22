this.script_fight_screen <- ::inherit("scripts/mods/msu/ui_screen", {
	m = {
		ID = "ScriptFightScreen"
	},
	
	function show()
	{
		local activeState = ::MSU.Utils.getActiveState();
		activeState.onHide();
		switch(activeState.ClassName)
		{
			case "world_state":
				activeState.setAutoPause(true);
				activeState.m.MenuStack.push(function ()
				{
					::ScriptFight.Screen.hide();
					this.onShow();
					this.setAutoPause(false);
				});
				break;

			case "main_menu_state":
				activeState.m.MenuStack.push(function ()
				{
					::ScriptFight.Screen.hide();
					this.onShow();
				});
				break;
		}
		this.Tooltip.hide();
		this.m.JSHandle.asyncCall("setData", this.queryData());
		this.m.JSHandle.asyncCall("show", null);
		return false;
	}

	function hide()
	{
		if (this.isVisible())
		{
			local activeState = ::MSU.Utils.getActiveState();
			this.m.JSHandle.asyncCall("hide", null);
			activeState.m.MenuStack.pop();
			return false
		}
	}

	function toggle()
	{
		if(this.m.Animating)
		{
			return false
		}

		if (this.isVisible())
		{
			this.hide();
		}
		else
		{
			this.show();
		}
		return true;
	}

	function queryData()
	{
		local ret = {
			AllUnits = this.querySpawnlistMaster(),
			AllFactions =  this.queryFactions(),
			AllSpawnlists = this.querySpawnlists(),
			AllBaseTerrains = this.queryTerrains(),
			AllLocationTerrains = this.queryTerrainLocations(),
			Factions = {
				ID = "",
				Spawnlists = "",
			}
		}
		return ret;
	}

	function querySpawnlistMaster()
	{
		// clone it
		local ret = clone ::Const.World.Spawn.Troops;
		foreach (id, unit in ret)
		{	
			unit.Name <- ::Const.Strings.EntityName[unit.ID];
			unit.Icon <- ::Const.EntityIcon[unit.ID];
		}
		return ret;
	}

	function queryFactions()
	{
		return clone ::Const.FactionType;
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

	function onCancelButtonPressed()
	{
		this.hide()
	}

	function onOkButtonPressed(_data)
	{
		this.hide();
		this.startFight(_data);
	}

	function startFight(_data)
	{
		// local properties = this.Const.Tactical.CombatInfo.getClone();
		// local tile = this.World.getTile(this.World.worldToTile(_pos));
		// local isAtUniqueLocation = false;
		// properties.TerrainTemplate = this.Const.World.TerrainTacticalTemplate[tile.TacticalType];
		// properties.Tile = tile;
		// properties.InCombatAlready = false;
		// properties.IsAttackingLocation = false;
		local p = this.Const.Tactical.CombatInfo.getClone();
		p.Tile = this.World.State.getPlayer().getTile();
		p.TerrainTemplate = _data.Settings.Terrain;
		if(_data.Settings.Map != "")
		{
			p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
			p.LocationTemplate.Template[0] = _data.Settings.Map;
			p.LocationTemplate.OwnedByFaction = this.Const.Faction.Enemy;
		}
		// local p = this.World.State.getLocalCombatProperties(this.World.State.getPlayer().getPos());
		p.Entities = [];
		p.CombatID = "ScriptedFight";
		p.Music = this.Const.Music.OrcsTracks;
		p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.IsAutoAssigningBases = false;
		p.IsFogOfWarVisible = false;
		p.IsUsingSetPlayers = !_data.Settings.UsePlayer;
		p.WithoutPlayer <- !_data.Settings.UsePlayer;
		
		::ScriptFight.WithoutPlayer = !_data.Settings.UsePlayer;
		foreach(spawnlist in _data.Player.Spawnlists)
		{
			this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn[spawnlist.ID], spawnlist.Resources.tointeger() , this.Const.Faction.PlayerAnimals);
		}
		foreach(spawnlist in _data.Enemy.Spawnlists)
		{
			this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn[spawnlist.ID], spawnlist.Resources.tointeger(), this.Const.Faction.Enemy);
		}
		this.addUnitsToCombat(_data.Player.Units, p.Entities, this.Const.Faction.PlayerAnimals);
		this.addUnitsToCombat(_data.Enemy.Units, p.Entities, this.Const.Faction.Enemy);
		this.World.State.startScriptedCombat(p, false, false, true);
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
					if (!this.Const.DLC.Wildmen || this.Math.rand(1, 100) > unit.Variant)
					{
						unit.Variant = 0;
					}
					else
					{
						unit.Strength = this.Math.round(unit.Strength * 1.35);
						unit.Variant = this.Math.rand(1, 255);

						if ("NameList" in t.Type)
						{
							unit.Name = this.generateName(t.Type.NameList) + (t.Type.TitleList != null ? " " + t.Type.TitleList[this.Math.rand(0, t.Type.TitleList.len() - 1)] : "");
						}
					}
				}

				_into.push(unit);
			}
		}
	}
});

