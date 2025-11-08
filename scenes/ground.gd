extends TileMapLayer

const TILE_SIZE = Vector2i(32, 32)
const MAP_SIZE  = Vector2i(75, 40)

const TERRAIN_TEXTURES = {
	"sand":  "res://tiles/placeholders/Sand.png",
	"ice":   "res://tiles/placeholders/ice.png",
	"grass": "res://tiles/placeholders/grass_1.png"
}

var terrain_sources: Dictionary = {} # name -> { source_id, atlas_pos }
var map_center: Vector2i # tady bude střed mapy (v tile souřadnicích)
var grass_fields: Array[Dictionary] = []
var ice_fields: Array[Dictionary] = []


func _ready():
	_build_tileset()
	map_center = _get_map_center()
	_fill_whole_map("sand")
	_debug_mark_center()
	
	 # sem si přidáš, kde všude chceš začít grass
	grass_fields = [
		#map_center,                     # jedno pole uprostřed
		#map_center + Vector2i(5, -3),   # pokud to budeme chtít použit pro danou vzdálenost od středu "základu základny"
		{ "center": Vector2i(35, 8), "radius": Vector2i(2, 2) },          # úplně konkrétní souřadnice
		{ "center": Vector2i(55, 35), "radius": Vector2i(3, 2) }
	]
	ice_fields = [
		{"center": Vector2i(8, 35), "radius": Vector2i(4, 1)},            
		{"center": Vector2i(35, 35) , "radius": Vector2i(3, 4)},
		
	]

	# pro každý záznam v grass_fields vykreslíme oblast grass
	_paint_grass_fields()
	_paint_ice_fields()

func _build_tileset():
	var ts := TileSet.new()

	for name in TERRAIN_TEXTURES.keys():
		var tex: Texture2D = load(TERRAIN_TEXTURES[name])
		if tex == null:
			push_error("Chybí textura pro terrain: %s" % name)
			continue

		var atlas := TileSetAtlasSource.new()
		atlas.texture = tex
		atlas.texture_region_size = TILE_SIZE

		atlas.create_tile(Vector2i(0, 0)) # 1 tile z daného obrázku

		var src_id := ts.add_source(atlas)

		terrain_sources[name] = {
			"source_id": src_id,
			"atlas_pos": Vector2i(0, 0),
		}

	tile_set = ts

func _fill_whole_map(terrain_name: String):
	if not terrain_sources.has(terrain_name):
		push_error("Neznámý terrain: %s" % terrain_name)
		return

	var info = terrain_sources[terrain_name]
	var source_id: int = info["source_id"]
	var atlas_pos: Vector2i = info["atlas_pos"]

	for x in range(MAP_SIZE.x):
		for y in range(MAP_SIZE.y):
			set_cell(Vector2i(x, y), source_id, atlas_pos)

	update_internals()

func _get_map_center() -> Vector2i:
	# pro 50x30 to dá (25, 15)
	return Vector2i(MAP_SIZE.x / 2, MAP_SIZE.y / 2)


func _paint_grass_fields():
	for field in grass_fields:
		var center := field["center"] as Vector2i
		var radius := field["radius"] as Vector2i
		_paint_terrain_area(center, radius, "grass", true) # true = zaoblený tvar
		
func _paint_ice_fields():
	for field in ice_fields:
		var center := field["center"] as Vector2i
		var radius := field["radius"] as Vector2i
		_paint_terrain_area(center, radius, "ice", true) # true = zaoblený tvar


func _paint_terrain_area(center: Vector2i, radius: Vector2i, terrain_name: String, rounded: bool = false):
	var info = terrain_sources.get(terrain_name)
	if info == null:
		push_error("Neznámý terrain pro area: %s" % terrain_name)
		return

	var source_id: int = info["source_id"]
	var atlas_pos: Vector2i = info["atlas_pos"]

	var rx = max(radius.x, 1)
	var ry = max(radius.y, 1)

	for x in range(center.x - rx, center.x + rx + 1):
		for y in range(center.y - ry, center.y + ry + 1):
			if x < 0 or y < 0 or x >= MAP_SIZE.x or y >= MAP_SIZE.y:
				continue

			if rounded:
				var nx = float(x - center.x) / float(rx)
				var ny = float(y - center.y) / float(ry)
				if nx * nx + ny * ny > 1.0:
					continue

			set_cell(Vector2i(x, y), source_id, atlas_pos)

	update_internals()
	

func _debug_mark_center(): #na přepsaní do budoucna jen pro debug a visualizaci
	if terrain_sources.has("ice"):
		var info = terrain_sources["ice"]
		set_cell(map_center, info["source_id"], info["atlas_pos"])
		update_internals()
