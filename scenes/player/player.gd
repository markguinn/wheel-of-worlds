class_name Player
extends CharacterBody2D

const SPEED = 300.0
const JUMP_STRENGTH = 900.0
const GRAVITY = 15.0
const ROT_TWEEN = 0.2
const PUSH_FORCE = 10.0
const COYOTE_TIME_MS = 100

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

enum State { idle, walk, jump, fall }

var state: State = State.idle
var last_floor_touch: int

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Node2D = $Sprite
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	anim_player.play("idle")


func _in_coyote_window() -> bool:
	return not is_on_floor() and last_floor_touch + COYOTE_TIME_MS > Time.get_ticks_msec()


func _can_jump() -> bool:
	return is_on_floor() or _in_coyote_window()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and _can_jump():
		velocity += up_direction * JUMP_STRENGTH
		state = State.jump


func _process(_delta: float) -> void:
	var dir = Input.get_vector("left", "right", "up", "down")
	velocity.x = dir.x * SPEED

	if dir.x < 0:
		sprite.scale.x = -1.0
	elif dir.x > 0:
		sprite.scale.x = 1.0

	if is_on_floor() and state != State.jump:
		last_floor_touch = Time.get_ticks_msec()
		if velocity.x != 0:
			state = State.walk
		else:
			state = State.idle
	elif state == State.jump or state == State.fall or not _in_coyote_window():
		velocity.y -= up_direction.y * GRAVITY
		if velocity.y < 0:
			state = State.jump
		else:
			state = State.fall

	if anim_player.current_animation != ANIMS_BY_STATE[state]:
		anim_player.play(ANIMS_BY_STATE[state], BLEND_TIME_BY_STATE[state])

	if move_and_slide():
		for i in range(get_slide_collision_count()):
			var col = get_slide_collision(i)
			if col.get_collider() is GoalArtifact:
				col.get_collider().apply_force(col.get_normal() * -PUSH_FORCE)
