extends Control

@onready var info_label: Label = $Info_Label
@onready var target_label: Label = $Target_Label
@onready var command_line: LineEdit = $Command_LineEdit

var target: Entity

func _ready() -> void:
	Global.entity_selected.connect(_on_entity_selected)

func _init() -> void:
	visible = false
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("c"): visible = !visible
	if visible and Input.is_action_just_pressed("enter"):
		command(command_line.text)
		visible = false

func command(cmd_line: String):
	var cmd = cmd_line.split(" ")
	var task = {}
	match cmd[0]:
		"feed":
			target.hunger = 0
		"pos":
			info_label.text = "pos: %d %d" % [target.position.x, target.position.y]
		"team":
			info_label.text = "faction: %s" % target.faction
		"play":
			target.sprite.play(cmd[1].replace("_"," "))
		"st":
			info_label.text = "HP: %d\nhunger: %d" % [target.max_health-target.income_damage, target.max_hunger-target.hunger]
		"kill":
			target.income_damage += target.max_health*100
		"stop":
			target.complete_task()
		"stopall":
			target.schedule = []
			target.complete_task()
		"mv": 
			target.add_task("mv", [cmd[1], cmd[2]])

func _on_entity_selected(entity: Entity):
	target = entity
	target_label.text = "tg: "+entity.name
