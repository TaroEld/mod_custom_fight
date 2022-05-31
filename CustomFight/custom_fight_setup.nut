this.custom_fight_setup <- {
	m = {},
	function querySpawnlistMaster()
	{
		// clone it
		local ret = {};

		foreach (id, unit in ::Const.World.Spawn.Troops)
		{	
			ret[id] <- clone unit;
			ret[id].DisplayName <- ::Const.Strings.EntityName[unit.ID];
			ret[id].Icon <- ::Const.EntityIcon[unit.ID];
		}
		return ret;
	}

	function queryFactions()
	{
		return clone ::Const.FactionType;
	}

	function querySpawnlists()
	{
		local ret = {};
		foreach(id, list in ::Const.World.Spawn)
		{
			ret[id] <- {
				id = id,
				list = clone list
			}
		}
		return ret;
	}

	function queryTerrains()
	{
		return clone ::Const.World.TerrainTacticalTemplate
	}

	function queryTracklist()
	{
		return clone ::CustomFight.Const.TrackList
	}


	function queryTerrainLocations()
	{
		local ret = [];
		local locSplit, locFinal;
		foreach(key in ::IO.enumerateFiles("scripts/mapgen/templates/tactical/locations"))
		{
			locSplit = split(key, "/");
			locSplit = locSplit[locSplit.len()-1];
			locSplit = split(locSplit, "_");
			locFinal = locSplit.remove(0) + "." + locSplit.remove(0);
			while(locSplit.len() > 0)
			{
				locFinal += "_" + locSplit.remove(0)
			}
			ret.push(locFinal);
		}
		return ret;
	}

	function setupFactions(_properties, _tacticalActive = false)
	{
		local nobleFactionAlly = createFaction(_tacticalActive, 100.0);
		local nobleFactionEnemy = createFaction(_tacticalActive, 0.0);
		_properties.NobleFactionAlly <- ::WeakTableRef(nobleFactionAlly);
		_properties.NobleFactionEnemy <- ::WeakTableRef(nobleFactionEnemy);
	}

	function createFaction(_tacticalActive, _relation)
	{
		local a = ::MSU.Array.rand(::Const.FactionArchetypes[0])
		local f = this.new("scripts/factions/noble_faction");
		local banner = this.Math.rand(2, 10);
		local name = this.Const.Strings.NobleHouseNames[this.Math.rand(0, this.Const.Strings.NobleHouseNames.len() - 1)];
		f.setID( this.World.FactionManager.m.Factions.len());
		f.setName(name);
		f.setMotto("\"" + a.Mottos[this.Math.rand(0, a.Mottos.len() - 1)] + "\"");
		f.setDescription(a.Description);
		f.setBanner(banner);
		f.setDiscovered(true);
		f.m.PlayerRelation = _relation;
		f.updatePlayerRelation();
		this.World.FactionManager.m.Factions.push(f);
		// If spawn screen is used during a normal fight, we need to add these empty arrays
		if (_tacticalActive)
		{
			this.Tactical.Entities.m.Instances.push([]);
			this.Tactical.Entities.m.InstancesMax.push(0.0);
			local s = this.new("scripts/ai/tactical/strategy");
			s.setFaction(f);
			this.Tactical.Entities.m.Strategies.push(s);
		}
		return f;
	}

	function addUnitsToCombat(_units, _into, _faction)
	{
		foreach( t in _units )
		{
			t.Type = ::Const.World.Spawn.Troops[t.Type];
			t.Num = t.Num.tointeger();
			for( local i = 0; i < t.Num; i++ )
			{
				local unit = clone t.Type;
				unit.Faction <- _faction;
				unit.Name <- "";

				if (unit.Variant > 0)
				{
					if (!this.Const.DLC.Wildmen || (!t.Champion && this.Math.rand(1, 100) > unit.Variant))
					{
						unit.Variant = 0;
					}
					else
					{
						unit.Strength = this.Math.round(unit.Strength * 1.35);
						unit.Variant = this.Math.rand(1, 255);

						if ("NameList" in t.Type)
						{
							unit.Name = ::Const.World.Common.generateName(t.Type.NameList) + (t.Type.TitleList != null ? " " + t.Type.TitleList[this.Math.rand(0, t.Type.TitleList.len() - 1)] : "");
						}
					}
				}

				_into.push(unit);
			}
		}
	}
}