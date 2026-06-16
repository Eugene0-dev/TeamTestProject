class_name WorldMap
extends TileMapLayer

@export var noise: FastNoiseLite
@export var objective_noise: FastNoiseLite

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
@onready var objects_layer: TileMapLayer = $Objects
var progress: float = 0.0
var world_seed: int = 0

const sector_size: Vector2i = Vector2i(32, 32)
var sectors: Dictionary = {}

signal generation_complete()

func _ready() -> void:
	map_width_px = map_width*tileset.tile_size.x
	map_height_px = map_height*tileset.tile_size.y
	world_seed = randi_range(1, 100)
	init_noise()
	init_sectors()
	map_gen()

func init_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = world_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.001
	noise.fractal_gain = 0.6
	noise.fractal_octaves = 5
	
	objective_noise = FastNoiseLite.new()
	objective_noise.seed = world_seed+1
	objective_noise.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
	objective_noise.frequency = 0.1

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
	var batch_cells_grass: Array[Vector2i] = []
	var batch_cells_sand: Array[Vector2i] = []
	var batch_cells_earth: Array[Vector2i] = []
	var batch_cells_stone: Array[Vector2i] = []
	
	for x in range(map_width):
		for y in range(map_height):
				
			var noise_val = noise.get_noise_2d(x, y)
			var tile_case = get_tile_type(noise_val)
			var cell = Vector2i(x, y)
			match tile_case.y:
				t_grass: batch_cells_grass.append(cell)
				t_sand: batch_cells_sand.append(cell)
				t_earth: batch_cells_earth.append(cell)
				t_stone: batch_cells_stone.append(cell)
				
			var obj_noise_val = objective_noise.get_noise_2d(x, y)
			
			if noise_val < 0.5 and noise_val > 0: set_trees(noise_val, obj_noise_val, Vector2i(x, y))
				
			if y == 0 or y == map_height-1:
				set_cell(Vector2(x, y), 2, tile_case)
			else:
				set_cell(Vector2(x, y), 1, tile_case)
			if noise_val < -0.1:
				water_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
				
			progress = x
			# use bigger value to increase generation speed ( x % 20 )
			# that decreases FPS on loading screan
			if x % 5 == 0 and y == 0:
				await get_tree().process_frame
	
	var post_process = connect_cells.bind(batch_cells_grass, batch_cells_earth, batch_cells_sand, batch_cells_stone)
	var thread_task_id = WorkerThreadPool.add_task(post_process, false)
	progress = map_width
	emit_signal("generation_complete")

func connect_cells(grass: Array[Vector2i], earth: Array[Vector2i], sand: Array[Vector2i], stone: Array[Vector2i]) -> void:
	var batch_grass: Array[Vector2i]
	var batch_earth: Array[Vector2i]
	var batch_sand: Array[Vector2i]
	var batch_stone: Array[Vector2i]
	var i = 0
	var chunk_size = 10000
	while i < grass.size():
		if i < grass.size()-1:
			batch_grass = grass.slice(i, i+chunk_size)
			set_cells_terrain_connect(batch_grass, 0, 0, false)
		if i < earth.size()-1:
			batch_earth = earth.slice(i, i+chunk_size)
			set_cells_terrain_connect(batch_earth, 0, 1, false)
		if i < sand.size()-1:
			batch_sand = sand.slice(i, i+chunk_size)
			set_cells_terrain_connect(batch_sand, 0, 2, false)
		if i < stone.size()-1:
			batch_stone = stone.slice(i, i+chunk_size)
			set_cells_terrain_connect(batch_stone, 0, 3, false)
		i += chunk_size
		OS.delay_msec(50)

func set_trees(val: float, obj_val: float, pos: Vector2i) -> void:
	var noise_sum = val+obj_val
	if noise_sum >= 0.5 and noise_sum < 0.5001: 
		#objects_layer.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(1, 3))
		objects_layer.set_cell(Vector2i(pos.x, pos.y), 1, Vector2i(3, 13))
		return
	if noise_sum >= 0.5001 and noise_sum < 0.5002: 
		#objects_layer.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(6, 3))
		objects_layer.set_cell(Vector2i(pos.x, pos.y), 1, Vector2i(24, 11))
		return
	if noise_sum >= 0.5002 and noise_sum < 0.5003: 
		#objects_layer.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(11, 2))
		objects_layer.set_cell(Vector2i(pos.x, pos.y), 1, Vector2i(45, 10))
		return
	if noise_sum >= 0.5003 and noise_sum < 0.5004: 
		#objects_layer.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(16, 2))
		objects_layer.set_cell(Vector2i(pos.x, pos.y), 1, Vector2i(66, 11))
		return
	if noise_sum >= 0.5004 and noise_sum < 0.5005: 
		#objects_layer.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(22, 1))
		objects_layer.set_cell(Vector2i(pos.x, pos.y), 1, Vector2i(90, 7))
		return
	if noise_sum >= 0.5005 and noise_sum < 0.5006: 
		#objects_layer.set_cell(Vector2i(pos.x, pos.y), 0, Vector2i(26, 1))
		objects_layer.set_cell(Vector2i(pos.x, pos.y), 1, Vector2i(106, 7))
		return

func get_tile_type(val: float) -> Vector2i:
	if -0.5 < val and val < 0: return Vector2i(randi_range(0, 3), t_sand)
	if val > 0 and val < 0.5: return  Vector2i(randi_range(0, 3), t_grass)
	if val > 0.5: return Vector2i(randi_range(0, 3), t_earth)
	return Vector2i(randi_range(0, 3), t_stone)
