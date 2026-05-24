extends TileMapLayer

@export var noise: FastNoiseLite

@export var map_width: int
@export var map_height: int
@export var tileset: TileSet
const t_earth = 0
const t_grass = 1
const t_mug = 2
const t_sand = 3

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
	var idx = randi_range(0, 3)
	if -0.5 < val and val < 0: return Vector2i(idx, t_grass)
	if val > 0 and val < 0.5: return Vector2i(idx, t_sand)
	if val > 0.5: return Vector2i(idx, t_grass)
	return Vector2i(idx, t_mug)
