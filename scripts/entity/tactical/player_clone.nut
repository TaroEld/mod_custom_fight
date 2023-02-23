this.player_clone <- this.inherit("scripts/entity/tactical/player", {
	m = {},
	function create()
	{
		this.player.create();
		this.m.AIAgent = this.new("scripts/ai/tactical/agents/charmed_player_agent");
		this.m.AIAgent.setActor(this);
	}

	function onInit()
	{
		this.player.onInit();
	}

	function onCombatFinished()
	{
	}

	function isPlayerControlled()
	{
		return this.m.IsControlledByPlayer;
	}

	function onDeath( _killer, _skill, _tile, _fatalityType )
	{
		local flip = this.Math.rand(0, 100) < 50;
		this.m.IsCorpseFlipped = flip;
		if (_tile != null)
		{
			this.human.onDeath(_killer, _skill, _tile, _fatalityType);
			local corpse = _tile.Properties.get("Corpse");
			corpse.IsPlayer = true;
			corpse.Value = 10.0;
		}
		this.onRemovedFromMap();
	}

	function isReallyKilled( _fatalityType )
	{
		return true;
	}

	function kill( _killer = null, _skill = null, _fatalityType = this.Const.FatalityType.None, _silent = false )
	{
		if (!this.isAlive())
		{
			return;
		}

		if (_killer != null && !_killer.isAlive())
		{
			_killer = null;
		}

		this.m.IsDying = true;
		local isReallyDead = this.isReallyKilled(_fatalityType);

		this.logDebug(this.getName() + " has died.");

		if (!_silent)
		{
			this.playSound(this.Const.Sound.ActorEvent.Death, this.Const.Sound.Volume.Actor * this.m.SoundVolume[this.Const.Sound.ActorEvent.Death] * this.m.SoundVolumeOverall, this.m.SoundPitch);
		}

		local myTile = this.isPlacedOnMap() ? this.getTile() : null;
		local tile = this.findTileToSpawnCorpse(_killer);
		this.m.Skills.onDeath(_fatalityType);
		this.onDeath(_killer, _skill, tile, _fatalityType);

		if (!this.Tactical.State.isFleeing() && _killer != null)
		{
			_killer.onActorKilled(this, tile, _skill);
		}

		if (_killer != null && !_killer.isHiddenToPlayer() && !this.isHiddenToPlayer())
		{
			if (_killer.getID() != this.getID())
			{
				this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(_killer) + " has killed " + this.Const.UI.getColorizedEntityName(this));
			}
			else
			{
				this.Tactical.EventLog.logEx(this.Const.UI.getColorizedEntityName(this) + " has died");
			}
		}

		if (!this.Tactical.State.isFleeing() && myTile != null)
		{
			local actors = this.Tactical.Entities.getAllInstances();

			foreach( i in actors )
			{
				foreach( a in i )
				{
					if (a.getID() != this.getID())
					{
						a.onOtherActorDeath(_killer, this, _skill);
					}
				}
			}
		}

		if (!this.isHiddenToPlayer())
		{
			if (tile != null)
			{
				if (_fatalityType == this.Const.FatalityType.Decapitated)
				{
					this.spawnDecapitateSplatters(tile, 1.0 * this.m.DecapitateBloodAmount);
				}
				else if (_fatalityType == this.Const.FatalityType.Smashed && (this.getFlags().has("human") || this.getFlags().has("zombie_minion")))
				{
					this.spawnSmashSplatters(tile, 1.0);
				}
				else
				{
					this.spawnBloodSplatters(tile, this.Const.Combat.BloodSplattersAtDeathMult * this.m.DeathBloodAmount);

					if (!this.getTile().isSameTileAs(tile))
					{
						this.spawnBloodSplatters(this.getTile(), this.Const.Combat.BloodSplattersAtOriginalPosMult);
					}
				}
			}
			else if (myTile != null)
			{
				this.spawnBloodSplatters(this.getTile(), this.Const.Combat.BloodSplattersAtDeathMult * this.m.DeathBloodAmount);
			}
		}

		if (tile != null)
		{
			this.spawnBloodPool(tile, this.Math.rand(this.Const.Combat.BloodPoolsAtDeathMin, this.Const.Combat.BloodPoolsAtDeathMax));
		}

		this.m.IsTurnDone = true;
		this.m.IsAlive = false;

		if (this.m.WorldTroop != null && ("Party" in this.m.WorldTroop) && this.m.WorldTroop.Party != null && !this.m.WorldTroop.Party.isNull())
		{
			this.m.WorldTroop.Party.removeTroop(this.m.WorldTroop);
		}


		this.removeFromMap();

		if (this.m.Items != null)
		{
			this.m.Items.onActorDied(tile);
			this.m.Items.setActor(null);
		}

		this.onAfterDeath(myTile);
	}

	function onActorKilled( _actor, _tile, _skill )
	{
		this.actor.onActorKilled(_actor, _tile, _skill);
	}

	function updateLevel()
	{
	}

	function assignRandomEquipment()
	{
	}
})