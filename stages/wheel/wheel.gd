class_name WheelStage
extends Stage


# converts spin_velocity into degrees per second
const ROTATION_FACTOR = 4.0
# converts spin_velocity into pixels per second of player movement
# this needs to match ROTATION_FACTOR such that it looks like you're moving with the wheel
# TODO: we can probably derive this from above using radius of wheel
const OBJECT_FACTOR = 50.0 
const CAMERA_FACTOR = 0.05
const MIN_ZOOM = 0.5
const MAX_ZOOM = 1.0


var spin_velocity := 0.0
var in_gravity := 0.0

@onready var wheel_body: Node2D = $WheelTiles
# We're sort of forcing the physics here with two area2d's.
# If you enter one, it starts rotating the wheel and moving you until you're back in the middle.
# I think that will be less glitchy than using a rigidbody and force/impule.
@onready var left_gravity: Area2D = $LeftGravity
@onready var right_gravity: Area2D = $RightGravity


func _ready() -> void:
	left_gravity.body_entered.connect(_on_enter_gravity.bind(-1.0))
	left_gravity.body_exited.connect(_on_exit_gravity)
	right_gravity.body_entered.connect(_on_enter_gravity.bind(1.0))
	right_gravity.body_exited.connect(_on_exit_gravity)


func init_player_at_portal(portal: Node2D) -> void:
	var player := GameManager.get_player()
	var rot := player.position.normalized().angle() + PI / 2.0
	wheel_body.rotation = rot
	player.global_position = portal.global_position


func _process(delta: float) -> void:
	if in_gravity:
		spin_velocity += in_gravity * delta
	else:
		spin_velocity = move_toward(spin_velocity, 0.0, delta)

	if spin_velocity:
		wheel_body.rotation_degrees += spin_velocity * ROTATION_FACTOR * delta

		for node in get_tree().get_nodes_in_group("free_movers"):
			node.position.x -= spin_velocity * OBJECT_FACTOR * delta

		var zoom := clampf(1.0 - absf(spin_velocity) * CAMERA_FACTOR, MIN_ZOOM, MAX_ZOOM)
		var cam := get_viewport().get_camera_2d()
		cam.zoom = cam.zoom.move_toward(Vector2(zoom, zoom), delta)


func _on_enter_gravity(body: Node2D, direction: float) -> void:
	if body is Player:
		in_gravity = direction


func _on_exit_gravity(body: Node2D) -> void:
	if body is Player:
		in_gravity = 0.0
