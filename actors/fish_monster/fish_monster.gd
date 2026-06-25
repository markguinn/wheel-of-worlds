class_name FishMonster
extends MoveableRigidBody2D


# moderates the horizontal linear velocity when jumping from the bottom
const JUMP_X_FACTOR = 0.8

# How many points of data the ring buffer contains.
# this only needs to be long enough to hold enough data for the whole
# body length before it wraps around at the slowest velocity we'd see in the
# wild. Longer isn't a problem except for the memory usage.
const BUFFER_POINTS = 4000

# how many seconds each point in the ring buffer represents
# this needs to be at least as low as the delta we get at the slowest
# time scale we need to support with reasonable smoothness and consistent
# bone distances. This is what's I'm seeing for the physics delta at 0.25 scale.
const BUFFER_STEP_S = 0.00416


signal jumping

@export var is_active := true
## Defines the area where the beast can roam. Defaults to the parent node.
@export var territory: Area2D
## How far above or below the territory line should splashes appear?
@export var splash_offset := -20.0
## How far above or below the territory line should the creature target when swimming?
@export var patrol_offset := 20.0
@export var jump_y_min := 1200.0
@export var jump_y_max := 1800.0
@export var jump_x_min := 200.0
@export var jump_x_max := 1000.0
@export var attack_impact := 2.0
@export var ragdoll_player := true
@export var slomo_entry := false


var territory_rect: Rect2

# ring buffer of the position of the first bone
var position_history: Array[Vector2] = []
# element i stores the distance between i and i+1 in position_history
var delta_history: Array[float] = []
# the current index in position_history, represented by each element in the bones array
# so bone_idx[0] is the front of the ring buffer
var bone_idx: Array[int] = [0, 0, 0, 0]
# the length of each bone at rest
var bone_len: Array[float] = []

var splash_idx := 0

@onready var hit_box: Area2D = $HitBox
@onready var splash_particles: CPUParticles2D = $SplashParticles
@onready var swim_particles: CPUParticles2D = $SwimParticles
@onready var sprite: Node2D = $SpriteContainer
@onready var main_shape: CollisionShape2D = $CollisionShape2D
@onready var polygon_l: Polygon2D = $SpriteContainer/PolygonL
@onready var polygon_r: Polygon2D = $SpriteContainer/PolygonR
@onready var bones: Array[Bone2D] = [
	$SpriteContainer/Skeleton2D/Bone2D,
	$SpriteContainer/Skeleton2D/Bone2D/Bone2D,
	$SpriteContainer/Skeleton2D/Bone2D/Bone2D/Bone2D,
	$SpriteContainer/Skeleton2D/Bone2D/Bone2D/Bone2D/Bone2D,
]


func _ready() -> void:
	if not territory:
		territory = get_parent()
	for node in territory.get_children():
		if node is CollisionShape2D:
			territory_rect = node.shape.get_rect()
			territory_rect.position = node.to_global(territory_rect.position)
	if not territory_rect:
		Log.warn(self, self.get_path(), "no territory rect found. This node should be the child of an Area2d")

	hit_box.body_entered.connect(_on_body_entered)
	splash_particles.emitting = false
	swim_particles.emitting = false

	# NOTE: this is a hack for the temporary polygon because setting scale.x=-1 had bad
	# side effects. When we get a real sprite, it will probably be better to create both
	# polygons by hand rather than flipping them but who knows. Maybe this is fine.
	# the second polygon is the same image flipped _vertically_ (weird, I know). It works
	# that way because the bones don't change direction. Creating by hand may not be possible
	# though because of the orientation of the rest position of the underlying bones.
	for p in polygon_r.polygon:
		p.y = 700.0 - p.y
	for p in polygon_r.uv:
		p.y = 700.0 - p.y

	# initialize the length of the buffer once
	for i in range(BUFFER_POINTS):
		position_history.append(global_position)
		delta_history.append(0.0)
	for b in bones:
		bone_len.append(b.get_length() * b.global_scale.x)


func _on_body_entered(body: Node) -> void:
	Log.debug(self, "contact with ", body.name)
	if body is Stone:
		VFX.shake(VFX.SHORT, VFX.QUAKE)
		apply_impulse(-linear_velocity * 2)
	elif body is Player and body.state_machine.get_active() != "Ragdoll":
		VFX.shake(VFX.MID, VFX.QUAKE)
		body.velocity = linear_velocity * attack_impact
		if ragdoll_player:
			body.state_machine.transition_by_name.call_deferred("Ragdoll")
		apply_impulse(-linear_velocity * 1.5)
	elif body is Plank or body is Teleplate:
		body.apply_impulse(linear_velocity * attack_impact * 0.4)
		apply_impulse(-linear_velocity * 1.5)
	elif body is Teleplate:
		body.apply_impulse(linear_velocity * attack_impact)
		apply_impulse(-linear_velocity * 1.5)
	elif body is Orb:
		body.apply_impulse(linear_velocity * attack_impact * 0.005)
		apply_impulse(-linear_velocity * 1.5)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	super._integrate_forces(state)
	
	if global_position.y > territory_rect.position.y + territory_rect.size.y:
		global_position.y = territory_rect.position.y + territory_rect.size.y
		linear_velocity.y = -randf_range(jump_y_min, jump_y_max)
		var player := GameManager.get_player()
		if player:
			var px := player.global_position.x
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
	# if the rotation gets changed when we hit something, everything gets a little funky
	rotation = 0


# if we take a direct distance between the two bone points, we can get glitchy moments on turns
# so we measure the cumulative distance of the actual history between the two, which handles
# turns in a more natural-looking way
func _dist_along_path(i1: int, i2: int) -> float:
	var end := i2 if i2 >= i1 else i2 + BUFFER_POINTS
	var d := 0.0
	for i in range(i1, end):
		#d += delta_history[i % BUFFER_POINTS]
		var p := position_history[i % BUFFER_POINTS]
		var p2 := position_history[(i + 1) % BUFFER_POINTS]
		d += p.distance_to(p2)
	return d


func _physics_process(delta: float) -> void:
	if is_active and freeze:
		freeze = false
		visible = true
	if not is_active:
		freeze = true
		visible = false
		return

	if linear_velocity.x > 0:
		polygon_r.show()
		polygon_l.hide()
	else:
		polygon_r.hide()
		polygon_l.show()

	# fill in the ring buffer and update the bone positions
	# we use the delta here and interpolate between the current position and the last position
	# in order to keep the behavior consistent if the time scale slows
	var delta_idx := ceili(delta / BUFFER_STEP_S)
	var start_pos := position_history[bone_idx[0]]
	var last_pos := start_pos
	var last_idx := bone_idx[0]
	for i in range(delta_idx):
		var idx := (last_idx + 1) % BUFFER_POINTS
		var progress := float(i + 1) / float(delta_idx + 1)
		# store the interpolated point (at 1.0 it will be where the bone is now, at 0.0
		# where it was at the last physics tick)
		position_history[idx] = lerp(start_pos, bones[0].global_position, progress)
		# store the distances between points to make calculations faster below, maybe? idk
		# this may be just overoptimization.
		delta_history[last_idx] = last_pos.distance_to(position_history[idx])
		last_pos = position_history[idx]
		last_idx = idx
		bone_idx[0] = idx

	# Now move through the remaining bones, and find the point in the history arc that's
	# closest in distance to the length of the bone. 
	for i in range(1, bones.size()):
		var idx := bone_idx[i]
		var prev := position_history[bone_idx[i - 1]]
		var cur := position_history[idx]
		var dist := _dist_along_path(idx, bone_idx[i - 1])
		# move this bone to the next point that's about the right distance away
		while idx < BUFFER_POINTS and idx != bone_idx[i - 1] and dist > bone_len[i]:
			idx = (idx + 1) % BUFFER_POINTS
			dist -= cur.distance_to(position_history[idx])
			cur = position_history[idx]
		bone_idx[i] = idx
		bones[i - 1].global_rotation = prev.angle_to_point(cur)
		bones[i].global_position = cur

	var is_out_of_water := last_pos.y < territory_rect.position.y
	var was_out_of_water := start_pos.y < territory_rect.position.y
	if is_out_of_water != was_out_of_water and not swim_particles.emitting:
		if is_out_of_water:
			splash_particles.direction = linear_velocity.normalized()
			if slomo_entry:
				Log.debug(self, "epic entry triggered")
				VFX.slomo()
				VFX.shake(VFX.MID, VFX.FREAK_OUT)
				slomo_entry = false
		else:
			splash_particles.direction = -linear_velocity.normalized()
		splash_particles.global_position = Vector2(last_pos.x, territory_rect.position.y + splash_offset)
		splash_particles.call_deferred("restart")
