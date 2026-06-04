extends Node2D

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
