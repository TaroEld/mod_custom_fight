::CustomFight <- {
	ID = "mod_custom_fight",
	Name = "Custom Fight",
	Version = "1.0.0"
}
::mods_registerMod(::CustomFight.ID, ::CustomFight.Version)

::mods_queue(::CustomFight.ID, "mod_msu", function()
{
	::mods_registerJS("CustomFight.js");
	::mods_registerCSS("CustomFight.css");
	::mods_registerJS("CustomFight_TacticalScreenTopbarOptionsModule.js");
	::mods_registerCSS("CustomFight_TacticalScreenTopbarOptionsModule.css");

	::CustomFight.Mod <- ::MSU.Class.Mod(::CustomFight.ID, ::CustomFight.Version, ::CustomFight.Name); 
	::CustomFight.Screen <- this.new("scripts/ui/screens/custom_fight_screen");
	::CustomFight.Const <- {};
	::MSU.UI.registerConnection(::CustomFight.Screen);
	::CustomFight.Mod.Keybinds.addSQKeybind("toggleCustomFightScreen", "ctrl+p", ::MSU.Key.State.All,  ::CustomFight.Screen.toggle.bindenv(::CustomFight.Screen));
	::CustomFight.Mod.Keybinds.addSQKeybind("initNextTurn", "f", ::MSU.Key.State.Tactical, function(){
		this.Tactical.TurnSequenceBar.initNextTurn(true);
		return true;
	});
	::CustomFight.Mod.Keybinds.addSQKeybind("togglePauseTactical", "p", ::MSU.Key.State.Tactical, function()
	{
		::CustomFight.Screen.onPausePressed();
		return true;
	})
	::CustomFight.Mod.Keybinds.addSQKeybind("toggleFovTactical", "d", ::MSU.Key.State.Tactical, function()
	{
		::CustomFight.Screen.onFOVPressed();
		return true;
	})
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
			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.CombatID != "CustomFight") return;

			if (_e.getFaction() != properties.NobleFactionAlly.Ref.getID()) return;
			this.logInfo("past check")

			// basically false turns them left for humans and right for beasts because rap pls
			// so it's wrong for humans, but we rely on onFactionChanged to change them back
			foreach(key in ::CustomFight.Const.SpriteList)
			{
				if (_e.hasSprite(key))
				{
					_e.getSprite(key).setHorizontalFlipping(true);
				}
			}
			_e.onFactionChanged();

			if (!properties.ControlAllies || _e.m.IsControlledByPlayer) return;

			_e.setFaction(this.Const.Faction.Player);
			_e.m.AIAgent = this.new("scripts/ai/tactical/player_agent");
			_e.m.AIAgent.setActor(_e);
			_e.m.IsControlledByPlayer = true;
			_e.m.IsGuest <- true;
			_e.isGuest <- function(){
				return this.m.IsGuest;
			}
			
			_e.onCombatStart <- function(){};

			if("Tail" in _e.m)
			{
				_e.m.Tail.setFaction(this.Const.Faction.PlayerAnimals);
			}
		}
	})

	::mods_hookNewObject("camera/tactical_camera_director", function(o){
		local isInputAllowed = o.isInputAllowed;
		o.isInputAllowed = function()
		{
			local properties = this.Tactical.State.getStrategicProperties();
			if ("UnlockCamera" in properties && properties.UnlockCamera)
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
			if ("UnlockCamera" in properties && properties.UnlockCamera)
			{
				return setInputLocked(false);
			}
			return setInputLocked(_bool);
		}

		local exitTactical = o.exitTactical;
		o.exitTactical = function()
		{
			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.CombatID != "CustomFight") return exitTactical();


			properties.NobleFactionAlly.Ref.m.PlayerRelation = properties.NobleFactionAlly.Relation;
			properties.NobleFactionAlly.Ref.updatePlayerRelation();
			if (properties.NobleFactionAlly.OtherFactionFriendly) properties.NobleFactionAlly.Ref.addAlly(properties.NobleFactionEnemy.Ref.getID())
			properties.NobleFactionEnemy.Ref.m.PlayerRelation = properties.NobleFactionEnemy.Relation;
			properties.NobleFactionEnemy.Ref.updatePlayerRelation();
			if (properties.NobleFactionEnemy.OtherFactionFriendly) properties.NobleFactionAlly.Ref.addAlly(properties.NobleFactionAlly.Ref.getID())
			
			return exitTactical();
		}
	})

	::mods_hookExactClass("ui/screens/tactical/modules/turn_sequence_bar/turn_sequence_bar", function(o){
		local initNextTurn = o.initNextTurn;
		o.initNextTurn = function(_force = false)
		{
			if (_force) return initNextTurn(_force);
			local properties = this.Tactical.State.getStrategicProperties();
			if ("ManualTurns" in properties && properties.ManualTurns)
			{
				return;
			}
			return initNextTurn(_force);
		}
	})

	::mods_hookNewObject("ui/screens/tactical/tactical_screen", function(o){
		local connect = o.connect;
		o.connect = function()
		{
			connect();
			local properties = this.Tactical.State.getStrategicProperties();
			if (properties.CombatID == "CustomFight") ::CustomFight.Screen.setTopBarButtonsDisplay(true);
		}
	})
})