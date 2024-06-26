::CombatSimulator <- {
	ID = "mod_combat_simulator"
	Name = "Combat Simulator"
	Version = "1.0.1"
	Const = {}
	function isCombatSimulatorFight()
	{
		local state = this.Tactical.State;
		if (state == null)
			return false;
		local properties = this.Tactical.State.getStrategicProperties();
		if (properties.CombatID != "CombatSimulator") 
			return false;
		return true;
	}
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

	::CombatSimulator.Mod <- ::MSU.Class.Mod(::CombatSimulator.ID, ::CombatSimulator.Version, ::CombatSimulator.Name); 
	::CombatSimulator.Screen <- this.new("scripts/ui/screens/combat_simulator_screen");
	::CombatSimulator.SpawnScreen <- this.new("scripts/ui/screens/combat_simulator_spawn_screen");

	::include("CombatSimulator/combat_simulator_setup")
	::CombatSimulator.Setup <- this.new("CombatSimulator/combat_simulator_setup");
	
	::MSU.UI.registerConnection(::CombatSimulator.Screen);
	::MSU.UI.registerConnection(::CombatSimulator.SpawnScreen);
	
	::include("CombatSimulator/tooltips");
	::include("CombatSimulator/keybinds");
	::include("CombatSimulator/modsettings");

	::include("CombatSimulator/const/sprite_list");
	::include("CombatSimulator/const/track_list");

	::mods_hookNewObject("ui/screens/tooltip/tooltip_events", function(o)
	{
		local tactical_helper_getEntityTooltip = o.tactical_helper_getEntityTooltip;
		o.tactical_helper_getEntityTooltip = function( _targetedEntity, _activeEntity, _isTileEntity )
		{
			local ret = tactical_helper_getEntityTooltip( _targetedEntity, _activeEntity, _isTileEntity );
			if (ret != null || !::CombatSimulator.isCombatSimulatorFight())
				return null
			if (this.Tactical.State != null && this.Tactical.State.getCurrentActionState() == this.Const.Tactical.ActionState.SkillSelected)
			{
				if (_activeEntity != null && this.isKindOf(_targetedEntity, "actor") && _activeEntity.isPlayerControlled() && _targetedEntity != null && _targetedEntity.getFaction() != _activeEntity.getFaction())
				{
					local skill = _activeEntity.getSkills().getSkillByID(this.Tactical.State.getSelectedSkillID());

					if (skill != null)
					{
						return this.tactical_helper_addContentTypeToTooltip(_targetedEntity, _targetedEntity.getTooltip(skill), _isTileEntity);
					}
				}

				return null;
			}

			if (this.isKindOf(_targetedEntity, "entity"))
			{
				return this.tactical_helper_addContentTypeToTooltip(_targetedEntity, _targetedEntity.getTooltip(), _isTileEntity);
			}

			return null;
		}
	})

	::mods_hookNewObject("entity/tactical/tactical_entity_manager", function(o){
		local checkCombatFinished = o.checkCombatFinished;
		o.checkCombatFinished = function( _forceFinish = false )
		{
			if (!::CombatSimulator.isCombatSimulatorFight())
				return checkCombatFinished(_forceFinish);

			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.StartEmptyMode)
				return false;

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
			if (::CombatSimulator.isCombatSimulatorFight())
				::CombatSimulator.Setup.setupEntity(_e);
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


	::mods_hookNewObject("ui/screens/character/character_screen", function(o){
		local tactical_onQueryBrothersList = o.tactical_onQueryBrothersList;
		o.tactical_onQueryBrothersList = function()
		{
			local ret = tactical_onQueryBrothersList();
			if (!::CombatSimulator.isCombatSimulatorFight())
				return ret;

			local extraUnits = [];
			local activeEntity = this.Tactical.TurnSequenceBar.getActiveEntity();
			local activeEntityFaction = activeEntity.getFaction();
			if (activeEntityFaction ==this.Const.Faction.Player)
			if (activeEntityFaction == this.Const.Faction.Player)
				return ret;

			local units = this.Tactical.Entities.getInstancesOfFaction(activeEntityFaction);
			foreach( i, unit in units )
			{
				if (unit.isPlayerControlled())
				if (unit.ClassName == "player_clone")
					extraUnits.push(this.UIDataHelper.convertEntityToUIData(unit, activeEntity));
			}
			if (ret != null)
			{
				ret.extend(extraUnits);
				return ret;
			}
			else return extraUnits
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

		local onBattleEnded = o.onBattleEnded;
		o.onBattleEnded = function()
		{
			if (!::CombatSimulator.isCombatSimulatorFight())
				return onBattleEnded();

			local properties = this.Tactical.State.getStrategicProperties();

			if ("UnpausedEndCombat" in properties)
				return onBattleEnded();

			if ("SetupEndCombat" in properties && !("UnpausedEndCombat" in properties))
				return;

			::CombatSimulator.Screen.getButton("Pause").setValue(true);
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

		local turnsequencebar_onNextRound = o.turnsequencebar_onNextRound;
		o.turnsequencebar_onNextRound = function(_round)
		{
			turnsequencebar_onNextRound(_round);
			::CombatSimulator.Setup.updatePlayerVisibility();
		} 
	})

	::mods_hookExactClass("states/world_state", function(o){
		local onReturnedFromTactical = o.onReturnedFromTactical;
		o.onReturnedFromTactical = function()
		{
			onReturnedFromTactical();
			::CombatSimulator.Setup.cleanupAfterFight();
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
			if (::CombatSimulator.isCombatSimulatorFight() || ::CombatSimulator.Mod.ModSettings.getSetting("AllowSettings").getValue()) 
				::CombatSimulator.Screen.setTopBarButtonsDisplay(true);
		}
	})

	::mods_hookExactClass("entity/tactical/actor", function(o)
	{
		local onTurnStart = o.onTurnStart;
		o.onTurnStart = function()
		{
			local ret = onTurnStart();
			this.combatsim_updateVisibilityForPlayer();
			return ret;
		}
		local onTurnResumed = o.onTurnResumed;
		o.onTurnResumed = function()
		{
			local ret = onTurnResumed();
			this.combatsim_updateVisibilityForPlayer();
			return ret;
		}
		local onMovementStep = o.onMovementStep;
		o.onMovementStep = function( _tile, _levelDifference ) 
		{
			local ret = onMovementStep(_tile, _levelDifference);
			this.combatsim_updateVisibilityForPlayer();
			return ret;
		}
		local onMovementFinish = o.onMovementFinish;
		o.onMovementFinish = function( _tile )
		{
			local ret = onMovementFinish(_tile);
			this.combatsim_updateVisibilityForPlayer();
			return ret;
		}

		o.combatsim_updateVisibilityForPlayer <- function()
		{
			if (!this.isAlive() || !::CombatSimulator.isCombatSimulatorFight() || !::MSU.Utils.getState("tactical_state").m.IsFogOfWarVisible)
				return;
			if (!this.isPlayerControlled())
				return;
			this.updateVisibility(this.getTile(), this.m.CurrentProperties.getVision(), this.Const.Faction.Player);
		}
	})
})
