extends Camera2D

@export var speed: float = 500.0
@export var zoom_speed: float = 0.1

func _process(delta: float) -> void:
	# Движение на WASD или стрелки
	var direction = Input.get_vector("left", "right", "up", "down")
	position += direction * speed * delta / zoom.x # делим на зум, чтобы скорость не падала при отдалении
	
	# Зум на колесико мыши
	if Input.is_action_pressed("shift"):
		zoom += Vector2(zoom_speed, zoom_speed)
	if Input.is_action_pressed("space"):
		zoom -= Vector2(zoom_speed, zoom_speed)
	
	# Ограничение зума, чтобы не уйти в бесконечность
	zoom = zoom.clamp(Vector2(0.2, 0.2), Vector2(3.0, 3.0))
