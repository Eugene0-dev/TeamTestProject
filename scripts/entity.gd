
class_name Entity 
extends CharacterBody2D 

@export_group("Nodes")
@export var sprite: AnimatedSprite2D
@export var hitbox: Area2D

@export var max_health: int = 100
var income_damage: int = 0

@export var outcome_damage: int = 5

@export var max_hunger: int = 100
var hunger: int = 0

@export var faction: String = "none"

@export var speed: int = 10

var schedule: Array = []
var current_task: Dictionary = {}

func _ready() -> void:
	if not sprite:
		push_warning("Забыл назначить спрайт в ", name)
	else:
		sprite.play("Idle Down")
		

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
	
	AI(delta)
	if current_task == {}: 
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
			var pos = Vector2(int(args[0]), int(args[1]))
			task["pos"] = pos
			var diff = pos - global_position
			if abs(diff.x) > abs(diff.y):
				schedule.append({"type": "mv", "pos": Vector2(pos.x, position.y)})
			else:
				schedule.append({"type": "mv", "pos": Vector2(position.x, pos.y)})
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

func complete_task() -> void:
	current_task = {}

func walk(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		sprite.play("Walk Right" if dir.x > 0 else "Walk Left")
	else:
		sprite.play("Walk Down" if dir.y > 0 else "Walk Up")
	velocity = dir*speed
	move_and_slide()

func move_at(pos: Vector2i) -> bool:
	var dist = global_position.distance_to(pos)
	var dir = global_position.direction_to(pos)
	if dist <= 5:
		velocity = Vector2.ZERO
		sprite.play("Idle Down")
		return true
	walk(dir)
	return false

func move_to(target: Node2D) -> bool:
	return false

func eat(target: Node2D) -> void:
	pass

func AI(delta: float) -> void:
	pass
