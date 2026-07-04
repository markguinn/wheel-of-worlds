extends Node2D

@export var height := 500.0
@export var seconds_to_raise := 1.0

@onready var platform: StaticBody2D = $Platform
@onready var activator: Activator = $Platform/Activator
@onready var activator2: Activator = $Base/Activator2

var tween: Tween = null
var raised := false


func _ready() -> void:
	activator.activated.connect(_on_activated)
	activator2.activated.connect(_on_activated)
	activator2.enabled = false
	_update_activators.call_deferred()


func _on_activated(_source: Activator) -> void:
	toggle_raised.call_deferred()


func toggle_raised() -> void:
	if tween:
		return
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	activator.enabled = false
	activator2.enabled = false
	Activator.update_active_candidate()
	if raised:
		tween.tween_property(platform, "position", Vector2.ZERO, seconds_to_raise)
	else:
		tween.tween_property(platform, "position", Vector2(0.0, -height), seconds_to_raise)
	raised = not raised
	await tween.finished
	tween = null
	_update_activators()


func _update_activators() -> void:
	activator.enabled = true
	activator2.enabled = raised
	var txt := "Press DOWN/S to lower..." if raised else "Press UP/W to raise..."
	activator.label.text = txt
	activator2.label.text = txt
	Activator.update_active_candidate()


func _input(event: InputEvent) -> void:
	var a: Activator
	if activator.enabled and activator in Activator.candidates:
		a = activator
	elif activator2.enabled and activator2 in Activator.candidates:
		a = activator2
	else:
		return
	if raised and event.is_action_pressed("down"):
		a.activated.emit.call_deferred(a)
		get_viewport().set_input_as_handled()
	if not raised and event.is_action_pressed("up"):
		a.activated.emit.call_deferred(a)
		get_viewport().set_input_as_handled()
