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

@onready var target: Area2D = $TargetArea
@onready var label: Label = $Label


func _ready() -> void:
	target.body_entered.connect(_on_body_entered)
	target.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body is Orb:
		orb_is_present = true
		orb_entered_at = Time.get_ticks_msec()
	if body is Player:
		player_is_present = true


func _on_body_exited(body: Node2D) -> void:
	if body is Orb:
		orb_is_present = false
		orb_entered_at = 0
	if body is Player:
		player_is_present = false


func _can_enter() -> bool:
	return player_is_present and orb_entered_at > 0 and Time.get_ticks_msec() > orb_entered_at + ORB_WAIT_MS


func _process(_delta: float) -> void:
	if _can_enter():
		label.show()
	else:
		label.hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _can_enter():
		get_viewport().set_input_as_handled()
		GameManager.change_scene.call_deferred(linked_stage, true, target_portal)
