class_name Portal
extends Node2D

signal activation_complete

const ORB_WAIT_MS = 1000
const FOLLOW_ORB_LEN = 256.0
const EYE_MOVEMENT_RADIUS = 50.0
## How long after entering the level before the orb will activate the portal
const WAIT_TIME_AFTER_INIT_MS = 5000
const LIGHT_CHANGE_MS = 150
const SFX_TWEEN_SECONDS = 1.0

## This is how other portals reference this one
@export var portal_name: String
@export var is_active := true
## When the player enters, they go to this stage
@export_file("*.tscn") var linked_stage: String
## If not blank, the player will go to the portal with this name instead of the usual starting point of the level
@export var target_portal: String
## If not blank, this string will be displayed when the portal can be activated instead of "Press X to enter..."
@export var activator_text: String
## used in the ending cutscene
@export var stare_and_blink := false

var player_is_present := false
var orb_is_present := false
var orb_entered_at := 0
var orbs: Array[Orb] = []
var iris_start_pos: Vector2
var anim_state_machine: AnimationNodeStateMachinePlayback

var init_time_ms: int
var light_changed_ms: int

@onready var activator: Activator = $Activator
@onready var orb_detector: Area2D = $OrbDetector
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var sparkles: Node2D = $Sprites/Sparkles
@onready var eye_bg: Node2D = $Sprites/EyeBackground
@onready var iris: Sprite2D = $Sprites/BlackIris
@onready var light: PointLight2D = $PointLight2D
@onready var opening_sound: AudioStreamPlayer2D = $OpeningSound


func _ready() -> void:
	anim_tree.active = true
	anim_state_machine = anim_tree["parameters/playback"]
	activator.activated.connect(_on_activated)
	activator.enabled = false
	if activator_text:
		activator.label_text = activator_text
		activator.label.text = activator_text
	orb_detector.body_entered.connect(_on_body_entered)
	orb_detector.body_exited.connect(_on_body_exited)
	iris_start_pos = iris.position
	init_time_ms = GameManager.now_ms()

	for n in get_children():
		if n is Orb:
			orb_is_present = true
			orb_entered_at = 1
			orbs.append(n)


func _on_body_entered(body: Node2D) -> void:
	if GameManager.now_ms() < init_time_ms + WAIT_TIME_AFTER_INIT_MS:
		return
	Log.debug(self, 'orb entered', body)
	if not orb_is_present:
		start_sound.call_deferred()
	orb_is_present = true
	orb_entered_at = GameManager.now_ms()
	orbs.append(body)
	


func _on_body_exited(body: Node2D) -> void:
	Log.debug(self, 'orb exited', body)
	orbs.erase(body)
	if orbs.is_empty():
		orb_is_present = false
		orb_entered_at = 0
		stop_sound.call_deferred()


func _process(_delta: float) -> void:
	if not is_active:
		orb_detector.gravity_space_override = Area2D.SPACE_OVERRIDE_DISABLED
		return

	if is_active and orb_entered_at > 0 and GameManager.now_ms() > orb_entered_at + ORB_WAIT_MS:
		if not activator.enabled:
			Log.debug(self, 'enabling activator')
			activator.enabled = true
			Activator.update_active_candidate()
	else:
		if activator.enabled:
			Log.debug(self, 'disabling activator')
			activator.enabled = false
			Activator.update_active_candidate()

	if GameManager.now_ms() > light_changed_ms + LIGHT_CHANGE_MS:
		light_changed_ms = GameManager.now_ms()
		light.energy = randf_range(0.8, 1.2)
		light.texture_scale = randf_range(4.5, 5.5)

	if orbs.size() > 0:
		var orb_pos := to_local(orbs[0].global_position)
		var orb_dir := orb_pos.normalized()
		var orb_dist := clampf(orb_pos.length(), 0.0, FOLLOW_ORB_LEN)
		var eye_dist := EYE_MOVEMENT_RADIUS * orb_dist / FOLLOW_ORB_LEN
		iris.position = iris_start_pos - iris.offset + orb_dir * eye_dist


var lpf_tween: Tween
func start_sound() -> void:
	if lpf_tween and lpf_tween.is_running():
		lpf_tween.stop()
	var lpf := AudioManager.get_portal_lpf()
	lpf_tween = create_tween()
	lpf_tween.set_ease(Tween.EASE_IN_OUT)
	lpf_tween.set_trans(Tween.TRANS_SINE)
	lpf_tween.tween_property(lpf, "cutoff_hz", 22000.0, SFX_TWEEN_SECONDS)
	lpf_tween.parallel().tween_property(opening_sound, "volume_linear", 1.0, SFX_TWEEN_SECONDS)
	opening_sound.play()


func stop_sound() -> void:
	if lpf_tween and lpf_tween.is_running():
		lpf_tween.stop()
	var lpf := AudioManager.get_portal_lpf()
	lpf_tween = create_tween()
	lpf_tween.set_ease(Tween.EASE_IN_OUT)
	lpf_tween.set_trans(Tween.TRANS_SINE)
	lpf_tween.tween_property(lpf, "cutoff_hz", 20.0, SFX_TWEEN_SECONDS)
	lpf_tween.parallel().tween_property(opening_sound, "volume_linear", 0.0, SFX_TWEEN_SECONDS)
	await lpf_tween.finished
	opening_sound.stop()

func _on_activated(_source: Activator) -> void:
	Log.info(self, 'portal activated', self.name)
	anim_state_machine.travel("activated")
	await anim_tree.animation_finished
	activation_complete.emit()
	if linked_stage:
		GameManager.change_scene.call_deferred(linked_stage, {"target_portal": target_portal})


func take_player_and_orb() -> void:
	var p := GameManager.get_player()
	p.reparent(eye_bg)
	p.z_index = 0
	VFX.shake(VFX.SHORT, VFX.TREMOR)


func drop_orb() -> void:
	VFX.shake(VFX.MID, VFX.FREAK_OUT)
	VFX.flash(VFX.SHORT, VFX.QUAKE, VFX.Flash.LIGHT)
