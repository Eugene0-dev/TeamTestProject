
class_name Entity 
extends CharacterBody2D 

@export_group("Nodes")
@export var sprite: AnimatedSprite2D

@export_group("Stats")
@export var lifetime: int = 3600
@export var max_health: int = 100
var income_damage: int = 0

@export var outcome_damage: int = 5
@export var max_hunger: int = 100
var hunger: int = 0

@export var faction: String = "none"
@export var speed: int = 10

@onready var sight_area: Area2D = $Sight_Area

var schedule: Array = []
var current_task: Dictionary = {}

var environment: World
var specific_commands: Array = [
	"step", "mv", "mv_s", "pos", "feed", "expire", "lifetime", "kill", "play", "stop", "stopall", "st", "team"
]
var prefered_pos: Vector2
var face_dir: Vector2i

func _ready() -> void:
	sprite = $Sprite
	face_dir = Vector2i(0, 1)
	idle()
	prefered_pos = global_position

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and \
	event.button_index == MOUSE_BUTTON_LEFT\
	and event.pressed:
		Global.emit_signal("entity_selected", self)

var timer: float = 0.0
func is_tick(delta: float) -> bool:
	timer += delta
	if timer >= 1.0:
		timer = 0.0
		lifetime -= 1
		if lifetime <= 0:
			on_lifetime_end()
		return true
	return false
		
func _process(delta: float) -> void:
	var tick = is_tick(delta)
	
	if tick and hunger < max_hunger:
		hunger += 1
	if income_damage > max_health: 
		queue_free()
		return
	if hunger >= max_hunger and tick: income_damage+=1
	elif income_damage > 0 and tick: 
		var heal_rate = clamp(10 - (hunger / 10), 0, 10)
		income_damage -= heal_rate
	if tick:
		AI(delta)
	if current_task.is_empty(): 
		if schedule.is_empty():
			pass
		else: 
			current_task = schedule.pop_front()
	else:
		exec_task(current_task, delta)

func add_task(type: String, args: Array) -> void:
	var task: Dictionary = {"type": type}
	match type:
		"mv": 
			var pos = Vector2(args[0], args[1])
			var change_prefered_pos: bool
			if args.size() == 3:
				change_prefered_pos = args[2]
			else:
				change_prefered_pos = true
			if change_prefered_pos: prefered_pos = pos
			task["pos"] = pos
			var diff = pos - global_position
			if abs(diff.x) > abs(diff.y):
				schedule.append({"type": "mv", "pos": Vector2(pos.x, global_position.y)})
			else:
				schedule.append({"type": "mv", "pos": Vector2(global_position.x, pos.y)})
		"wait": task["time"] = args[0]
		
	schedule.append(task)

func exec_task(task: Dictionary, delta: float) -> void:
	match task["type"]:
		"wait":
			task["time"] -= delta
			if task["time"] <= 0: complete_task()
		"mv":
			if move_at(task["pos"]):
				complete_task()

func exec_command(type: String, args: Array):
	match type:	
		"expire":
			lifetime = 0
		"lifetime":
			lifetime = int(args[0])
		"feed":
			hunger = 0
		"pos":
			return "pos: %d %d" % [position.x, position.y]
		"sector":
			var sec = environment.get_sector_key(global_position)
			return "sec: %d %d" % [sec.x, sec.y]
		"team":
			return "faction: %s" % faction
		"play":
			sprite.play(args[0].replace("_"," "))
		"st":
			return "HP: %d\nhunger: %d" % [max_health-income_damage, max_hunger-hunger]
		"kill":
			income_damage += max_health*100
		"stop":
			complete_task()
		"stopall":
			schedule = []
			complete_task()
			sprite.play("Idle Down")
		"mv": 
			add_task("mv", [int(args[0]), int(args[1])])
		"mv_s":
			var sec_key = Vector2i(int(args[0]), int(args[1]))
			var sec = environment.sectors.get(sec_key)
			if sec:
				var sec_center = sec.get_center()
				add_task("mv", [sec_center.x, sec_center.y])
		"step":
			add_task("mv", [global_position.x+int(args[0]), global_position.y+int(args[1])])

func complete_task() -> void:
	current_task.clear()
	idle()

func idle() -> void:
	if not sprite: return
	match face_dir:
		Vector2i(0, 1):
			sprite.play("Idle Down")
		Vector2i(0, -1):
			sprite.play("Idle Up")
		Vector2i(1, 0):
			sprite.play("Idle Right")
		Vector2i(-1, 0):
			sprite.play("Idle Left")

func walk(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		sprite.play("Walk Right" if dir.x > 0 else "Walk Left")
		face_dir = Vector2i(1, 0) if dir.x > 0 else Vector2i(-1, 0)
	else:
		sprite.play("Walk Down" if dir.y > 0 else "Walk Up")
		face_dir = Vector2i(0, 1) if dir.y > 0 else Vector2i(0, -1)
	sight_area.rotation = Vector2.DOWN.angle_to(Vector2(face_dir))
	velocity = dir*speed
	move_and_slide()

func mv_forward(dist: float, overrie_prefered_pos: bool = true):
	add_task("mv", [
		global_position.x + face_dir.x*dist,
		global_position.y + face_dir.y*dist,
		overrie_prefered_pos
	])

func move_at(pos: Vector2i) -> bool:
	var dir = global_position.direction_to(pos)
	if global_position.distance_to(pos) <= 5:
		velocity = Vector2.ZERO
		return true
	var obstacles = sight_area.get_overlapping_areas()
	if obstacles.size() > 0:
		complete_task()
		if randf() > 0.5:
			face_dir = Vector2i(face_dir.y, -face_dir.x)
		else:
			face_dir = Vector2i(face_dir.y, face_dir.x)
		mv_forward(randi_range(50, 100), false)
	walk(dir)
	return false

func move_to(target: Node2D) -> bool:
	return false

func eat(target: Node2D) -> void:
	pass

func on_lifetime_end() -> void:
	queue_free()

func AI(delta: float) -> void:
	if global_position.distance_to(prefered_pos) > 5 and schedule.size() == 0:
		add_task("mv", [prefered_pos.x, prefered_pos.y])
