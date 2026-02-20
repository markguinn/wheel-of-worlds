class_name FishMonster
extends RigidBody2D

const JUMP_X_FACTOR = 0.8 # moderates the horizontal linear velocity when jumping from the bottom


## Defines the area where the beast can roam. Defaults to the parent node.
@export var territory: Area2D
@export var jump_y_min := 1200.0
@export var jump_y_max := 1800.0
@export var jump_x_min := 200.0
@export var jump_x_max := 1000.0

var territory_rect: Rect2

@onready var hit_box: Area2D = $HitBox
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if not territory:
		territory = get_parent()
	for node in territory.get_children():
		if node is CollisionShape2D:
			territory_rect = node.shape.get_rect()
			print("[Fish] territory=", territory_rect)
			territory_rect.position = node.to_global(territory_rect.position)
			print("[Fish] territory=", territory_rect)
	if not territory_rect:
		print("[FishMonster] WARN: no territory rect found. This node should be the child of an Area2d")


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if global_position.y > territory_rect.position.y + territory_rect.size.y:
		global_position.y = territory_rect.position.y + territory_rect.size.y
		linear_velocity.y = -randf_range(jump_y_min, jump_y_max)
		var px := GameManager.get_player().global_position.x
		linear_velocity.x = (px - global_position.x) * JUMP_X_FACTOR
		linear_velocity.x = signf(linear_velocity.x) * clampf(absf(linear_velocity.x), jump_x_min, jump_x_max)
		print("[FishMonster] jump:", linear_velocity, " from:", global_position, " player:", GameManager.get_player().global_position.x)
	if global_position.x > territory_rect.position.x + territory_rect.size.x:
		global_position.x = territory_rect.position.x + territory_rect.size.x
		linear_velocity.x = -randf_range(jump_x_min, jump_x_max)
		print("[FishMonster] right:", linear_velocity, " from:", global_position)
	if global_position.x < territory_rect.position.x:
		global_position.x = territory_rect.position.x
		linear_velocity.x = randf_range(jump_x_min, jump_x_max)		
		print("[FishMonster] left:", linear_velocity, " from:", global_position)
	if linear_velocity.x > 0:
		sprite.rotation = linear_velocity.angle()
		sprite.scale.x = -absf(sprite.scale.x)
	else:
		sprite.rotation = PI + linear_velocity.angle()
		sprite.scale.x = absf(sprite.scale.x)
