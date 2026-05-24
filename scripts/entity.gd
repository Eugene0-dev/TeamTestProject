
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

func _ready() -> void:
	if not sprite:
		push_warning("Забыл назначить спрайт в ", name)
	else:
		sprite.play("Idle")
		

var timer: float = 0.0
func is_tick(delta: float) -> bool:
	timer += delta
	if timer >= 1.0:
		timer = 0.0
		return true
	return false
		
func _process(delta: float) -> void:
	var tick = is_tick(delta)
	
	if income_damage > max_health: 
		queue_free()
		return
	if hunger >= max_hunger and tick: income_damage+=1
	elif income_damage > 0 and tick: 
		var heal_rate = max_hunger % (int(hunger) + 1)
		income_damage -= heal_rate
	
	AI()

func walk(dir: Vector2) -> void:
	velocity = dir*speed
	sprite.play("Walk Down")
	move_and_slide()

func move_to(target: Node2D) -> void:
	pass

func eat(target: Node2D) -> void:
	pass

func AI() -> void:
	pass
