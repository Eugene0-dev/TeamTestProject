extends TileMapLayer

@export var noise: FastNoiseLite

@export var map_width: int
@export var map_height: int
@export var tileset: TileSet
const t_earth = 1
const t_grass =0
const t_stone = 3
const t_sand = 2

@onready var water_layer: TileMapLayer = $Water

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	init_noise()
	map_gen()

func init_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = randi_range(1,100)
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.001
	noise.fractal_gain = 0.6
	noise.fractal_octaves = 5

func map_gen() -> void:
	for x in range(map_width):
		for y in range(map_height):
			var noise_val = noise.get_noise_2d(x, y)
			var tile_case = get_tile_type(noise_val)
			
			set_cell(Vector2(x, y), 1, tile_case)
			
			if noise_val < -0.1:
				water_layer.set_cell(Vector2(x, y), 0, Vector2i(0, 0))

func get_tile_type(val: float) -> Vector2i:
	if -0.5 < val and val < 0: return Vector2i(randi_range(0, 3), t_sand)
	if val > 0 and val < 0.5: return  Vector2i(randi_range(0, 3), t_grass)
	if val > 0.5: return Vector2i(randi_range(0, 3), t_earth)
	return Vector2i(randi_range(0, 3), t_stone)
