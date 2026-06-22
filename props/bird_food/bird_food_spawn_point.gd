class_name BirdFoodSpawnPoint
extends Marker2D

# This is a spot that spawns bird food. You probably want to place
# One or more of these on a bush or tree and add one or more BirdFood
# scenes as a child. If you place more than one child node, it will
# choose between them when it's time to spawn a new one. New food is
# spawned only when the old food is taken by the player.

# Bird food is a distraction for the bird - if there is food in range
# it will always go for the food instead of a prop.

## Min amount of time after the food is taken before it grows back
@export var min_spawn_seconds := 4.0
## Max amount of time after the food is taken before it grows back
@export var max_spawn_seconds := 12.0

var templates: Array[BirdFood] = []
var spawn_id := 1
var active_food: BirdFood = null

func _ready() -> void:
	for n in get_children():
		if n is BirdFood:
			Log.debug(self, "found template node", n)
			templates.append(n)
			remove_child.call_deferred(n)
	_set_next_timer.call_deferred()


func _set_next_timer() -> void:
	var timeout := randf_range(min_spawn_seconds, max_spawn_seconds)
	var timer := get_tree().create_timer(timeout)
	timer.timeout.connect(spawn_food)
	Log.debug(self, "next food spawning in", timeout)


func spawn_food() -> void:
	var idx := randi_range(0, templates.size() - 1)
	var node: BirdFood = templates[idx].duplicate()
	node.name = name + "_" + str(spawn_id)
	spawn_id += 1
	add_sibling(node)
	node.global_position = global_position
	node.collected.connect(_on_food_taken)
	node.freeze = true
	node.rotation = randf_range(-0.5, 0.5)
	active_food = node
	Log.debug(self, "spawning food", idx, node)


func _on_food_taken() -> void:
	if not active_food:
		return
	Log.debug(self, "food was collected", active_food)
	active_food.collected.disconnect(_on_food_taken)
	active_food = null
	_set_next_timer.call_deferred()
