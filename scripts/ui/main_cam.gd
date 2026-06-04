extends Camera2D

@export var speed: float = 500.0
@export var zoom_speed: float = 0.1
var move_lock: bool = false

func _process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if Input.is_action_just_pressed("alt"): move_lock = !move_lock
	if Input.is_action_just_pressed("enter"): move_lock = false
	
	if not move_lock:
		position += direction * speed * delta / zoom.x
		
		if Input.is_action_pressed("shift"):
			zoom += Vector2(zoom_speed, zoom_speed)
		if Input.is_action_pressed("space"):
			zoom -= Vector2(zoom_speed, zoom_speed)
	
	zoom = zoom.clamp(Vector2(0.2, 0.2), Vector2(3.0, 3.0))
