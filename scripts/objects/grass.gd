@tool
class_name Grass
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

enum types{GRASS0, GRASS1, GRASS2}
@export var type: types = types.GRASS0:
	set(val):
		type = val
		update_sprite_region()

func _ready() -> void:
	update_sprite_region()

func update_sprite_region() -> void:
	if not sprite: return
	
	var atlas = sprite.texture as AtlasTexture
			
	atlas.region = Rect2(
		type * 9 + 1, 1,
			8, 8
	)
