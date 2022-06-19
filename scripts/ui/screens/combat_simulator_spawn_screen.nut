this.combat_simulator_spawn_screen <- ::inherit("scripts/mods/msu/ui_screen", {
	m = {
		ID = "CombatSimulatorSpawnScreen"
	},
	
	function show()
	{
		local properties = this.Tactical.State.getStrategicProperties();
		if (properties.CombatID != "CombatSimulator" && ::CombatSimulator.Mod.ModSettings.getSetting("AllowSettings").getValue() == false) 
			return false;

		local activeState = ::MSU.Utils.getActiveState();
		this.Cursor.setCursor(this.Const.UI.Cursor.Hand);
		local previousPauseState = activeState.m.IsGamePaused;
		if (!previousPauseState)
		{
			::CombatSimulator.Screen.getButton("Pause").onPressed(false);
		}
		activeState.m.MenuStack.push(function ()
		{
			if(!previousPauseState)
			{
				::CombatSimulator.Screen.getButton("Pause").onPressed(false);
			}
			::CombatSimulator.SpawnScreen.hide();
		});
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

	function queryData()
	{
		local ret = {
			AllUnits = ::CombatSimulator.Setup.querySpawnlistMaster(),
		}
		return ret;
	}

	function spawnUnit(_data)
	{
		local unit = _data.Unit;
		local settings = _data.Settings;

		local tile = this.Tactical.getTile(this.Tactical.screenToTile(::Cursor.getX(), ::Cursor.getY()));
		local properties = this.Tactical.State.getStrategicProperties();
		if (!("CustomFactions" in properties)) ::CombatSimulator.Setup.setupFactions(properties, true);

		unit.Faction <- settings.Ally ?  properties.NobleFactionAlly.getID() : properties.NobleFactionEnemy.getID();
		unit.Name <- "";
		unit.Champion <- settings.Champion;
		unit.Variant <- settings.Champion ? this.Math.rand(1, 255) : 0;
		if (settings.Champion && "NameList" in unit)
		{
			unit.Name = ::Const.World.Common.generateName(unit.NameList) + (unit.TitleList != null ? " " + unit.TitleList[this.Math.rand(0, unit.TitleList.len() - 1)] : "");
		}
		local entity = this.Tactical.spawnEntity(unit.Script, tile.Coords.X, tile.Coords.Y);
		this.Tactical.Entities.setupEntity(entity, unit);
	}

	function onCancelButtonPressed()
	{
		this.hide()
	}
});

