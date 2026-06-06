class_name WorldMap
extends TileMapLayer

@export var noise: FastNoiseLite

@export var map_width: int
@export var map_height: int
@export var tileset: TileSet

var map_width_px: int
var map_height_px: int

const t_earth = 1
const t_grass = 0
const t_stone = 3
const t_sand  = 2

@onready var water_layer: TileMapLayer = $Water
var progress: float = 0.0
var seed: int = 0

const sector_size: Vector2i = Vector2i(32, 32)
var sectors: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	map_width_px = map_width*tileset.tile_size.x
	map_height_px = map_height*tileset.tile_size.y
	seed = randi_range(1, 100)
	init_noise()
	init_sectors()
	map_gen()

func init_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.001
	noise.fractal_gain = 0.6
	noise.fractal_octaves = 5

func init_sectors() -> void:
	var tile_width = tileset.tile_size.x
	var tile_height = tileset.tile_size.y
	
	var sector_width_px = sector_size.x * tile_width
	var sector_height_px = sector_size.y * tile_height
	var sector_size_px = Vector2i(sector_width_px, sector_height_px)
	
	var sectors_x = ceili(float(map_width) / sector_size.x)
	var sectors_y = ceili(float(map_height) / sector_size.y)
	
	for x in range(sectors_x):
		for y in range(sectors_y):
			var sector_pos = Vector2i(x * sector_width_px, y * sector_height_px)
			sectors[Vector2i(x, y)] = Rect2i(sector_pos, sector_size_px)

func map_gen() -> void:
	for x in range(map_width):
		for y in range(map_height):
			progress = x
			# use bigger value to increase generation speed ( x % 20 )
			# that decreases FPS on loading screan
			if x % 5 == 0 and y == 0:
				await get_tree().process_frame
				
			var noise_val = noise.get_noise_2d(x, y)
			var tile_case = get_tile_type(noise_val)
			
			if y == 0 or y == map_height-1:
				set_cell(Vector2(x, y), 2, tile_case)
			else:
				set_cell(Vector2(x, y), 1, tile_case)
			if noise_val < -0.1:
				water_layer.set_cell(Vector2(x, y), 0, Vector2i(0, 0))
	progress = map_width

func get_tile_type(val: float) -> Vector2i:
	if -0.5 < val and val < 0: return Vector2i(randi_range(0, 3), t_sand)
	if val > 0 and val < 0.5: return  Vector2i(randi_range(0, 3), t_grass)
	if val > 0.5: return Vector2i(randi_range(0, 3), t_earth)
	return Vector2i(randi_range(0, 3), t_stone)
