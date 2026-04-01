class_name FishMonster
extends MoveableRigidBody2D

const JUMP_X_FACTOR = 0.8 # moderates the horizontal linear velocity when jumping from the bottom
const BUFFER_LEN = 90

signal jumping

## Defines the area where the beast can roam. Defaults to the parent node.
@export var territory: Area2D
@export var jump_y_min := 1200.0
@export var jump_y_max := 1800.0
@export var jump_x_min := 200.0
@export var jump_x_max := 1000.0

var territory_rect: Rect2
var bone_pos_ring_buffer: Array[Vector2] = []
var ring_buffer_idx := 0
var bone_idx_idx: Array[int] = []

@onready var hit_box: Area2D = $Sprite2D/HitBox
@onready var sprite: Node2D = $Sprite2D
@onready var main_shape: CollisionShape2D = $CollisionShape2D
@onready var polygon_l: Polygon2D = $Sprite2D/PolygonL
@onready var polygon_r: Polygon2D = $Sprite2D/PolygonR
#@onready var tail_body: MoveableRigidBody2D = $TailBody
#@onready var tail_joint: PinJoint2D = $PinJoint2D
@onready var tail_target: Marker2D = $TailTarget
@onready var bones: Array[Bone2D] = [
	$Sprite2D/Skeleton2D/Bone2D,
	$Sprite2D/Skeleton2D/Bone2D/Bone2D,
	$Sprite2D/Skeleton2D/Bone2D/Bone2D/Bone2D,
	$Sprite2D/Skeleton2D/Bone2D/Bone2D/Bone2D/Bone2D,
]


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
	
	#polygon_r.modulate = Color.GREEN
	#polygon_r.texture_scale = Vector2(-1, 1)
	#polygon_r.texture_offset = Vector2(-900, 0)
	for p in polygon_r.polygon:
		#p.x = 900.0 - p.x
		p.y = 700.0 - p.y
	for p in polygon_r.uv:
		#p.x = 900.0 - p.x
		p.y = 700.0 - p.y

	for i in range(BUFFER_LEN):
		bone_pos_ring_buffer.append(Vector2.INF)
	var total_len := 0.0
	for i in range(bones.size()):
		total_len += bones[i].get_length()
	for i in range(bones.size()):
		bone_idx_idx.append(floori(bones[i].get_length() * float(BUFFER_LEN) / total_len))
		if i > 0:
			bone_idx_idx[i] += bone_idx_idx[i - 1]
	Log.debug(self, "bii", bone_idx_idx)
	#_deferred_setup.call_deferred()
	#$Sprite2D/Skeleton2D.

#func _deferred_setup():
	#$TailBody/RemoteTransform2D.remote_path = tail_target.get_path()
	#tail_body.reparent(get_parent())
	#tail_joint.node_a = get_path()
	#tail_joint.node_b = tail_body.get_path()


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


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	super._integrate_forces(state)
	if global_position.y > territory_rect.position.y + territory_rect.size.y:
		global_position.y = territory_rect.position.y + territory_rect.size.y
		linear_velocity.y = -randf_range(jump_y_min, jump_y_max)
		var px := GameManager.get_player().global_position.x
		linear_velocity.x = (px - global_position.x) * JUMP_X_FACTOR
		linear_velocity.x = signf(linear_velocity.x) * clampf(absf(linear_velocity.x), jump_x_min, jump_x_max)
		#tail_body.set_next_global_position(global_position)
		#tail_body.set_next_linear_velocity(Vector2.ZERO)
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
	rotation = 0 # linear_velocity.angle()
	#bones[0].rotation = move_toward(bones[0].rotation, linear_velocity.angle(), 0.1)

func _physics_process(_delta: float) -> void:
	if linear_velocity.x > 0:
	#if bones[0].global_position.x > tail_target.global_position.x:
		##rotation = move_toward(rotation, linear_velocity.angle(), 0.1)
		#bones[0].rotation = move_toward(bones[0].rotation, linear_velocity.angle(), 0.1)
		polygon_r.show()
		polygon_l.hide()
		#sprite.scale.x = -absf(sprite.scale.x)
		#pass
	else:
		##rotation = move_toward(rotation, PI + linear_velocity.angle(), 0.1)
		#bones[0].rotation = move_toward(bones[0].rotation, PI + linear_velocity.angle(), 0.1)
		polygon_r.hide()
		polygon_l.show()
		#sprite.scale.x = absf(sprite.scale.x)
		#pass

	#main_shape.rotation = bones[0].global_position.angle_to_point(tail_target.global_position)

	var next_idx = (ring_buffer_idx + 1) % BUFFER_LEN
	bone_pos_ring_buffer[ring_buffer_idx] = bones[0].global_position
	if bone_pos_ring_buffer[next_idx] != Vector2.INF:
		tail_target.global_position = bone_pos_ring_buffer[next_idx]
	for i in range(bones.size()):
		var i2 := (ring_buffer_idx + BUFFER_LEN - bone_idx_idx[i]) % BUFFER_LEN
		var v := bone_pos_ring_buffer[i2]
		if v != Vector2.INF:
			if i < bones.size() - 1:
				bones[i + 1].global_position = v
			bones[i].global_rotation = bones[i].global_position.angle_to_point(v)
	ring_buffer_idx = next_idx
	#if not GameManager.rate_limit(500, "dasffdsf"):
		#Log.debug(self, ring_buffer_idx, bones[0].global_position, tail_target.global_position, global_rotation, sprite.global_rotation)
