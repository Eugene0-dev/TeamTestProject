extends Control

@export var camera: Camera2D
@export var world: Node2D

@onready var info_label: Label = $Info_Label
@onready var target_label: Label = $Target_Label
@onready var command_line: LineEdit = $Command_LineEdit
@onready var command_history: TextEdit = $Command_History_TextEdit
@onready var command_hints_menu: ItemList = $Command_Hints_ItemList

var target: Entity
var line_counter: int = 0
var commands_no_target: Array = [
	"select", "find", "cam"
]
var commands_target: Array = [
	"mv", "pos", "feed", "kill", "play", "stop", "stopall", "st", "team"
]
func _ready() -> void:
	Global.entity_selected.connect(_on_entity_selected)
	commands_hint_update(false)
	
func commands_hint_update(is_target: bool):
	command_hints_menu.clear()
	for cmd in commands_no_target:
		command_hints_menu.add_item(cmd)
	if is_target:
		for cmd in commands_target:
			command_hints_menu.add_item(cmd)
	
func _init() -> void:
	visible = false
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("alt"): visible = !visible
	if visible and Input.is_action_just_pressed("enter"):
		command(command_line.text)
		command_line.text = ""
		line_counter = 0
		visible = false
	if Input.is_action_just_pressed("ui_up"):
		command_line.text = command_history.text.get_slice("\n", line_counter)
		line_counter += 1
	if Input.is_action_just_pressed("ui_down"):
		line_counter -= 1
		command_line.text = command_history.text.get_slice("\n", line_counter)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): 
		target = null
		target_label.text = "tg: None"
		commands_hint_update(false)

func command(cmd_line: String):
	command_history.text = cmd_line+"\n"+command_history.text
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
		"cam":
			if len(cmd)>2:
				camera.position = Vector2(int(cmd[1]), int(cmd[2]))
			elif target:
				camera.position = target.position
		"find":
			var target = world.get_node_or_null(cmd[1])
			if target:
				camera.position = target.position
		"select":
			var target = world.get_node_or_null(cmd[1])
			if target:
				Global.emit_signal("entity_selected", target)

func _on_entity_selected(entity: Entity):
	target = entity
	target_label.text = "tg: "+entity.name
	commands_hint_update(true)


func _on_command_hints_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	command_line.text = command_hints_menu.get_item_text(index)
