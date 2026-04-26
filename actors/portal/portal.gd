class_name Portal
extends Node2D


const ORB_WAIT_MS = 1000


@export var portal_name: String
@export var is_active := true
@export_file("*.tscn") var linked_stage: String
@export var target_portal: String

var player_is_present := false
var orb_is_present := false
var orb_entered_at := 0
var orbs: Array[Orb] = []
var anim_state_machine: AnimationNodeStateMachinePlayback

@onready var activator: Activator = $Activator
@onready var orb_detector: Area2D = $OrbDetector
@onready var anim_tree: AnimationTree = $AnimationTree
@onready var sparkles: Node2D = $Sprites/Sparkles
@onready var eye_bg: Node2D = $Sprites/EyeBackground

func _ready() -> void:
	anim_tree.active = true
	anim_state_machine = anim_tree["parameters/playback"]
	activator.activated.connect(_on_activated)
	activator.enabled = false
	orb_detector.body_entered.connect(_on_body_entered)
	orb_detector.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	Log.debug(self, 'orb entered', body)
	orb_is_present = true
	orb_entered_at = GameManager.now_ms()
	orbs.append(body)


func _on_body_exited(body: Node2D) -> void:
	Log.debug(self, 'orb exited', body)
	orbs.erase(body)
	if orbs.is_empty():
		orb_is_present = false
		orb_entered_at = 0


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


func _on_activated(_source: Activator) -> void:
	Log.info(self, 'portal activated', self.name)
	anim_state_machine.travel("activated")
	await anim_tree.animation_finished
	GameManager.change_scene.call_deferred(linked_stage, {"target_portal": target_portal})


func take_player_and_orb() -> void:
	var p := GameManager.get_player()
	p.reparent(eye_bg)
	p.z_index = 0
	#for o in orbs:
		#o.reparent(eye_bg)
