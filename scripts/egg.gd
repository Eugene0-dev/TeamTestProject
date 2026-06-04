
class_name Egg
extends Entity

@export var type: String

func _ready() -> void:
	var entity_src = "res://entity/ants/%s.tscn" % type
	var is_entity_src_valid = FileAccess.file_exists(entity_src)
	if not is_entity_src_valid: 
		queue_free()

func _process(delta: float) -> void:
	is_tick(delta)

func on_lifetime_end() -> void:
	if environment:
		var subject = environment.create_entity("ants/%s" % type, position)
		if subject:
			subject.faction = faction
			var num = name.split("_")[2]
			subject.name = type.capitalize()+"_"+num
	super()
