::ScriptFight <- {
	ID = "mod_script_fight",
	Name = "Script Fight",
	Version = "1.0.0",
	WithoutPlayer = false,
}
::mods_registerMod(::ScriptFight.ID, ::ScriptFight.Version)

::mods_queue(::ScriptFight.ID, "mod_msu", function()
{
	::mods_registerJS("ScriptFight.js");
	::mods_registerCSS("ScriptFight.css");

	::ScriptFight.Mod <- ::MSU.Class.Mod(::ScriptFight.ID, ::ScriptFight.Version, ::ScriptFight.Name); 
	::ScriptFight.Screen <- this.new("scripts/ui/screens/script_fight_screen");
	::MSU.UI.registerConnection(::ScriptFight.Screen);
	::ScriptFight.Mod.Keybinds.addSQKeybind("toggleScriptFightScreen", "ctrl+p", ::MSU.Key.State.All,  ::ScriptFight.Screen.toggle.bindenv(::ScriptFight.Screen));

	::mods_hookNewObject("entity/tactical/tactical_entity_manager", function(o){
		local checkCombatFinished = o.checkCombatFinished;
		o.checkCombatFinished = function( _forceFinish = false )
		{
			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.CombatID != "ScriptedFight")
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
})