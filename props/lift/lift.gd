extends Node2D

@export var height := 500.0
@export var seconds_to_raise := 1.0

@onready var platform: StaticBody2D = $Platform
@onready var activator: Activator = $Platform/Activator

var tween: Tween = null
var raised := false


func _ready() -> void:
	activator.activated.connect(_on_activated)


func _on_activated(_source: Activator) -> void:
	toggle_raised.call_deferred()


func toggle_raised() -> void:
	if not tween:
		tween = create_tween()
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.set_trans(Tween.TRANS_QUAD)
		if raised:
			tween.tween_property(platform, "position", Vector2.ZERO, seconds_to_raise)
		else:
			tween.tween_property(platform, "position", Vector2(0.0, -height), seconds_to_raise)
		raised = not raised
		await tween.finished
		tween = null
