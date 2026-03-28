class_name FishMonster
extends MoveableRigidBody2D

const JUMP_X_FACTOR = 0.8 # moderates the horizontal linear velocity when jumping from the bottom

signal jumping

## Defines the area where the beast can roam. Defaults to the parent node.
@export var territory: Area2D
@export var jump_y_min := 1200.0
@export var jump_y_max := 1800.0
@export var jump_x_min := 200.0
@export var jump_x_max := 1000.0

var territory_rect: Rect2

@onready var hit_box: Area2D = $Sprite2D/HitBox
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if not territory:
		territory = get_parent()
	for node in territory.get_children():
		if node is CollisionShape2D:
			territory_rect = node.shape.get_rect()
			territory_rect.position = node.to_global(territory_rect.position)
	Log.debug(self, "territory", territory_rect)
	if not territory_rect:
		Log.warn(self, self.get_path(), "no territory rect found. This node should be the child of an Area2d")
	hit_box.body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	Log.debug(self, "contact with ", body.name)
	if body is Stone:
		VFX.shake(VFX.SHORT, VFX.QUAKE)
		apply_impulse(-linear_velocity * 2)
	elif body is Player and body.state_machine.get_active() != "Ragdoll":
		VFX.shake(VFX.MID, VFX.QUAKE)
		body.velocity = linear_velocity * 2
		body.state_machine.transition_by_name.call_deferred("Ragdoll")
		apply_impulse(-linear_velocity * 1.5)
	elif body is Plank:
		body.apply_impulse(linear_velocity * 0.8)
		apply_impulse(-linear_velocity * 1.5)
	elif body is Orb:
		body.apply_impulse(linear_velocity * 0.01)
		apply_impulse(-linear_velocity * 1.5)


func _integrate_forces(_state: PhysicsDirectBodyState2D) -> void:
	if global_position.y > territory_rect.position.y + territory_rect.size.y:
		global_position.y = territory_rect.position.y + territory_rect.size.y
		linear_velocity.y = -randf_range(jump_y_min, jump_y_max)
		var px := GameManager.get_player().global_position.x
		linear_velocity.x = (px - global_position.x) * JUMP_X_FACTOR
		linear_velocity.x = signf(linear_velocity.x) * clampf(absf(linear_velocity.x), jump_x_min, jump_x_max)
		jumping.emit.call_deferred()
		Log.debug(self, "jump:", linear_velocity, "from:", global_position, "player:", GameManager.get_player().global_position.x)
	if global_position.x > territory_rect.position.x + territory_rect.size.x:
		global_position.x = territory_rect.position.x + territory_rect.size.x
		linear_velocity.x = -randf_range(jump_x_min, jump_x_max)
		Log.debug(self, "right:", linear_velocity, "from:", global_position)
	if global_position.x < territory_rect.position.x:
		global_position.x = territory_rect.position.x
		linear_velocity.x = randf_range(jump_x_min, jump_x_max)		
		Log.debug(self, "left:", linear_velocity, "from:", global_position)
	if linear_velocity.x > 0:
		rotation = move_toward(rotation, linear_velocity.angle(), 0.1)
		sprite.scale.x = -absf(sprite.scale.x)
	else:
		rotation = move_toward(rotation, PI + linear_velocity.angle(), 0.1)
		sprite.scale.x = absf(sprite.scale.x)
