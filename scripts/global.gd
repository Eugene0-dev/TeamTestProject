extends Node

var debug_node: DevFeatures

func throw_dice(d: int, val: int) -> bool:
	return randi_range(1, d) <= val

signal place_item(item_id, pos)

signal grow_plant(type, pos)

signal entity_selected(entity)

signal entity_unselected(entity)

signal track_navigation_enabled(entity)

signal track_navigation_disabled()

signal nav_layer_enabled(nav_grid)

signal nav_layer_disabled()
