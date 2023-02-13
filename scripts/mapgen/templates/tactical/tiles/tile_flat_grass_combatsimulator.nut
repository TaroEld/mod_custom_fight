this.tile_flat_grass_combatsimulator <- this.inherit("scripts/mapgen/tactical_template", {
	m = {
		DetailsA = [
			"detail_grass_00",
			"detail_grass_01",
			"detail_grass_02",
			"detail_grass_03",
			"detail_grass_04",
			"detail_grass_00",
			"detail_grass_01",
			"detail_grass_02",
			"detail_grass_03",
			"detail_grass_04",
			"detail_grass_05",
			"detail_grass_05",
			"detail_stone_00",
			"detail_stone_01",
			"detail_stone_02",
			"detail_stone_03",
			"detail_stone_04",
			"detail_mushrooms_03",
			"detail_clover_01",
			"detail_clover_02",
			"detail_clover_03",
			"detail_clover_04",
			"detail_clover_05"
		],
		DetailsB = [
			"detail_grass_00",
			"detail_grass_01",
			"detail_grass_02",
			"detail_grass_03",
			"detail_grass_04",
			"detail_grass_00",
			"detail_grass_01",
			"detail_grass_02",
			"detail_grass_03",
			"detail_grass_04",
			"detail_grass_05",
			"detail_grass_05",
			"detail_fern_01",
			"detail_fern_02",
			"detail_flowers_01",
			"detail_flowers_02",
			"detail_flowers_03",
			"detail_flowers_04"
		],
		FlowerDetails = [
			"detail_flowerstuff_01",
			"detail_flowerstuff_02",
			"detail_flowerstuff_03",
			"detail_flowerstuff_04",
			"detail_flowerstuff_04b"
		],
		ChanceToSpawnDetails = 50,
		ChanceToSpawnFlowerDetails = 33,
		LimitOfSpawnedDetails = 5,
	},
	function init()
	{
		this.m.Name = "tile.flat_grass_combatsimulator";
		this.m.MinX = 1;
		this.m.MinY = 1;
		local t = this.createTileTransition();
		t.setBlendIntoSockets(true);
		t.setBrush(this.Const.Direction.N, "transition_grass_01_N");
		t.setBrush(this.Const.Direction.NE, "transition_grass_01_NE");
		t.setBrush(this.Const.Direction.SE, "transition_grass_01_SE");
		t.setBrush(this.Const.Direction.S, "transition_grass_01_S");
		t.setBrush(this.Const.Direction.SW, "transition_grass_01_SW");
		t.setBrush(this.Const.Direction.NW, "transition_grass_01_NW");
		t.setSocket("socket_earth");
		this.Tactical.setTransitions("tile_grass_01", t);
	}

	function fillWithTrees( _rect, _properties, _pass = 1 )
	{
	}

	function fillWithShrubbery( _rect, _properties, _pass = 1 )
	{
	}

	function onFirstPass( _rect )
	{
		local tile = this.Tactical.getTileSquare(_rect.X, _rect.Y);

		if (tile.Type != 0)
		{
			return;
		}

		tile.Type = this.Const.Tactical.TerrainType.FlatGround;
		tile.Subtype = this.Const.Tactical.TerrainSubtype.Grassland;
		tile.BlendPriority = this.Const.Tactical.TileBlendPriority.Grass1;
		tile.setBrush("tile_grass_01");
		local details = this.Math.rand(0, 100) < 50 ? this.m.DetailsA : this.m.DetailsB;
		local allowFlowerSpecials = 0;
		local n = 0;
		while (this.Math.rand(0, 100) < this.m.ChanceToSpawnDetails && n++ < this.m.LimitOfSpawnedDetails)
		{
			local i = this.Math.rand(0, details.len() - 1);
			tile.spawnDetail(details[i]);

			if (i >= 14 && details == this.m.DetailsB)
			{
				allowFlowerSpecials = ++allowFlowerSpecials;
			}
		}

		if (allowFlowerSpecials >= 2 && this.Math.rand(0, 100) < this.m.ChanceToSpawnFlowerDetails)
		{
			for( local i = 0; i < this.m.FlowerDetails.len(); i = ++i )
			{
				tile.spawnDetail(this.m.FlowerDetails[i]);
			}
		}
	}

});

