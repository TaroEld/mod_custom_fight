this.flat_grass_combatsimulator <- this.inherit("scripts/mapgen/tactical_template", {
	m = {},
	function init()
	{
		this.m.Name = "flat_grass_combatsimulator";
		this.m.MinX = 32;
		this.m.MinY = 32;
	}

	function fill( _rect, _properties, _pass = 1 )
	{
		local flatTile = this.MapGen.get("tile.flat_grass_combatsimulator");

		for( local x = _rect.X; x < _rect.X + _rect.W; x = ++x )
		{
			for( local y = _rect.Y; y < _rect.Y + _rect.H; y = ++y )
			{
				local tile = this.Tactical.getTileSquare(x, y);

				if (tile.Type != 0)
				{
				}
				else
				{

					tile.Level = 0;
					flatTile.fill({
						X = x,
						Y = y,
						W = 1,
						H = 1,
						IsEmpty = this.Math.rand(1, 5) != 1
					}, _properties);

				}
			}
		}

		this.makeBordersImpassable(_rect);
	}

	function campify( _rect, _properties )
	{
	}

});

