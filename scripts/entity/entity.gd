
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

var subtasks: Array = []
var current_subtask: Dictionary = {}

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
	
	if not current_subtask.is_empty():
		exec_subtask(current_subtask, delta)
	elif not subtasks.is_empty():
		current_subtask = subtasks.pop_front()
		exec_subtask(current_subtask, delta)
	elif not current_task.is_empty():
		exec_task(current_task, delta) 
	elif not schedule.is_empty():
		current_task = schedule.pop_front()
	else: idle()

func add_task(type: String, args: Array) -> void:
	var task: Dictionary = {"type": type}
	match type:
		"mv": 
			var pos = Vector2(args[0], args[1])
			if not args[2]:
				prefered_pos = pos
			task["pos"] = pos
		"wait": task["time"] = args[0]
		
	schedule.append(task)

func add_subtask(type: String, args: Array) -> void:
	var subtask: Dictionary = {"type": type}
	match type:
		"mv":
			var pos = Vector2i(args[0], args[1])
			subtask["pos"] = pos
			subtask["evade"] = args[2]
	subtasks.append(subtask)

func exec_task(task: Dictionary, delta: float) -> int:
	match task["type"]:
		"wait":
			task["time"] -= delta
			if task["time"] <= 0: 
				complete_task()
				return 1
		"mv":
			var pos = task["pos"]
			var dir = global_position.direction_to(pos)
			if global_position.distance_to(pos) > 5:
				if abs(dir.x) > abs(dir.y):
					add_subtask("mv", [pos.x, global_position.y, false])
					add_subtask("mv", [pos.x, pos.y, false])
				else:
					add_subtask("mv", [global_position.x, pos.y, false])
					add_subtask("mv", [pos.x, pos.y, false])
				return 0
			else:
				complete_task()
				return 1
	return 1

func exec_subtask(task: Dictionary, delta: float) -> int:
	var status: int
	match task["type"]:
		"mv":
			var results = move_at(task["pos"])
			status = results["status"]
			if status == -1:
				complete_subtask()
				on_stuck_handle(results["obstacle"])
			
	if status == 1: complete_subtask()
	return status

func on_stuck_handle(obstacle: Area2D) -> void:
	subtasks.clear()
	turn("left")
	var evade_point = global_position+Vector2(face_dir)*100
	current_subtask = {"type": "mv", "pos": Vector2(evade_point.x, evade_point.y), "evade": true}
	var dir = evade_point.direction_to(prefered_pos)
	if abs(dir.x) > abs(dir.y):
		add_subtask("mv", [evade_point.x, prefered_pos.y, false])
		add_subtask("mv", [prefered_pos.x, prefered_pos.y, false])
	else:
		add_subtask("mv", [prefered_pos.x, evade_point.y, false])
		add_subtask("mv", [prefered_pos.x, prefered_pos.y, false])


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
			subtasks.clear()
			complete_subtask()
		"stopall":
			schedule.clear()
			subtasks.clear()
			complete_task()
			complete_subtask()
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
			add_task("mv", [global_position.x+int(args[0]), global_position.y+int(args[1]), false])

func complete_task() -> void:
	current_task.clear()
	idle()

func complete_subtask() -> void:
	current_subtask.clear()
	if subtasks.is_empty(): complete_task()

func idle() -> void:
	if not sprite: return
	match face_dir:
		Vector2i(0, 1): sprite.play("Idle Down")
		Vector2i(0, -1): sprite.play("Idle Up")
		Vector2i(1, 0): sprite.play("Idle Right")
		Vector2i(-1, 0): sprite.play("Idle Left")

func walk(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		sprite.play("Walk Right" if dir.x > 0 else "Walk Left")
		face_dir = Vector2(1, 0) if dir.x > 0 else Vector2(-1, 0)
	else:
		sprite.play("Walk Down" if dir.y > 0 else "Walk Up")
		face_dir = Vector2(0, 1) if dir.y > 0 else Vector2(0, -1)
	sight_area.rotation = Vector2.DOWN.angle_to(Vector2(face_dir))
	velocity = dir*speed
	move_and_slide()

func move_at(pos: Vector2i) -> Dictionary:
	var dir = global_position.direction_to(pos)
	if global_position.distance_to(pos) <= 5:
		return {"status": 1}
	var obstacles = sight_area.get_overlapping_areas()
	if obstacles.size() > 0 and not current_subtask["evade"]: return {"status": -1, "obstacle": obstacles[0]}
	walk(dir)
	return {"status": 0}

func move_to(target: Node2D) -> bool:
	return false

func turn(side: String) -> void:
	match side:
		"left": 
			face_dir = Vector2i(face_dir.y, -face_dir.x)
		"right":
			face_dir = Vector2i(-face_dir.y, face_dir.x)
	sight_area.rotation = Vector2.DOWN.angle_to(Vector2(face_dir))
	idle()

func eat(target: Node2D) -> void:
	pass

func on_lifetime_end() -> void:
	queue_free()

func is_busy() -> bool:
	return not (subtasks.is_empty() and\
	 schedule.is_empty() and\
	 current_subtask.is_empty() and\
	 current_task.is_empty())

func AI(delta: float) -> void:
	if global_position.distance_to(prefered_pos) > 10 and not is_busy():
		add_task("mv", [prefered_pos.x, prefered_pos.y])
