@tool
class_name Item
extends Node2D

enum id {
	LOG, BOLD_LOG, ROCK, REDBALL,
	LAMPFRUIT, SUNFRUIT, PUSHFRUIT, HELLBERRY,
	SUCKBERRY, WHITEBALLS, BLACKBALL, CLOWNBERRY,
	SEGBERRY, BEGBERRY, SPIRITBERRY, RUSHBERRY,
	ID16, ID17, ID18, ID19
}

@export var item_id: id = id.LOG:
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
