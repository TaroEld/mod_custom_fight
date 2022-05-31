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
		this.isVisible() ? this.hide() : this.show();
		return true;
	}

	function onCancelButtonPressed()
	{
		this.hide();
	}

	function onOkButtonPressed(_data)
	{
		this.hide();
		this.startFight(_data);
	}

	function onTopBarButtonPressed(_buttonType)
	{
		// manual is true when the button was clicked instead of hotkey
		local properties = this.Tactical.State.getStrategicProperties();
		if (properties.CombatID != "CustomFight" && ::CustomFight.Mod.ModSettings.getSetting("AllowSettings").getValue() == false)
			return

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

	function setTopBarButtonsDisplay(_bool)
	{
		this.m.JSHandle.asyncCall("setTopBarButtonsDisplay", _bool);
	}

	function startFight(_data)
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
		::MSU.Log.printData(p.LocationTemplate, 2)
		p.Entities = [];
		p.CombatID = "CustomFight";
		p.Music = this.Const.Music[_data.Settings.MusicTrack];
		p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.IsAutoAssigningBases = false;
		p.IsFogOfWarVisible = _data.Settings.SpectatorMode;
		p.IsFleeingProhibited = _data.Settings.IsFleeingProhibited;

		p.IsUsingSetPlayers = _data.Settings.SpectatorMode;
		p.SpectatorMode <- _data.Settings.SpectatorMode;
		p.StartEmptyMode <- _data.Settings.StartEmptyMode;
		p.ControlAllies <- _data.Settings.ControlAllies;
		p.UnlockCamera <- false;
		p.ManualTurns <- false;
		p.FOV <- true;
		p.Pause <- false;

		// Use noble factions so that noble units dont break when they look for banner
		::CustomFight.Setup.setupFactions(p)


		foreach(spawnlist in _data.Player.Spawnlists)
		{
			this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn[spawnlist.ID], spawnlist.Resources.tointeger() , p.NobleFactionAlly.getID());
		}
		foreach(spawnlist in _data.Enemy.Spawnlists)
		{
			this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn[spawnlist.ID], spawnlist.Resources.tointeger(), p.NobleFactionEnemy.getID());
		}
		local playerFaction = this.Const.Faction.PlayerAnimals;
		::CustomFight.Setup.addUnitsToCombat(_data.Player.Units, p.Entities, p.NobleFactionAlly.getID());
		::CustomFight.Setup.addUnitsToCombat(_data.Enemy.Units, p.Entities, p.NobleFactionEnemy.getID());
		this.World.State.startScriptedCombat(p, false, false, true);
	}

	function queryData()
	{
		local ret = {
			AllUnits = ::CustomFight.Setup.querySpawnlistMaster(),
			AllFactions =  ::CustomFight.Setup.queryFactions(),
			AllSpawnlists = ::CustomFight.Setup.querySpawnlists(),
			AllBaseTerrains = ::CustomFight.Setup.queryTerrains(),
			AllLocationTerrains = ::CustomFight.Setup.queryTerrainLocations(),
			AllMusicTracks =::CustomFight.Setup.queryTracklist(),
		}
		return ret;
	}
});

