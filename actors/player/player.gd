class_name Player
extends CharacterBody2D

const SPEED = 300.0
const JUMP_STRENGTH = 900.0
const GRAVIY_MULTIPLIER = 1.8
const ROT_TWEEN = 0.2
const PUSH_FORCE = 10.0 # Applied to the orb
const PLANK_FORCE = Vector2(0.2, 0.6) # Applied to the plank
const COYOTE_TIME_MS = 100
const CAMERA_HORIZONTAL_OFFSET = 1.2

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

const ANIMS_BY_STATE = {
	State.idle: "idle",
	State.walk: "walk",
	State.jump: "jump",
	State.fall: "fall",
}

const BLEND_TIME_BY_STATE = {
	State.idle: 0.4,
	State.walk: 0.1,
	State.jump: 0.1,
	State.fall: 0.4,
}

enum State { idle, walk, jump, fall, ragdolling }


@export var holding_hand: Node2D
@export var resting_point: Node2D
@export var ragdoll := false : set=set_ragdoll

var state: State = State.idle
var last_floor_touch: int
var is_holding_prop: Node2D = null
var active_grab_box: GrabBox = null
var start_pos: Vector2

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Node2D = $Sprite
@onready var shape: CollisionShape2D = $NormalCollision
@onready var ground_detector: RayCast2D = $GroundDetector


func _ready() -> void:
	anim_player.play("idle")
	start_pos = position
	set_ragdoll.call_deferred(ragdoll)


func reset_after_fall() -> void:
	position = start_pos


func set_ragdoll(val: bool) -> void:
	if not anim_player:
		return
	ragdoll = val
	if ragdoll:
		state = State.ragdolling
		$Sprite/Ragdoll/FootL.global_position = $Sprite/GuidePoints/LegL.global_position
		$Sprite/Ragdoll/FootR.global_position = $Sprite/GuidePoints/LegR.global_position
		$Sprite/Ragdoll/HandL.global_position = $Sprite/GuidePoints/ArmL.global_position
		$Sprite/Ragdoll/HandR.global_position = $Sprite/GuidePoints/ArmR.global_position
		$Sprite/Ragdoll/Torso.global_position = $Sprite/GuidePoints/Torso.global_position
		$Sprite/Ragdoll/Torso.global_rotation = 0
	else:
		state = State.idle
		rotation = 0
	
	anim_player.active = not ragdoll
	shape.disabled = ragdoll
	for n in get_tree().get_nodes_in_group("ragdoll"):
		if n is CollisionShape2D:
			n.disabled = not ragdoll
		if n is RigidBody2D:
			n.freeze = not ragdoll
		if n is RemoteTransform2D:
			n.update_position = ragdoll
			n.update_rotation = ragdoll

func _in_coyote_window() -> bool:
	return not is_on_floor() and last_floor_touch + COYOTE_TIME_MS > Time.get_ticks_msec()


func _can_jump() -> bool:
	return is_on_floor() or _in_coyote_window()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		set_ragdoll(not ragdoll)
	if event.is_action_pressed("jump") and _can_jump():
		velocity += up_direction * JUMP_STRENGTH
		state = State.jump
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("interact") and is_holding_prop:
		put_down_prop()
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if state == State.ragdolling:
		var torso = $Sprite/Ragdoll/Torso
		var marker = $Sprite/GuidePoints/Torso
		var diff = torso.global_position - marker.global_position
		var rdiff = torso.global_rotation - global_rotation
		global_position += diff
		for n in get_tree().get_nodes_in_group("ragdoll"):
			if n is RigidBody2D:
				n.global_position -= diff
		global_rotation += rdiff
		torso.global_rotation -= rdiff

	
func _process(delta: float) -> void:
	if state == State.ragdolling:
		return
	var dir = Input.get_vector("left", "right", "up", "down")
	var cam = get_viewport().get_camera_2d()
	velocity.x = dir.x * SPEED

	if dir.x < 0 and sprite.scale.x > 0:
		sprite.scale.x = -1.0
		if cam:
			cam.drag_horizontal_offset = -CAMERA_HORIZONTAL_OFFSET
	elif dir.x > 0 and sprite.scale.x < 0:
		sprite.scale.x = 1.0
		if cam:
			cam.drag_horizontal_offset = CAMERA_HORIZONTAL_OFFSET

	if is_on_floor() and state != State.jump:
		last_floor_touch = Time.get_ticks_msec()
		if velocity.x != 0:
			state = State.walk
		else:
			state = State.idle
	elif state == State.jump or state == State.fall or not _in_coyote_window():
		velocity.y -= up_direction.y * gravity * GRAVIY_MULTIPLIER * delta
		if velocity.y < 0:
			state = State.jump
		else:
			state = State.fall

	if anim_player.current_animation != ANIMS_BY_STATE[state]:
		anim_player.play(ANIMS_BY_STATE[state], BLEND_TIME_BY_STATE[state])

	var v := velocity
	if move_and_slide():
		# TODO: this is ugly. replace it with a more flexible system
		# I tried a bunch of things here and they were all glitch and less fun than the original 
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			var obj = col.get_collider()
			if obj is Orb:
				obj.apply_force(col.get_normal() * -PUSH_FORCE)
				#if ground_detector.get_collider() != obj and sign(col.get_normal().x) != sign(v.x):
					#var force := col.get_normal().abs() * v * PUSH_FORCE * delta
					#print("force:", [force, col.get_normal().x, v.x])
					#obj.apply_force(force, col.get_position() - obj.global_position)
					#obj.apply_force(force)
			if obj is Plank:
				if v.y > 1.0:
					var force := col.get_normal().abs() * v * PLANK_FORCE
					#print("force:", [force, col.get_normal().x, v.x])
					obj.apply_impulse(force, col.get_position() - obj.global_position)
	
	if is_holding_prop:
		_update_prop(delta)
	elif velocity != Vector2.ZERO:
		GrabBoxManager.update_active_candidate()


# TODO: trigger a pickup animation?
func pick_up_prop(target_node: Node2D, grab_box: GrabBox) -> bool:
	if ground_detector.is_colliding() and ground_detector.get_collider() == target_node:
		return false
	print("picking up: ", target_node)
	if is_holding_prop:
		return false
	is_holding_prop = target_node
	active_grab_box = grab_box
	return true


func put_down_prop() -> void:
	if is_holding_prop:
		is_holding_prop.rotation = 0.0 if sprite.scale.x > 0 else PI
		active_grab_box.put_down.emit(self)
		is_holding_prop = null
		active_grab_box = null


func _update_prop(_delta: float) -> void:
	var prop: Node2D = is_holding_prop
	prop.rotation = holding_hand.global_position.angle_to_point(resting_point.global_position) #+ PI / 2
	prop.global_position = holding_hand.global_position # lerp(holding_hand.global_position, resting_point.global_position, 0.5)
