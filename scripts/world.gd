
class_name World
extends Node2D

@onready var sun: DirectionalLight2D = $Sun
@onready var clouds: ColorRect = $Clouds
@onready var camera: Camera2D = $MainCam

@export var world_map: WorldMap
var sectors: Dictionary

func _ready() -> void:
	sectors = world_map.sectors
	clouds.size.x = world_map.map_width_px
	clouds.size.y = world_map.map_height_px

func create_entity(link: String, pos: Vector2, extra: String = "") -> Entity:
	var scene: PackedScene = load("res://entity/%s.tscn" % link)
	if scene:
		if scene.can_instantiate():
			var subject = scene.instantiate()
			if subject is Egg and extra != "":
				subject.type = extra
			subject.name = create_entity_name(subject)
			subject.position = pos
			subject.environment = self
			add_child(subject)
			return subject
	return null

func create_entity_name(subject: Entity) -> String:
	var name: String
	var num: int = randi_range(0, 4000)
	if subject is Queen:
		name = "Queen_%d" % num
	elif subject is Drone:
		name = "Drone_%d" % num
	elif subject is Soldier:
		name = "Soldier_%d" % num
	elif subject is Egg:
		name = "Egg_%s_%d" % [subject.type, num]
	
	if not get_node_or_null(name):
		return name
	else:
		return create_entity_name(subject)

func get_sector_key(pos: Vector2i) -> Vector2i:
	var x = pos.x >> 8
	var y = pos.y >> 8
	return Vector2i(x, y)

func get_sector_rect(key: Vector2i) -> Rect2i:
	return sectors[key]

func get_dir_to_sector(from: Vector2, key: Vector2i) -> Vector2i:
	var sector_center = sectors[key].get_center()
	return from.direction_to(sector_center)

func _on_ground_generation_complete() -> void:
	var pos = Vector2i(
		randi_range(100, world_map.map_width_px-100),
		randi_range(100, world_map.map_height_px-100)
	)
	create_entity("ants/queen", pos)
	camera.position = pos
