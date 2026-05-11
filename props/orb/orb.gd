class_name Orb
extends MoveableRigidBody2D


signal persisted_state_changed(node: Node)


const RADIUS = 64.0
const SMOOSHING_EASE = PI
const SPEED_SNAP = 20.0
const POS_SNAP = 256.0
const SKEW_STRENGTH = 1.0

const IMPACT_STRETCH = 0.25
const IMPACT_MIN_VEL = 200.0
const IMPACT_MAX_VEL = 1000.0

var start_pos: Vector2
var last_pos: Vector2
var iris_velocity: Vector2
var iris_base_scale: Vector2

@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var iris: Sprite2D = $SquishContainer/WhiteSphere/Iris
@onready var sprite: Sprite2D = $SquishContainer/WhiteSphere
@onready var squisher: Node2D = $SquishContainer
@onready var pos_history: PositionHistoryBuffer = $PositionHistoryBuffer


func _ready() -> void:
	super._ready()
	start_pos = global_position
	iris_base_scale = iris.scale
	impact.connect(_on_impact)


func set_checkpoint() -> void:
	start_pos = global_position


func reset_after_fall() -> void:
	# TODO: make a fun animation
	set_next_global_position(start_pos)


func get_persisted_state() -> Dictionary:
	return { "position": position }


func restore_persisted_state(data: Dictionary) -> void:
	if "position" in data:
		position = data.get("position")


func _physics_process(_delta: float) -> void:
	if not GameManager.rate_limit(500, name) and not position.is_equal_approx(last_pos):
		persisted_state_changed.emit(self)
		last_pos = position


func _process(delta: float) -> void:
	var pos = iris.position #.rotated(rotation)
	var target_v := linear_velocity #.rotated(-rotation)
	var edge_ratio := clampf(ease(pos.length() / RADIUS, SMOOSHING_EASE), 0.0, 1.0)
	if edge_ratio >= 1.0:
		iris.visible = false
	else:
		iris.position += (linear_velocity - iris_velocity) * delta
		iris.visible = true
		iris.scale = iris_base_scale
		if abs(pos.y) > abs(pos.x) and not is_zero_approx(pos.y):
			iris.skew = edge_ratio * SKEW_STRENGTH * pos.x / pos.y
			iris.scale.y = lerpf(iris.scale.y, 0.0, ease(absf(pos.y) / RADIUS, SMOOSHING_EASE))
		elif not is_zero_approx(pos.x):
			iris.skew = edge_ratio * SKEW_STRENGTH * pos.y / pos.x
			iris.scale.x = lerpf(iris.scale.x, 0.0, ease(absf(pos.x) / RADIUS, SMOOSHING_EASE))
	iris.position = iris.position.move_toward(Vector2.ZERO, delta * POS_SNAP * edge_ratio)
	iris_velocity = iris_velocity.move_toward(target_v, delta * SPEED_SNAP)
	
	# we want the orb to squish slightly when it hits the ground or a wall
	# this extra wrapper node can be counter-rotated when the orb spins so
	# it's always true to the ground. we then re-rotate the inner sprite so
	# the iris rotates as expected. then we can just apply an x or y scale
	# to initiate the squish and this move_toward will reset it back to even
	squisher.scale = squisher.scale.move_toward(Vector2.ONE, delta)
	squisher.rotation = -rotation
	squisher.position.y = lerpf(50.0, 0.0, squisher.scale.y)
	sprite.rotation = rotation


func squish(vel: Vector2, _collision_point: Vector2, collision_normal: Vector2) -> Vector2:
	if vel.length() < IMPACT_MIN_VEL:
		return Vector2.ZERO
	var impact_amt := IMPACT_STRETCH * smoothstep(IMPACT_MIN_VEL, IMPACT_MAX_VEL, vel.length())
	if absf(vel.y) > absf(vel.x):
		squisher.scale.y = 1.0 - impact_amt
		squisher.scale.x = 1.0 + impact_amt * 0.5
	else:
		squisher.scale.x = 1.0 - impact_amt
		squisher.scale.y = 1.0 + impact_amt * 0.5
	return collision_normal * 800.0

# TODO: this still looks kind of janky. I think we'll do better if we can base it on
# the actual acceleration (i.e. quick slowdown squishes and maybe quick speedup stretches)
func _on_impact(collision_point: Vector2, vel: Vector2, _colliding_body: Node, _part: MoveableRigidBody2D) -> void:
	squish(vel, collision_point, (collision_point - global_position).normalized())
