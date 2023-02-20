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
				this.informBackend();
				local state = ::MSU.Utils.getActiveState();
				if (::MSU.Utils.getActiveState() != null && ::MSU.Utils.getActiveState().ClassName == "tactical_state")
				{
					this.logChange();
					this.onAfterChange();
				}
			}
			function onAfterChange(){}
			function logChange()
			{
				if(this.getValue())
				{
					this.Tactical.EventLog.log(format("[color=#1e468f]%s is now ", this.ID) +  this.getValue() + "[/color]");
				}
				else
				{
					this.Tactical.EventLog.log(format("[color=#8f1e1e]%s is now ", this.ID) +  this.getValue() + "[/color]");
				}
			}
			function onPressed()
			{
				this.toggleSettingValue();
			}
			function informBackend()
			{
				::CombatSimulator.Screen.m.JSHandle.asyncCall("setTopBarButtonState", [this.ID, this.getValue()]);
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
				onPressed = function()
				{
					local state = ::MSU.Utils.getState("tactical_state");
					state.exitTactical();
				}
			},

			Pause = {
				ID = "Pause",
				DefaultValue = false,
				CurrentValue = false,
				function logChange()
				{
					if(this.getValue())
					{
						this.Tactical.EventLog.log("[color=#1e468f]Game is now paused.[/color]");
					}
					else
					{
						this.Tactical.EventLog.log("[color=#8f1e1e]Game is now unpaused.[/color]");
					}
				}
				function onAfterChange()
				{
					::MSU.Utils.getState("tactical_state").setPause(this.getValue());
	
					return this.getValue();
				},
			},

			FOV = {
				ID = "FOV",
				DefaultValue = true,
				CurrentValue = true,
				function logChange()
				{
					if(this.getValue())
					{
						this.Tactical.EventLog.log("[color=#1e468f]FOV is now visible.[/color]");
					}
					else
					{
						this.Tactical.EventLog.log("[color=#8f1e1e]FOV is no longer visible.[/color]");
					}
				}
				function onAfterChange()
				{
					::MSU.Utils.getState("tactical_state").m.IsFogOfWarVisible = this.getValue();

					if (this.getValue())
					{
						this.Tactical.fillVisibility(this.Const.Faction.Player, false);
						foreach (idx, faction in this.Tactical.State.getStrategicProperties().CustomFactions)
						{
							local units = this.Tactical.Entities.getInstancesOfFaction(faction.getID());

							foreach( i, unit in units )
							{
								unit.updateVisibilityForFaction();
							}
						}

						if (this.Tactical.TurnSequenceBar.getActiveEntity() != null)
						{
							this.Tactical.TurnSequenceBar.getActiveEntity().updateVisibilityForFaction();
						}
						::CombatSimulator.Setup.updatePlayerVisibility();
					}
					else
					{
						this.Tactical.fillVisibility(this.Const.Faction.Player, true);
					}
					return this.getValue();
				}
			},
		}
	},

	function create()
	{
		this.ui_screen.create();
		foreach(key, button in this.m.Buttons) button.setdelegate(this.m.ButtonDelegate)
	}


	function queryData()
	{
		local ret = {
			AllUnits = ::CombatSimulator.Setup.querySpawnlistMaster(),
			AllFactions =  ::CombatSimulator.Setup.queryFactions(),
			AllBrothers =  ::CombatSimulator.Setup.queryBrothers(),
			AllSpawnlists = ::CombatSimulator.Setup.querySpawnlists(),
			AllBaseTerrains = ::CombatSimulator.Setup.queryTerrains(),
			AllLocationTerrains = ::CombatSimulator.Setup.queryTerrainLocations(),
			AllMusicTracks =::CombatSimulator.Setup.queryTracklist(),
		}
		return ret;
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
		::CombatSimulator.Setup.setupFight(_data);
	}

	function getButton(_id)
	{
		return this.m.Buttons[_id];
	}

	function onTopBarButtonPressed(_buttonType)
	{
		// manual is true when the button was clicked instead of hotkey
		if (!::CombatSimulator.isCombatSimulatorFight() && ::CombatSimulator.Mod.ModSettings.getSetting("AllowSettings").getValue() == false)
			return
		this.getButton(_buttonType).onPressed();
	}

	function setTopBarButtonsDisplay(_bool)
	{
		this.m.JSHandle.asyncCall("setTopBarButtonsDisplay", _bool);
	}

	function resetButtonValues()
	{
		foreach(key, button in this.m.Buttons) button.setValue(button.DefaultValue)
	}

	function updateFactionProperty(_data)
	{
		::CombatSimulator.Setup.updateFactionProperty(_data);
	}
});

