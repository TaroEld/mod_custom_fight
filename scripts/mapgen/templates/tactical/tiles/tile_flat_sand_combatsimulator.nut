this.tile_flat_sand_combatsimulator <- this.inherit("scripts/mapgen/tactical_template", {
	m = {
		Details = [
			"desert_bones_01",
			"desert_bones_02",
			"desert_bones_03",
			"desert_bones_04",
			"desert_stone_detail_01",
			"desert_stone_detail_02",
			"desert_stone_detail_03",
			"desert_stone_detail_04",
			"desert_stone_detail_05",
			"desert_stone_detail_06",
			"desert_stone_detail_07",
			"desert_stone_detail_08",
			"desert_stone_detail_09",
			"desert_stone_detail_10",
			"desert_stone_detail_01",
			"desert_stone_detail_02",
			"desert_stone_detail_03",
			"desert_stone_detail_04",
			"desert_stone_detail_05",
			"desert_stone_detail_06",
			"desert_stone_detail_07",
			"desert_stone_detail_08",
			"desert_stone_detail_09",
			"desert_stone_detail_10",
			"desert_stone_detail_01",
			"desert_stone_detail_02",
			"desert_stone_detail_03",
			"desert_stone_detail_04",
			"desert_stone_detail_05",
			"desert_stone_detail_06",
			"desert_stone_detail_07",
			"desert_stone_detail_08",
			"desert_stone_detail_09",
			"desert_stone_detail_10"
		],
		HidingExtras = [
			"desert_grass_details_01",
			"desert_grass_details_02",
			"desert_grass_details_03",
			"desert_grass_details_04",
			"desert_grass_details_05"
		],
		ChanceToSpawnDetails = 5,
		LimitOfSpawnedDetails = 1,
	},
	function init()
	{
		this.m.Name = "tile.flat_sand_combatsimulator";
		this.m.MinX = 1;
		this.m.MinY = 1;
		local t = this.createTileTransition();
		t.setSocket("socket_desert");
		this.Tactical.setTransitions("tile_desert_01", t);
	}

	function onFirstPass( _rect )
	{
		local tile = this.Tactical.getTileSquare(_rect.X, _rect.Y);

		if (tile.Type != 0)
		{
			return;
		}

		tile.Type = this.Const.Tactical.TerrainType.Sand;
		tile.Subtype = this.Const.Tactical.TerrainSubtype.Desert;
		tile.BlendPriority = this.Const.Tactical.TileBlendPriority.Desert1;
		tile.IsBadTerrain = false;
		tile.setBrush("tile_desert_01");

		if (_rect.IsEmpty)
		{
			return;
		}
		if (this.Math.rand(0, 100) < this.m.ChanceToSpawnDetails)
		{
			tile.spawnDetail(this.m.Details[this.Math.rand(0, this.m.Details.len() - 1)]);
		}
	}

	function onSecondPass( _rect )
	{
	}

});

