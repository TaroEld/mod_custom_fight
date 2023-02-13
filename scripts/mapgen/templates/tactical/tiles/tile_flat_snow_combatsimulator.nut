this.tile_flat_snow_combatsimulator <- this.inherit("scripts/mapgen/tactical_template", {
	m = {
		Details = [
			"tundra_grass_01",
			"tundra_grass_02",
			"tundra_grass_03",
			"tundra_grass_04",
			"tundra_grass_05"
		],
		DetailsSnow = [
			"snow_detail_01",
			"snow_detail_02",
			"snow_detail_03",
			"snow_detail_04",
			"snow_detail_05"
		],
		ChanceToSpawnDetails = 15,
		LimitOfSpawnedDetails = 4,
	},
	function init()
	{
		this.m.Name = "tile.flat_snow_combatsimulator";
		this.m.MinX = 1;
		this.m.MinY = 1;
		local t = this.createTileTransition();
		t.setBlendIntoSockets(false);
		t.setBrush(this.Const.Direction.N, "transition_snow_01_N");
		t.setBrush(this.Const.Direction.NE, "transition_snow_01_NE");
		t.setBrush(this.Const.Direction.SE, "transition_snow_01_SE");
		t.setBrush(this.Const.Direction.S, "transition_snow_01_S");
		t.setBrush(this.Const.Direction.SW, "transition_snow_01_SW");
		t.setBrush(this.Const.Direction.NW, "transition_snow_01_NW");
		t.setSocket("socket_snow");
		this.Tactical.setTransitions("tile_snow_01", t);
	}

	function onFirstPass( _rect )
	{
		local tile = this.Tactical.getTileSquare(_rect.X, _rect.Y);

		if (tile.Type != 0)
		{
			return;
		}

		tile.Type = this.Const.Tactical.TerrainType.RoughGround;
		tile.Subtype = this.Const.Tactical.TerrainSubtype.Snow;
		tile.BlendPriority = this.Const.Tactical.TileBlendPriority.Snow1;
		tile.IsBadTerrain = false;
		tile.setBrush("tile_snow_01");
		local n = 0;

		if (this.Math.rand(1, 100) <= this.m.ChanceToSpawnDetails)
		{
			if (this.Math.rand(1, 100) <= 90)
			{
				tile.spawnDetail(this.m.DetailsSnow[this.Math.rand(0, this.m.DetailsSnow.len() - 1)]);
			}
			else
			{
				tile.spawnDetail(this.m.Details[this.Math.rand(0, this.m.Details.len() - 1)]);
			}
		}
	}

});

