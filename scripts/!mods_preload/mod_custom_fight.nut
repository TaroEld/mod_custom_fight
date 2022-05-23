::CustomFight <- {
	ID = "mod_script_fight",
	Name = "Script Fight",
	Version = "1.0.0"
}
::mods_registerMod(::CustomFight.ID, ::CustomFight.Version)

::mods_queue(::CustomFight.ID, "mod_msu", function()
{
	::mods_registerJS("CustomFight.js");
	::mods_registerCSS("CustomFight.css");

	::CustomFight.Mod <- ::MSU.Class.Mod(::CustomFight.ID, ::CustomFight.Version, ::CustomFight.Name); 
	::CustomFight.Screen <- this.new("scripts/ui/screens/custom_fight_screen");
	::MSU.UI.registerConnection(::CustomFight.Screen);
	::CustomFight.Mod.Keybinds.addSQKeybind("toggleCustomFightScreen", "ctrl+p", ::MSU.Key.State.All,  ::CustomFight.Screen.toggle.bindenv(::CustomFight.Screen));
	::CustomFight.Mod.Keybinds.addSQKeybind("initNextTurn", "f", ::MSU.Key.State.Tactical, function(){
		this.Tactical.TurnSequenceBar.initNextTurn(true);
	});
	::CustomFight.Mod.Keybinds.addSQKeybind("togglePauseTactical", "p", ::MSU.Key.State.Tactical, function(){
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
	});

	::mods_hookNewObject("entity/tactical/tactical_entity_manager", function(o){
		local checkCombatFinished = o.checkCombatFinished;
		o.checkCombatFinished = function( _forceFinish = false )
		{
			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.CombatID != "CustomFight")
			{
				return checkCombatFinished(_forceFinish);
			}

			if (!("WithoutPlayer" in properties) || !properties.WithoutPlayer)
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
	})
	::mods_hookNewObject("camera/tactical_camera_director", function(o){
		local isInputAllowed = o.isInputAllowed;
		o.isInputAllowed = function()
		{
			local properties = this.Tactical.State.getStrategicProperties();
			if ("WithoutPlayer" in properties && properties.WithoutPlayer)
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
			local properties = this.Tactical.State.getStrategicProperties();
			if ("WithoutPlayer" in properties && properties.WithoutPlayer)
			{
				return setInputLocked(false);
			}
			return setInputLocked(_bool);
		}
	})

	::mods_hookExactClass("ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function(o){
		local initNextTurn = o.initNextTurn;
		o.initNextTurn = function(_force = false)
		{
			if (_force) return initNextTurn(_force);
			local properties = this.Tactical.State.getStrategicProperties();
			if ("WithoutPlayer" in properties && properties.WithoutPlayer)
			{
				return;
			}
			return initNextTurn(_force);
		}
	})
})