extends Control

@onready var hp_bar: ProgressBar = $HP_ProgressBar
@onready var hunger_bar: ProgressBar = $Hunger_ProgressBar
@onready var name_label: Label = $Name_Label
@onready var faction_label: Label = $Faction_Label

var target: Entity

func _init() -> void:
	visible = false

func _ready() -> void:
	Global.entity_selected.connect(_on_entity_selected)
	
func _process(delta: float) -> void:
	if target:
		hp_bar.value = target.max_health-target.income_damage
		hunger_bar.value = target.hunger
	else:
		visible = false
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): target = null
	
func _on_entity_selected(entity: Entity):
	target = entity
	hp_bar.max_value = target.max_health
	hunger_bar.max_value = target.max_hunger
	name_label.text = target.name
	faction_label.text = target.faction
	visible = true
