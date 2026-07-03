@tool
class_name WorldMap
extends TileMapLayer

@export var noise: FastNoiseLite
@export var objective_noise: FastNoiseLite
@export var ground_material_noise: FastNoiseLite

@export var map_width: int
@export var map_height: int
@export var tileset: TileSet

var threads: Array

var map_width_px: int
var map_height_px: int

const t_earth  = 1
const t_grass  = 0
const t_stone  = 3
const t_sand   = 2
const t_gravel = Vector2i(12, 15)
const t_clay   = Vector2i(12, 14)
const t_sludge = Vector2i(12, 13)

@onready var water_layer: TileMapLayer = $Water
@onready var objects_layer: TileMapLayer = $Objects
var progress: float = 0.0
@export var world_seed: int = 0:
	set(val):
		world_seed = val
		init_noise()
		map_gen()

const sector_size: Vector2i = Vector2i(32, 32)
var sectors: Dictionary = {}

var astar_grid: AStarGrid2D

signal generation_complete()

func _ready() -> void:
	map_width_px = map_width*tileset.tile_size.x
	map_height_px = map_height*tileset.tile_size.y
	world_seed = randi_range(1, 100)
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, map_width, map_height)
	astar_grid.cell_size = tileset.tile_size
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
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
	
	ground_material_noise = FastNoiseLite.new()
	ground_material_noise.seed = world_seed+2
	ground_material_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ground_material_noise.frequency = 0.0005
	ground_material_noise.fractal_gain = 0.6

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
	var batch_cells_gravel: Array[Vector2i] = []
	var batch_cells_clay: Array[Vector2i] = []
	var batch_cells_sludge: Array[Vector2i] = []
	
	for x in range(map_width):
		for y in range(map_height):
				
			var noise_val = noise.get_noise_2d(x, y)
			var material_val = 	ground_material_noise.get_noise_2d(x, y)
			var tile_case = get_tile_type(noise_val, material_val)
			var cell = Vector2i(x, y)
			if not (cell.y == 0 or cell.y == map_height):
				match tile_case.y:
					t_grass: batch_cells_grass.append(cell)
					t_sand: batch_cells_sand.append(cell)
					t_earth: batch_cells_earth.append(cell)
					t_stone: batch_cells_stone.append(cell)
					t_gravel: batch_cells_gravel.append(cell)
					t_clay: batch_cells_clay.append(cell)
					t_sludge: batch_cells_sludge.append(cell)
				
			var obj_noise_val = objective_noise.get_noise_2d(x, y)
			
			var cost = remap(noise_val, -1.0, 1.0, 50.0, 1.0)
			astar_grid.set_point_weight_scale(Vector2i(x, y), cost)
			
			if y == 0 or y == map_height-1:
				set_cell(Vector2(x, y), 2, tile_case)
			else:
				set_cell(Vector2(x, y), 1, tile_case)
				
			if noise_val < 0.5 and noise_val > 0: 
				set_bushes(noise_val, obj_noise_val, Vector2i(x, y))
				set_trees(noise_val, obj_noise_val, Vector2i(x, y))
			
			if noise_val < -0.1:
				water_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
				astar_grid.set_point_solid(Vector2i(x, y), true)
				astar_grid.set_point_weight_scale(Vector2i(x, y), 1000000)
				
			progress = x
			# use bigger value to increase generation speed ( x % 20 )
			# that decreases FPS on loading screan
			if x % 5 == 0 and y == 0 and is_inside_tree():
				await get_tree().process_frame
			elif not is_inside_tree(): return
	
	var post_process = connect_cells.bind(batch_cells_grass, batch_cells_earth, batch_cells_sand, batch_cells_stone, batch_cells_gravel, batch_cells_clay, batch_cells_sludge)
	if not Engine.is_editor_hint():
		threads.append(WorkerThreadPool.add_task(post_process, false))
	progress = map_width
	emit_signal("generation_complete")

func connect_cells(grass: Array[Vector2i], earth: Array[Vector2i], sand: Array[Vector2i], stone: Array[Vector2i], gravel: Array[Vector2i], clay: Array[Vector2i], sludge: Array[Vector2i]) -> void:
	var batch_grass: Array[Vector2i]
	var batch_earth: Array[Vector2i]
	var batch_sand: Array[Vector2i]
	var batch_stone: Array[Vector2i]
	var batch_gravel: Array[Vector2i]
	var batch_clay: Array[Vector2i]
	var batch_sludge: Array[Vector2i]
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
		if i < gravel.size()-1:
			batch_gravel = gravel.slice(i, i+chunk_size)
			set_cells_terrain_connect(batch_gravel, 0, 6, false)
		if i < clay.size()-1:
			batch_clay = clay.slice(i, i+chunk_size)
			set_cells_terrain_connect(batch_clay, 0, 4, false)
		if i < sludge.size()-1:
			batch_sludge = sludge.slice(i, i+chunk_size)
			set_cells_terrain_connect(batch_sludge, 0, 5, false)
		i += chunk_size
		OS.delay_msec(50)

func set_trees(val: float, obj_val: float, pos: Vector2i) -> void:
	var noise_sum = val+obj_val
	if noise_sum >= 0.5 and noise_sum < 0.5001:
		place_object(pos, 1, Vector2i(3, 13), true)
		return
	if noise_sum >= 0.5014 and noise_sum < 0.5015:
		place_object(pos, 1, Vector2i(24, 11), true) 
		return
	if noise_sum >= 0.5015 and noise_sum < 0.5016:
		place_object(pos, 1, Vector2i(45, 10), true)
		return
	if noise_sum >= 0.5016 and noise_sum < 0.5017:
		place_object(pos, 1, Vector2i(66, 11), true)
		return
	if noise_sum >= 0.5017 and noise_sum < 0.5018:
		place_object(pos, 1, Vector2i(90, 7), true) 
		return
	if noise_sum >= 0.5018 and noise_sum < 0.5019:
		place_object(pos, 1, Vector2i(106, 7), true) 
		return
	if noise_sum >= 0.5019 and noise_sum < 0.5020:
		place_object(pos, 1, Vector2i(3, 42), true) 
		return
	if noise_sum >= 0.5020 and noise_sum < 0.5021:
		place_object(pos, 1, Vector2i(24, 42), true) 
		return
	if noise_sum >= 0.5021 and noise_sum < 0.5022:
		place_object(pos, 1, Vector2i(45, 42), true) 
		return
	if noise_sum >= 0.5022 and noise_sum < 0.5023:
		place_object(pos, 1, Vector2i(66, 42), true) 
		return
	if noise_sum >= 0.5023 and noise_sum < 0.5024:
		place_object(pos, 1, Vector2i(90, 39), true) 
		return
	if noise_sum >= 0.5024 and noise_sum < 0.5025:
		place_object(pos, 1, Vector2i(106, 39), true) 
		return

func set_bushes(val: float, obj_val: float, pos: Vector2i) -> void:
	var noise_sum = val+obj_val
	if noise_sum >= 0.5 and noise_sum < 0.50001:
		place_object(pos, 1, Vector2i(3, 84), true)
		return
	if noise_sum >= 0.5001 and noise_sum < 0.5002:
		place_object(pos, 1, Vector2i(24, 83), true) 
		return
	if noise_sum >= 0.5002 and noise_sum < 0.5003:
		place_object(pos, 1, Vector2i(45, 83), true)
		return
	if noise_sum >= 0.5003 and noise_sum < 0.5004:
		place_object(pos, 1, Vector2i(66, 83), true)
		return
	if noise_sum >= 0.5004 and noise_sum < 0.5005:
		place_object(pos, 1, Vector2i(89, 78), true) 
		return
	if noise_sum >= 0.5005 and noise_sum < 0.5006:
		place_object(pos, 1, Vector2i(107, 78), true) 
		return
	if noise_sum >= 0.5006 and noise_sum < 0.5007:
		place_object(pos, 1, Vector2i(124, 78), true) 
		return
	if noise_sum >= 0.5007 and noise_sum < 0.5008:
		place_object(pos, 1, Vector2i(3, 115), true) 
		return
	if noise_sum >= 0.5008 and noise_sum < 0.5009:
		place_object(pos, 1, Vector2i(24, 115), true) 
		return
	if noise_sum >= 0.5009 and noise_sum < 0.5010:
		place_object(pos, 1, Vector2i(45, 115), true) 
		return
	if noise_sum >= 0.5010 and noise_sum < 0.5011:
		place_object(pos, 1, Vector2i(66, 115), true) 
		return
	if noise_sum >= 0.5011 and noise_sum < 0.5012:
		place_object(pos, 1, Vector2i(90, 111), true) 
		return
	if noise_sum >= 0.5012 and noise_sum < 0.5013:
		place_object(pos, 1, Vector2i(108, 111), true) 
		return
	if noise_sum >= 0.5013 and noise_sum < 0.5014:
		place_object(pos, 1, Vector2i(124, 111), true) 
		return

func place_object(pos: Vector2i, atlas_id: int, tile: Vector2i, is_solid: bool) -> void:
	objects_layer.set_cell(pos, atlas_id, tile)
	for x in range(-3, 4):
		for y in range(-2, 3):
			var tile_around = Vector2i(x, y)
			if astar_grid.is_in_boundsv(pos+tile_around):
				astar_grid.set_point_solid(pos+tile_around, true)
	for x in range(-7, 8):
		for y in range(-7, 8):
			var tile_around = Vector2i(x, y)
			if astar_grid.is_in_boundsv(pos+tile_around) and not astar_grid.is_point_solid(pos+tile_around):
				var dist = pos.distance_to(pos+tile_around)
				var cost = remap(dist, 1.0, 6.0, 10.0, 1.0)
				astar_grid.set_point_weight_scale(tile_around+pos, abs(cost))

func get_tile_type(val: float, m_val: float) -> Vector2i:
	if val > -0.2 and val < 0.6 and m_val > -1 and m_val < -0.7:
		return Vector2i(t_clay.x+randi_range(0, 3), t_clay.y)
	if -0.5 < val and val < -0.15: 
		if randf() > 0.99:
			return Vector2i(t_sludge.x+randi_range(0, 3), t_sludge.y-1)
		else:
			return Vector2i(t_sludge.x+randi_range(0, 3), t_sludge.y)
	if val > -0.15 and val < 0: return Vector2i(randi_range(0, 3), t_sand)
	if val > 0 and val < 0.5: return  Vector2i(randi_range(0, 3), t_grass)
	if val > 0.5: return Vector2i(randi_range(0, 3), t_earth)
	return Vector2i(randi_range(0, 3), t_stone)

func _on_generation_complete() -> void:
	pass
