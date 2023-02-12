::CombatSimulator <- {
	ID = "mod_combat_simulator",
	Name = "Combat Simulator",
	Version = "0.9.3"
}
::mods_registerMod(::CombatSimulator.ID, ::CombatSimulator.Version)

::mods_queue(::CombatSimulator.ID, "mod_msu(>=1.1.0)", function()
{
	::mods_registerJS("CombatSimulator.js");
	::mods_registerCSS("CombatSimulator.css");
	::mods_registerJS("CombatSimulatorSpawnScreen.js");
	::mods_registerCSS("CombatSimulatorSpawnScreen.css");
	::mods_registerJS("CombatSimulator_TacticalScreenTopbarOptionsModule.js");
	::mods_registerCSS("CombatSimulator_TacticalScreenTopbarOptionsModule.css");
	::include("CombatSimulator/combat_simulator_setup")

	::CombatSimulator.Mod <- ::MSU.Class.Mod(::CombatSimulator.ID, ::CombatSimulator.Version, ::CombatSimulator.Name); 
	::CombatSimulator.Screen <- this.new("scripts/ui/screens/combat_simulator_screen");
	::CombatSimulator.SpawnScreen <- this.new("scripts/ui/screens/combat_simulator_spawn_screen");
	::CombatSimulator.Setup <- this.new("CombatSimulator/combat_simulator_setup");
	::CombatSimulator.Const <- {};
	::include("CombatSimulator/const/track_list")
	::MSU.UI.registerConnection(::CombatSimulator.Screen);
	::MSU.UI.registerConnection(::CombatSimulator.SpawnScreen);
	::CombatSimulator.Mod.Keybinds.addSQKeybind("toggleCombatSimulatorSpawnScreen", "ctrl+s", ::MSU.Key.State.Tactical,  ::CombatSimulator.SpawnScreen.toggle.bindenv(::CombatSimulator.SpawnScreen), "Open tactical screen");
	::CombatSimulator.Mod.Keybinds.addSQKeybind("toggleCombatSimulatorScreen", "ctrl+s", ::MSU.Key.State.World,  ::CombatSimulator.Screen.toggle.bindenv(::CombatSimulator.Screen), "Open worldmap screen");
	::CombatSimulator.Mod.Keybinds.addSQKeybind("initNextTurn", "f", ::MSU.Key.State.Tactical, function(){
		this.Tactical.TurnSequenceBar.initNextTurn(true);
		return true;
	}, "End turn");
	::CombatSimulator.Mod.Keybinds.addSQKeybind("togglePauseTactical", "shift+p", ::MSU.Key.State.Tactical, function()
	{
		::CombatSimulator.Screen.getButton("Pause").onPressed(false);
		return true;
	}, "Toggle Pause")
	::CombatSimulator.Mod.Keybinds.addSQKeybind("toggleFovTactical", "shift+f", ::MSU.Key.State.Tactical, function()
	{
		::CombatSimulator.Screen.getButton("FOV").onPressed(false);
		return true;
	}, "Toggle FOV")

	::CombatSimulator.Mod.Keybinds.addSQKeybind("killHoveredUnit", "shift+k", ::MSU.Key.State.Tactical, function()
	{
		local activeState = ::MSU.Utils.getActiveState();
		if (activeState.m.LastTileHovered != null && !activeState.m.LastTileHovered.IsEmpty)
		{
		  local entity = activeState.m.LastTileHovered.getEntity();
		  if (entity != null && this.isKindOf(entity, "actor"))
		  {
		    if (entity == this.Tactical.TurnSequenceBar.getActiveEntity()) {activeState.cancelEntityPath(entity);}
		    entity.kill();
		  }
		}
	}, "Kill hovered unit")


	local generalPage = ::CombatSimulator.Mod.ModSettings.addPage("General");
	generalPage.addBooleanSetting("AllowSettings", false, "Allow Settings", "Allow the topbar buttons and the spawner screen to work in normal fights, outside of Combat Simulators.");
	::include("CombatSimulator/tooltips")
	::include("CombatSimulator/const/sprite_list")

	::mods_hookNewObject("entity/tactical/tactical_entity_manager", function(o){
		local checkCombatFinished = o.checkCombatFinished;
		o.checkCombatFinished = function( _forceFinish = false )
		{
			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.CombatID != "CombatSimulator")
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
			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.CombatID == "CombatSimulator") ::CombatSimulator.Setup.setupEntity(_e);
		}
	})

	::mods_hookNewObject("camera/tactical_camera_director", function(o){
		local isInputAllowed = o.isInputAllowed;
		o.isInputAllowed = function()
		{
			if (::CombatSimulator.Screen.getButton("UnlockCamera").getValue())
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
			if (::CombatSimulator.Screen.getButton("UnlockCamera").getValue()) 
				return setInputLocked(false);
			return setInputLocked(_bool);
		}

		local exitTactical = o.exitTactical;
		o.exitTactical = function()
		{
			::CombatSimulator.Setup.removeFactions();
			::CombatSimulator.Screen.resetButtonValues();		
			return exitTactical();
		}

		local onBattleEnded = o.onBattleEnded;
		o.onBattleEnded = function()
		{
			local properties = this.Tactical.State.getStrategicProperties();

			if (properties.CombatID != "CombatSimulator" || "UnpausedEndCombat" in properties)
				return onBattleEnded();

			if ("SetupEndCombat" in properties && !("UnpausedEndCombat" in properties))
				return;

			::CombatSimulator.Screen.getButton("Pause").onPressed(false, true);
			local oldPause = this.setPause;
			this.setPause = function( _f )
			{
				if (_f == false)
				{
					properties.UnpausedEndCombat <- true;
					this.setPause = oldPause;
					return oldPause(_f);
				}
			}
			properties.SetupEndCombat <- true;
		}
	})

	::mods_hookExactClass("ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function(o){
		local initNextTurn = o.initNextTurn;
		o.initNextTurn = function(_force = false)
		{
			if (_force) return initNextTurn(_force);
			if (::CombatSimulator.Screen.getButton("ManualTurns").getValue())
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
			if (properties.CombatID == "CombatSimulator" || ::CombatSimulator.Mod.ModSettings.getSetting("AllowSettings").getValue() == true) 
				::CombatSimulator.Screen.setTopBarButtonsDisplay(true);
		}
	})
})
