extends TileMapLayer

@export var noise: FastNoiseLite

@export var map_width: int
@export var map_height: int
@export var tileset: TileSet
const t_earth = Vector2i(1, 0)
const t_grass = Vector2i(0, 0)
const t_stone = Vector2i(1, 0)
const t_sand = Vector2i(1, 1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_noise()
	map_gen()

func init_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = 42
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.02

func map_gen() -> void:
	for x in range(map_width):
		for y in range(map_height):
			var noise_val = noise.get_noise_2d(x, y)
			var tile_case = get_tile_type(noise_val)
			
			set_cell(Vector2(x, y), 0, tile_case)

func get_tile_type(val: float) -> Vector2i:
	if -0.5 < val and val < 0: return t_grass
	if val > 0 and val < 0.5: return  t_sand
	if val > 0.5: return t_grass
	return t_stone
