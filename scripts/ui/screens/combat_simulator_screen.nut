this.combat_simulator_screen <- ::inherit("scripts/mods/msu/ui_screen", {
	m = {
		ID = "CombatSimulatorScreen",
		ButtonDelegate = {
			function toggleSettingValue()
			{
				this.setValue(!this.CurrentValue);
			}

			function getValue()
			{
				return this.CurrentValue;
			}

			function setValue(_value)
			{
				this.CurrentValue = _value;
			}

			function onPressed(_manual = false)
			{
				this.toggleSettingValue();
				this.Tactical.EventLog.log(this.ID + " is now " + this.getValue());
				this.informBackend(_manual);
			}

			function informBackend(_manual)
			{
				::CombatSimulator.Screen.m.JSHandle.asyncCall("setTopBarButtonState", [this.ID, this.getValue(), _manual]);
			}
		},
		Buttons = {
			//butttons get their functions mostly from the delegate
			ManualTurns = {
				ID = "ManualTurns",
				DefaultValue = false,
				CurrentValue = false,
			},

			UnlockCamera = {
				ID = "UnlockCamera",
				DefaultValue = false,
				CurrentValue = false,
			},

			FinishFight = {
				ID = "FinishFight",
				DefaultValue = false,
				CurrentValue = false,
				onPressed = function(_manual = false)
				{
					local state = ::MSU.Utils.getState("tactical_state");
					state.exitTactical();
				}
			},

			Pause = {
				ID = "Pause",
				DefaultValue = false,
				CurrentValue = false,
				onPressed = function(_manual = false){
					this.toggleSettingValue();
					local state = ::MSU.Utils.getState("tactical_state")
					state.setPause(this.getValue());
					
					if(this.getValue())
					{
						this.Tactical.EventLog.log("[color=#1e468f]Game is now paused.[/color]");
					}
					else
					{
						this.Tactical.EventLog.log("[color=#8f1e1e]Game is now unpaused.[/color]");
					}
					this.informBackend(_manual);
					return this.getValue();
				},
			},

			FOV = {
				ID = "FOV",
				DefaultValue = true,
				CurrentValue = true,
				onPressed = function(_manual= false){
					this.toggleSettingValue();
					local state = ::MSU.Utils.getState("tactical_state");
					state.m.IsFogOfWarVisible = this.getValue();

					if (this.getValue())
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
					this.informBackend(_manual);
					return state.m.IsFogOfWarVisible;
				}
			},
		}
	},

	function create()
	{
		this.ui_screen.create();
		foreach(key, button in this.m.Buttons) button.setdelegate(this.m.ButtonDelegate)
	}

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
					::CombatSimulator.Screen.hide();
					this.onShow();
					this.setAutoPause(false);
				});
				break;

			case "main_menu_state":
				activeState.m.MenuStack.push(function ()
				{
					::CombatSimulator.Screen.hide();
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

	function getButton(_id)
	{
		return this.m.Buttons[_id];
	}

	function onTopBarButtonPressed(_buttonType)
	{
		// manual is true when the button was clicked instead of hotkey
		local properties = this.Tactical.State.getStrategicProperties();
		if (properties.CombatID != "CombatSimulator" && ::CombatSimulator.Mod.ModSettings.getSetting("AllowSettings").getValue() == false)
			return
		this.getButton(_buttonType).onPressed(true);
	}

	function setTopBarButtonsDisplay(_bool)
	{
		this.m.JSHandle.asyncCall("setTopBarButtonsDisplay", _bool);
	}

	function resetButtonValues()
	{
		foreach(key, button in this.m.Buttons) button.setValue(button.DefaultValue)
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
		p.Entities = [];
		p.CustomFactions <- [];
		p.CombatID = "CombatSimulator";
		p.Music = this.Const.Music[_data.Settings.MusicTrack];	
		p.PlayerDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.EnemyDeploymentType = this.Const.Tactical.DeploymentType.Line;
		p.IsAutoAssigningBases = false;
		p.IsFogOfWarVisible = !_data.Settings.SpectatorMode;
		p.IsFleeingProhibited = _data.Settings.IsFleeingProhibited;

		p.IsUsingSetPlayers = _data.Settings.SpectatorMode;
		p.SpectatorMode <- _data.Settings.SpectatorMode;
		p.StartEmptyMode <- _data.Settings.StartEmptyMode;
		p.ControlAllies <- _data.Settings.ControlAllies;
		if(p.SpectatorMode)
		{
			this.getButton("UnlockCamera").setValue(true);
			this.getButton("FOV").setValue(false);
		}

		// Use noble factions so that noble units dont break when they look for banner
		::CombatSimulator.Setup.setupFactions(p, _data.Factions);
		foreach (idx, faction in p.CustomFactions)
		{
			foreach(spawnlist in _data.Factions[idx].Spawnlists)
			{
				this.Const.World.Common.addUnitsToCombat(p.Entities, this.Const.World.Spawn[spawnlist.ID], spawnlist.Resources.tointeger() , faction.getID());
			}
			::CombatSimulator.Setup.addUnitsToCombat(_data.Factions[idx].Units, p.Entities, faction.getID());
		}
		this.World.State.startScriptedCombat(p, false, false, true);
	}

	function queryData()
	{
		local ret = {
			AllUnits = ::CombatSimulator.Setup.querySpawnlistMaster(),
			AllFactions =  ::CombatSimulator.Setup.queryFactions(),
			AllSpawnlists = ::CombatSimulator.Setup.querySpawnlists(),
			AllBaseTerrains = ::CombatSimulator.Setup.queryTerrains(),
			AllLocationTerrains = ::CombatSimulator.Setup.queryTerrainLocations(),
			AllMusicTracks =::CombatSimulator.Setup.queryTracklist(),
		}
		return ret;
	}
});

