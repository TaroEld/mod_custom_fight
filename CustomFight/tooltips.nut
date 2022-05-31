::CustomFight.TooltipIdentifiers <- {
	Screen = {
		Main = {
			Start = ::MSU.Class.UITooltip("Start Fight", "Start the fight with the chosen setup."),
			Cancel = ::MSU.Class.UITooltip("Cancel", "Return to menu."),
			Reset = ::MSU.Class.UITooltip("Reset", "Reset all settings."),
		}
		Settings = {
			Terrain = ::MSU.Class.UITooltip("Choose Terrain", "Choose the terrain."),
			Map = ::MSU.Class.UITooltip("Choose Map", "Choose the map. Rightclick to clear."),
			Music = ::MSU.Class.UITooltip("Choose Music", "Choose the music."),
			CutDownTrees = ::MSU.Class.UITooltip("Cut down trees", "Cut down trees."),
			Fortification = ::MSU.Class.UITooltip("Add Fortifications", "Add fortifications. Does nothing if no map is selected."),
			Music = ::MSU.Class.UITooltip("Choose Music", "Choose the music."),
			StartEmptyMode = ::MSU.Class.UITooltip("Start Empty Mode", "Start Empty Mode."),
			IsFleeingProhibited = ::MSU.Class.UITooltip("Fleeing Probhibited", "Block fleeing, like in the arena."),
			SpectatorMode = ::MSU.Class.UITooltip("Spectator Mode", "Set spectator mode. Your bros won't be spawned."),
			ControlAllies = ::MSU.Class.UITooltip("Control Allies", "If this is checked, you can control your allied units."),
		},
		Spawnlist = {
			Main = {
				Add = ::MSU.Class.UITooltip("Add a spawnlist", "Add a spawnlist. A spawnlist is a group of enemies, such as the defenders of a bandit camp. The type and number of units depends on the resouces."),
				Type = ::MSU.Class.UITooltip("Type", "Type of spawnlist."),
				Resources = ::MSU.Class.UITooltip("Resources", "Resources (Strength) of the spawnlist. The more resources, the stronger and more numerous the units will be."),
				Delete = ::MSU.Class.UITooltip("Delete", "Delete this spawnlist."),
			}
			Popup = {
				OK = ::MSU.Class.UITooltip("OK", "Close the popup."),
			}
		}
		Units = {
			Main = {
				Add = ::MSU.Class.UITooltip("Add a unit", "Add a unit."),
				Type = ::MSU.Class.UITooltip("Type", "Type of unit."),
				Amount = ::MSU.Class.UITooltip("Amount", "Amount of this unit."),
				Delete = ::MSU.Class.UITooltip("Delete", "Delete this unit."),
				Champion = ::MSU.Class.UITooltip("Champion", "Sets this unit to be a champion."),
			}
			Popup = {
				OK = ::MSU.Class.UITooltip("OK", "Close the popup."),
			}
		},
	},
	Tactical = 
	{
		Topbar = {
			Pause = ::MSU.Class.UITooltip("Toggle Pause", @() format("Toggle pause %s", ::MSU.Utils.getState("tactical_state").m.IsGamePaused ? "off." : "on.")),
			FOV = ::MSU.Class.UITooltip("Toggle FOV", @() format("Toggle FOV %s", ::MSU.Utils.getState("tactical_state").m.IsFogOfWarVisible ? "off." : "on.")),
			ManualTurns = ::MSU.Class.UITooltip("Toggle Manual Turns", @() format("Toggle Manual Turns %s", this.Tactical.State.getStrategicProperties().ManualTurns ? "off." : "on.")),
			UnlockCamera = ::MSU.Class.UITooltip("Toggle Unlock Camera", @() format("%s the camera.", this.Tactical.State.getStrategicProperties().UnlockCamera ? "Lock" : "Unlock")),
			FinishFight = ::MSU.Class.UITooltip("Finish Fight", "Finish the current fight."),
		}
	}
}
::MSU.Tooltip.addTooltips("CustomFight", ::CustomFight.TooltipIdentifiers);
