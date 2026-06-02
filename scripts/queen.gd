
class_name Queen
extends Entity

func _ready() -> void:
	specific_commands.append("breed")

func AI(delta: float) -> void:
	if faction == "none":
		faction = create_faction()
		
func create_faction() -> String:
	var q_name = name.split("_")
	if len(q_name) > 1:
		var num = q_name[1]
		return "Swarm_%s" % num
	else:
		return "Swarm_NaN"
		
func exec_command(type: String, args: Array) -> void:
	match type:
		"breed": breed(args[0])
	
func breed(type: String) -> void:
	if environment:
		var subject = environment.create_entity("ants/%s" % type, position+Vector2(50, 0))
		if subject:
			subject.faction = faction
