@tool
class_name Item
extends Node2D

enum id {
	WOOD, REDBALL, LAMPFRUIT, id3,
	id4, id5, id6, id7,
	id8, id9, id10, id11,
	id12, id13, id14, id15
}

@export var item_id: id = id.WOOD:
	set(val):
		item_id = val
		update_sprite_region()
		
@export var atlas_columns: int
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	update_sprite_region()

func update_sprite_region() -> void:
	if not sprite: return
	
	var atlas = sprite.texture as AtlasTexture
	var pos: Vector2i = Vector2i.ZERO
	pos.x = item_id % atlas_columns
	pos.y = item_id / atlas_columns
			
	atlas.region = Rect2(
		pos.x * 17 + 1, pos.y * 17 + 1,
			16, 16
	)
