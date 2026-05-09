class_name PlayerPushState
extends PlayerState

# baseline scaling value for push force
const PUSH_STRENGTH = 1.0
# when pushing up a slope, how much extra force to add
# 0.0 = no extra force, 1.0 = roughly double the baseline
const VERTICAL_OOMPH_SCALE = 1.0
# the y component of the push direction is scaled by this value
# before actually applying it to the orb. Closer to 1.0 will give
# more lift on slopes. Too far will cause it to pop up off the ground
const VERTICAL_PUSH_DIRECTION_SCALE = 0.4
# if the orb gets stuck on a slope, we give it a little extra thump
# thie controls how hard that is
const AUTO_KICK_STRENGTH = 1.2
# how often should we thump the orb if it's stuck
const AUTO_KICK_DEBOUNCE_MS = 200
# if you press the jump button while pushing you kick the orb even harder
# this controls how hard
const KICK_STRENGTH = 3.0

# this is a point out in front of the player, from
# which we just the distance to the orb and the
# angle of pushing
@onready var push_point: Marker2D = %GuidePoints/PushPoint

var orb: Orb = null
var last_kick := 0

func can_enter(from_state: StateNode) -> bool:
	if not orb:
		return false
	return super.can_enter(from_state)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and orb:
		get_viewport().set_input_as_handled()
		orb.apply_central_impulse(_get_input_vector() * KICK_STRENGTH)
	

func _entered(_from_state: StateNode) -> void:
	if not orb:
		machine.transition_by_name("Idle")
		return
	player.anim_player.play("pushing")
	last_kick = GameManager.now_ms()


func _before_exit(_to_state: StateNode) -> void:
	orb.apply_impulse(Vector2.RIGHT if orb.position.x > player.position.x else Vector2.LEFT)
	orb = null


func start_pushing_orb(_orb: Orb, handle_txn = true) -> void:
	if not _orb or is_zero_approx(_get_input_vector().x) or machine.active_state == self:
		return
	Log.debug(player, "pushing orb", _orb.name)
	orb = _orb
	if handle_txn:
		machine.transition.call_deferred(self)


# the default implementation has some acceleration but that makes it
# look really jerky when you're bumping against the orb all the time
# so we just even out the velocity (this is called by super._process)
func _update_horizontal_movement(dir: Vector2, _delta: float) -> void:
	player.velocity.x = dir.x * horizontal_speed * player.speed_multiplier


func _process(delta: float) -> void:
	var dir := _get_input_vector()
	var orb_dir = push_point.global_position.direction_to(orb.global_position)
	var orb_dist = pow(absf(push_point.global_position.x - orb.global_position.x), 2.0)
	#Log.debounced(player, "dist", orb_dist, "dir", orb_dir, "xdiff", orb.pos_history.get_position_diff().x, "tdist", orb.pos_history.distance_traveled)
	
	if is_zero_approx(dir.x):
		machine.transition_by_name.call_deferred("Idle")
		return
	if signf(dir.x) != signf(orb.global_position.x - player.global_position.x):
		Log.debug(player, 'turned around')
		machine.transition_by_name.call_deferred("Walk")
		return
	if orb_dist > horizontal_speed:
		Log.debug(player, 'too far')
		machine.transition_by_name.call_deferred("Walk")
		return
		
	# we never want to push down on the orb
	if orb_dir.y > 0.0:
		orb_dir.y = 0.0
	
	# when pushing up a hill, we need to push harder
	var extra_oomph: float = 1.0 + -orb_dir.y * VERTICAL_OOMPH_SCALE
	# we want to scale down the direction slightly so we don't end up
	# popping the orb up off the ground on steeper slopes
	orb_dir.y *= VERTICAL_PUSH_DIRECTION_SCALE
	
	orb.apply_force(orb_dir.normalized() * extra_oomph * PUSH_STRENGTH)

	# if the orb stops moving or moves backwards for more than 0.2 seconds (as determined by the PositionHistoryBuffer on the orb)
	# we give it a little extra impulse on top of the constant force we applied above
	if (
		orb and 
		orb.pos_history.get_position_diff().x * signf(dir.x) <= 0.05 and 
		GameManager.now_ms() > last_kick + AUTO_KICK_DEBOUNCE_MS
	):
		Log.debug(player, "auto-kicking stuck orb")
		last_kick = GameManager.now_ms()
		orb.apply_central_impulse(orb_dir * AUTO_KICK_STRENGTH)
		#orb.apply_central_impulse(_get_input_vector() * AUTO_KICK_STRENGTH)

	super._process(delta)
	
