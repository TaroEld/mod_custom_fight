::CombatSimulator.Mod.Keybinds.addSQKeybind("toggleCombatSimulatorSpawnScreen", "ctrl+s", ::MSU.Key.State.Tactical,  ::CombatSimulator.SpawnScreen.toggle.bindenv(::CombatSimulator.SpawnScreen), "Open tactical screen");
::CombatSimulator.Mod.Keybinds.addSQKeybind("toggleCombatSimulatorScreen", "ctrl+s", ::MSU.Key.State.World,  ::CombatSimulator.Screen.toggle.bindenv(::CombatSimulator.Screen), "Open worldmap screen");
::CombatSimulator.Mod.Keybinds.addSQKeybind("initNextTurn", "f", ::MSU.Key.State.Tactical, function(){
	this.Tactical.TurnSequenceBar.initNextTurn(true);
	return true;
}, "End turn");
::CombatSimulator.Mod.Keybinds.addSQKeybind("togglePauseTactical", "shift+p", ::MSU.Key.State.Tactical, function()
{
	::CombatSimulator.Screen.getButton("Pause").toggleSettingValue();
	return true;
}, "Toggle Pause")
::CombatSimulator.Mod.Keybinds.addSQKeybind("toggleFovTactical", "shift+f", ::MSU.Key.State.Tactical, function()
{
	::CombatSimulator.Screen.getButton("FOV").toggleSettingValue();
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