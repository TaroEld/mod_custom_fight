this.custom_fight_screen <- ::inherit("scripts/mods/msu/ui_screen", {
	m = {
		ID = "CustomFightScreen"
	},
	
	function show()
	{
		local activeState = ::MSU.Utils.getActiveState();
		activeState.onHide();
		this.Cursor.setCursor(this.Const.UI.Cursor.Hand);
		switch(activeState.ClassName)
		{
			case "world_state":
				activeState.setAutoPause(true);
				activeState.m.MenuStack.push(function ()
				{
					::CustomFight.Screen.hide();
					this.onShow();
					this.setAutoPause(false);
				});
				break;

			case "main_menu_state":
				activeState.m.MenuStack.push(function ()
				{
					::CustomFight.Screen.hide();
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

	function onTopBarButtonPressed(_buttonType)
	{
		// manual is true when the button was clicked instead of hotkey
		switch(_buttonType)
		{
			case "Pause":
				this.onPausePressed(true);
				break;

			case "FOV":
				this.onFOVPressed(true);
				break;

			case "FinishFight":
				this.onFinishFightPressed()
				break;

			default:
				this.onGenericPressed(_buttonType, true)
				break;
		}		
	}

	function onPausePressed(_manual = false)
	{
		local state = ::MSU.Utils.getState("tactical_state")
		state.setPause(!state.m.IsGamePaused);
		
		if(state.m.IsGamePaused)
		{
			this.Tactical.EventLog.log("[color=#1e468f]Game is now paused.[/color]");
		}
		else
		{
			this.Tactical.EventLog.log("[color=#8f1e1e]Game is now unpaused.[/color]");
		}
		this.m.JSHandle.asyncCall("setTopBarButtonState", ["Pause", state.m.IsGamePaused, _manual]);
		return state.m.IsGamePaused;
	}

	function onFOVPressed(_manual = false)
	{
		local state = ::MSU.Utils.getState("tactical_state");
		state.m.IsFogOfWarVisible = !state.m.IsFogOfWarVisible;

		if (state.m.IsFogOfWarVisible)
		{
			this.Tactical.fillVisibility(this.Const.Faction.Player, false);
			local heroes = this.Tactical.Entities.getInstancesOfFaction(this.Const.Faction.Player);

			foreach( i, hero in heroes )
			{
				hero.updateVisibilityForFaction();
			}

			if (this.Tactical.TurnSequenceBar.getActiveEntity() != null)
			{
				this.Tactical.TurnSequenceBar.getActiveEntity().updateVisibilityForFaction();
			}
			this.Tactical.EventLog.log("[color=#1e468f]FOV is now visible.[/color]");
		}
		else
		{
			this.Tactical.fillVisibility(this.Const.Faction.Player, true);
			this.Tactical.EventLog.log("[color=#1e468f]FOV is no longer visible.[/color]");
		}
		this.m.JSHandle.asyncCall("setTopBarButtonState", ["FOV", state.m.IsFogOfWarVisible, _manual]);
		return state.m.IsFogOfWarVisible;
	}

	function onFinishFightPressed()
	{
		local state = ::MSU.Utils.getState("tactical_state");
		state.exitTactical();
	}

	function onGenericPressed(_buttonType, _manual = false)
	{
		local properties = this.Tactical.State.getStrategicProperties();
		properties[_buttonType] = !properties[_buttonType];
		this.Tactical.EventLog.log(_buttonType + " is now " + properties[_buttonType]);
		this.m.JSHandle.asyncCall("setTopBarButtonState", [_buttonType, properties[_buttonType], _manual]);
	}


	function startFight(_data)
	{
		local p = this.Const.Tactical.CombatInfo.getClone();
		p.Tile = this.World.State.getPlayer().getTile();
		local noble
		p.TerrainTemplate = _data.Settings.Terrain;
		if(_data.Settings.Map != "")
		{
			p.LocationTemplate = clone this.Const.Tactical.LocationTemplate;
			p.LocationTemplate.Template[0] = _data.Settings.Map;
			p.LocationTemplate.OwnedByFaction = this.Const.Faction.Enemy;
		}
		p.Entities = [];
		p.CombatID = "CustomFight";
		p.Music = this.Const.Music.OrcsTracks;
		p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.IsAutoAssigningBases = false;
		p.IsFogOfWarVisible = _data.Settings.SpectatorMode;

		p.IsUsingSetPlayers = _data.Settings.SpectatorMode;
		p.SpectatorMode <- _data.Settings.SpectatorMode;
		p.StartEmptyMode <- _data.Settings.StartEmptyMode;
		p.ControlAllies <- _data.Settings.ControlAllies;
		p.UnlockCamera <- false;
		p.ManualTurns <- false;
		p.FOV <- true;
		p.Pause <- false;

		// Use noble factions so that noble units dont break when they look for banner
		local nobleFactionAlly = this.World.FactionManager.getFactionsOfType(this.Const.FactionType.NobleHouse)[0];
		local nobleFactionEnemy = this.World.FactionManager.getFactionsOfType(this.Const.FactionType.NobleHouse)[1];
		p.NobleFactionAlly <- {
			Ref = nobleFactionAlly,
			Relation = nobleFactionAlly.m.PlayerRelation,
			OtherFactionFriendly = nobleFactionAlly.isAlliedWith(nobleFactionEnemy.getID())
		}
		p.NobleFactionEnemy <- {
			Ref = nobleFactionEnemy,
			Relation = nobleFactionEnemy.m.PlayerRelation,
			OtherFactionFriendly = nobleFactionEnemy.isAlliedWith(nobleFactionAlly.getID())
		}
		nobleFactionAlly.m.PlayerRelation = 100.0;
		nobleFactionAlly.updatePlayerRelation();
		nobleFactionAlly.removeAlly(nobleFactionEnemy.getID());
		nobleFactionEnemy.m.PlayerRelation = 0.0;
		nobleFactionEnemy.updatePlayerRelation();
		nobleFactionEnemy.removeAlly(nobleFactionAlly.getID());



		foreach(spawnlist in _data.Player.Spawnlists)
		{
			this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn[spawnlist.ID], spawnlist.Resources.tointeger() , nobleFactionAlly.getID());
		}
		foreach(spawnlist in _data.Enemy.Spawnlists)
		{
			this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn[spawnlist.ID], spawnlist.Resources.tointeger(), nobleFactionEnemy.getID());
		}
		local playerFaction = this.Const.Faction.PlayerAnimals;
		this.addUnitsToCombat(_data.Player.Units, p.Entities, nobleFactionAlly.getID());
		this.addUnitsToCombat(_data.Enemy.Units, p.Entities, nobleFactionEnemy.getID());
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
});

