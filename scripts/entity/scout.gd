class_name Scout
extends Entity

var is_onflight: bool = false

func _ready() -> void:
	super()
	specific_commands.append("takeoff")

func AI(delta: float) -> void:
	if position.distance_to(prefered_pos) > 250 : takeoff()
	elif position.distance_to(prefered_pos) < 50: landing()
	super(delta)

func exec_command(type: String, args: Array):
	match type:
		"takeoff": takeoff()
		_: super(type, args)

func idle() -> void:
	if not is_onflight:
		super()
	else:
		if not sprite: return
		match get_face_dir():
			dirrection.DOWN: sprite.play("Flight Down")
			dirrection.UP: sprite.play("Flight Up")
			dirrection.RIGHT: sprite.play("Flight Right")
			dirrection.LEFT: sprite.play("Flight Left")

func fly(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		sprite.play("Flight Right" if dir.x > 0 else "Flight Left")
		face_dir = Vector2(1, 0) if dir.x > 0 else Vector2(-1, 0)
	else:
		sprite.play("Flight Down" if dir.y > 0 else "Flight Up")
		face_dir = Vector2(0, 1) if dir.y > 0 else Vector2(0, -1)
	sight_area.rotation = Vector2.DOWN.angle_to(Vector2(face_dir))
	velocity = dir*speed*2
	move_and_slide()

func walk(dir: Vector2):
	if not is_onflight:
		super(dir)
	else: fly(dir)

func takeoff() -> void:
	is_onflight = true
	collision_mask = 3
	collision_layer = 3
	match get_face_dir():
		dirrection.UP   : sprite.play("Takeoff Up")
		dirrection.DOWN : sprite.play("Takeoff Down")
		dirrection.LEFT : sprite.play("Takeoff Left")
		dirrection.RIGHT: sprite.play("Takeoff Right")

func landing() -> void:
	is_onflight = false
	collision_mask = 1
	collision_layer = 2
	match get_face_dir():
		dirrection.UP   : sprite.play("Landing Up")
		dirrection.DOWN : sprite.play("Landing Down")
		dirrection.LEFT : sprite.play("Landing Left")
		dirrection.RIGHT: sprite.play("Landing Right")
