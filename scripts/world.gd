extends Node2D

func create_entity(link: String, pos: Vector2) -> Entity:
	var scene: PackedScene = load("res://entity/%s.tscn" % link)
	if scene:
		if scene.can_instantiate():
			var subject = scene.instantiate()
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
	
	if not get_node_or_null(name):
		return name
	else:
		return create_entity_name(subject)
