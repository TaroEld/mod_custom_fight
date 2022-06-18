::CustomFight <- {
	ID = "mod_custom_fight",
	Name = "Custom Fight",
	Version = "0.9.0"
}
::mods_registerMod(::CustomFight.ID, ::CustomFight.Version)

::mods_queue(::CustomFight.ID, "mod_msu(>=1.1.0)", function()
{
	::mods_registerJS("CustomFight.js");
	::mods_registerCSS("CustomFight.css");
	::mods_registerJS("CustomFightSpawnScreen.js");
	::mods_registerCSS("CustomFightSpawnScreen.css");
	::mods_registerJS("CustomFight_TacticalScreenTopbarOptionsModule.js");
	::mods_registerCSS("CustomFight_TacticalScreenTopbarOptionsModule.css");
	::include("CustomFight/custom_fight_setup")

	::CustomFight.Mod <- ::MSU.Class.Mod(::CustomFight.ID, ::CustomFight.Version, ::CustomFight.Name); 
	::CustomFight.Screen <- this.new("scripts/ui/screens/custom_fight_screen");
	::CustomFight.SpawnScreen <- this.new("scripts/ui/screens/custom_fight_spawn_screen");
	::CustomFight.Setup <- this.new("CustomFight/custom_fight_setup");
	::CustomFight.Const <- {};
	::include("CustomFight/const/track_list")
	::MSU.UI.registerConnection(::CustomFight.Screen);
	::MSU.UI.registerConnection(::CustomFight.SpawnScreen);
	::CustomFight.Mod.Keybinds.addSQKeybind("toggleCustomFightScreen", "ctrl+s", ::MSU.Key.State.World,  ::CustomFight.Screen.toggle.bindenv(::CustomFight.Screen));
	::CustomFight.Mod.Keybinds.addSQKeybind("toggleCustomFightSpawnScreen", "ctrl+s", ::MSU.Key.State.Tactical,  ::CustomFight.SpawnScreen.toggle.bindenv(::CustomFight.SpawnScreen));
	::CustomFight.Mod.Keybinds.addSQKeybind("initNextTurn", "f", ::MSU.Key.State.Tactical, function(){
		this.Tactical.TurnSequenceBar.initNextTurn(true);
		return true;
	});
	::CustomFight.Mod.Keybinds.addSQKeybind("togglePauseTactical", "shift+p", ::MSU.Key.State.Tactical, function()
	{
		::CustomFight.Screen.getButton("Pause").onPressed(false);
		return true;
	})
	::CustomFight.Mod.Keybinds.addSQKeybind("toggleFovTactical", "shift+f", ::MSU.Key.State.Tactical, function()
	{
		::CustomFight.Screen.getButton("FOV").onPressed(false);
		return true;
	})
	local generalPage = ::CustomFight.Mod.ModSettings.addPage("General");
	generalPage.addBooleanSetting("AllowSettings", false, "Allow Settings", "Allow the topbar buttons and the spawner screen to work in normal fights, outside of custom fights.");
	::include("CustomFight/tooltips")
	::include("CustomFight/const/sprite_list")

	::mods_hookNewObject("entity/tactical/tactical_entity_manager", function(o){
		local checkCombatFinished = o.checkCombatFinished;
		o.checkCombatFinished = function( _forceFinish = false )
		{
			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.CombatID != "CustomFight")
			{
				return checkCombatFinished(_forceFinish);
			}
			if (properties.StartEmptyMode)
			{
				return false;
			}

			if (!properties.SpectatorMode)
			{
				return checkCombatFinished(_forceFinish);
			}
			local oldResult = this.m.CombatResult;
			local oldFinished = this.m.IsCombatFinished;
			local ret = checkCombatFinished(_forceFinish);
			this.m.IsCombatFinished = _forceFinish || this.getHostilesNum() == 0;
			local allInstancesWithUnits = this.m.Instances.filter(@(a, b) b.len() > 0);
			foreach(idx, faction in allInstancesWithUnits)
			{
				local hasEnemy = false;
				foreach(idx2, otherFaction in allInstancesWithUnits)
				{
					if (idx != idx2 && !faction[0].isAlliedWith(otherFaction[0]))
					{
						hasEnemy = true;
						break;
					}
				}
				if(!hasEnemy)
				{
					this.m.IsCombatFinished = true;
					this.m.CombatResult = oldResult;
					return true;
				}
			}
		}

		local setupEntity = o.setupEntity;
		o.setupEntity = function(_e, _t)
		{
			setupEntity(_e, _t);
			::CustomFight.Setup.setupEntity(_e, _t);
		}
	})

	::mods_hookNewObject("camera/tactical_camera_director", function(o){
		local isInputAllowed = o.isInputAllowed;
		o.isInputAllowed = function()
		{
			if (::CustomFight.Screen.getButton("UnlockCamera").getValue())
			{
				return true;
			}
			return isInputAllowed();
		}
	})

	::mods_hookExactClass("states/tactical_state", function(o){
		local setInputLocked = o.setInputLocked;
		o.setInputLocked = function(_bool)
		{
			if (::CustomFight.Screen.getButton("UnlockCamera").getValue()) 
				return setInputLocked(false);
			return setInputLocked(_bool);
		}

		local exitTactical = o.exitTactical;
		o.exitTactical = function()
		{
			local properties = this.Tactical.State.getStrategicProperties();
			if (!("NobleFactionAlly" in properties))  return exitTactical();
			local factions = this.World.FactionManager.m.Factions;
			factions.pop();
			factions.pop();
			::CustomFight.Screen.resetButtonValues();		
			return exitTactical();
		}
	})

	::mods_hookExactClass("ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function(o){
		local initNextTurn = o.initNextTurn;
		o.initNextTurn = function(_force = false)
		{
			if (_force) return initNextTurn(_force);
			if (::CustomFight.Screen.getButton("ManualTurns").getValue())
				return;
			return initNextTurn(_force);
		}
	})

	::mods_hookNewObject("ui/screens/tactical/tactical_screen", function(o){
		local connect = o.connect;
		o.connect = function()
		{
			connect();
			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.CombatID == "CustomFight" || ::CustomFight.Mod.ModSettings.getSetting("AllowSettings").getValue() == true) 
				::CustomFight.Screen.setTopBarButtonsDisplay(true);
		}
	})
})