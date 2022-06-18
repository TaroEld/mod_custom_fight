::CombatSimulator.TooltipIdentifiers <- {
	Screen = {
		Main = {
			Start = ::MSU.Class.BasicTooltip("Start Fight", "Start the fight with the chosen setup."),
			Cancel = ::MSU.Class.BasicTooltip("Cancel", "Return to menu."),
			Reset = ::MSU.Class.BasicTooltip("Reset", "Reset all settings."),
		}
		Settings = {
			Terrain = ::MSU.Class.BasicTooltip("Choose Terrain", function(_data){
				local text = "Choose the terrain.";
				return text
			}),
			Map = ::MSU.Class.BasicTooltip("Choose Map", "Choose the map. Rightclick to clear."),
			Music = ::MSU.Class.BasicTooltip("Choose Music", "Choose the music."),
			CutDownTrees = ::MSU.Class.BasicTooltip("Cut down trees", "Cut down trees."),
			Fortification = ::MSU.Class.BasicTooltip("Add Fortifications", "Add fortifications. Does nothing if no map is selected."),
			Music = ::MSU.Class.BasicTooltip("Choose Music", "Choose the music."),
			StartEmptyMode = ::MSU.Class.BasicTooltip("Start Empty Mode", "Start Empty Mode."),
			IsFleeingProhibited = ::MSU.Class.BasicTooltip("Fleeing Probhibited", "Block fleeing, like in the arena."),
			SpectatorMode = ::MSU.Class.BasicTooltip("Spectator Mode", "Set spectator mode. Your bros won't be spawned."),
			ControlAllies = ::MSU.Class.BasicTooltip("Control Allies", "If this is checked, you can control your allied units."),
		},
		Spawnlist = {
			Main = {
				Add = ::MSU.Class.BasicTooltip("Add a spawnlist", "Add a spawnlist. A spawnlist is a group of enemies, such as the defenders of a bandit camp. The type and number of units depends on the resouces."),
				Type = ::MSU.Class.BasicTooltip("Type", "Type of spawnlist."),
				Resources = ::MSU.Class.BasicTooltip("Resources", "Resources (Strength) of the spawnlist. The more resources, the stronger and more numerous the units will be."),
				Delete = ::MSU.Class.BasicTooltip("Delete", "Delete this spawnlist."),
			}
			Popup = {
				OK = ::MSU.Class.BasicTooltip("OK", "Close the popup."),
			}
		}
		Units = {
			Main = {
				Add = ::MSU.Class.BasicTooltip("Add a unit", "Add a unit."),
				Type = ::MSU.Class.BasicTooltip("Type", "Type of unit."),
				Amount = ::MSU.Class.BasicTooltip("Amount", "Amount of this unit."),
				Delete = ::MSU.Class.BasicTooltip("Delete", "Delete this unit."),
				Champion = ::MSU.Class.BasicTooltip("Champion", "Sets this unit to be a champion."),
			}
			Popup = {
				OK = ::MSU.Class.BasicTooltip("OK", "Close the popup."),
			}
		},
	},
	Tactical = 
	{
		Topbar = {
			Pause = ::MSU.Class.BasicTooltip("Toggle Pause", @(_) format("Toggle pause %s", ::CombatSimulator.Screen.getButton("Pause").getValue() ? "off." : "on.")),
			FOV = ::MSU.Class.BasicTooltip("Toggle FOV", @(_) format("Toggle FOV %s", ::CombatSimulator.Screen.getButton("FOV").getValue() ? "off." : "on.")),
			ManualTurns = ::MSU.Class.BasicTooltip("Toggle Manual Turns", @(_) format("Toggle Manual Turns %s", ::CombatSimulator.Screen.getButton("ManualTurns").getValue() ? "off." : "on.")),
			UnlockCamera = ::MSU.Class.BasicTooltip("Toggle Unlock Camera", @(_) format("%s the camera.", ::CombatSimulator.Screen.getButton("UnlockCamera").getValue() ? "Lock" : "Unlock")),
			FinishFight = ::MSU.Class.BasicTooltip("Finish Fight", "Finish the current fight."),
		}
	}
}
::CombatSimulator.Mod.Tooltips.setTooltips(::CombatSimulator.TooltipIdentifiers);
