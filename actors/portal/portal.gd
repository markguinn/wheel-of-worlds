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

@onready var activator: Activator = $Activator
@onready var orb_detector: Area2D = $OrbDetector


func _ready() -> void:
	activator.activated.connect(_on_activated)
	activator.enabled = false
	orb_detector.body_entered.connect(_on_body_entered)
	orb_detector.body_exited.connect(_on_body_exited)


func _on_body_entered(_body: Node2D) -> void:
	Log.debug(self, 'orb entered')
	orb_is_present = true
	orb_entered_at = GameManager.now_ms()


func _on_body_exited(_body: Node2D) -> void:
	Log.debug(self, 'orb exited')
	orb_is_present = false
	orb_entered_at = 0


func _process(_delta: float) -> void:
	if orb_entered_at > 0 and GameManager.now_ms() > orb_entered_at + ORB_WAIT_MS:
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
	GameManager.change_scene.call_deferred(linked_stage, {"target_portal": target_portal})
