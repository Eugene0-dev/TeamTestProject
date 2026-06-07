extends Control

@export var world_map: WorldMap

@onready var cont_button: Button
@onready var exit_button: Button
@onready var seed_label: Label

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	cont_button = $Continue_Button
	exit_button = $Exit_Button
	seed_label = $Seed_Label
	if world_map:
		seed_label.text = "Seed:%d" % world_map.world_seed

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("esc"): switch_visibility()

func switch_visibility() -> void:
	visible = !visible 
	get_tree().paused = visible

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_continue_button_pressed() -> void:
	switch_visibility()
