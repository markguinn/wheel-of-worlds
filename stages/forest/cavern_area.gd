extends Area2D


@export var light_color := Color("#2a3426")
@export var tween_time := 0.5

var original_light_color: Color
var light_tween: Tween

@onready var canvas_modulate: CanvasModulate = %CanvasModulate


func _ready() -> void:
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exit)
	original_light_color = canvas_modulate.color


func _on_body_enter(_node: Node2D) -> void:
	if light_tween and light_tween.is_running():
		light_tween.stop()
	light_tween = create_tween()
	light_tween.tween_property(canvas_modulate, "color", light_color, tween_time)


func _on_body_exit(_node: Node2D) -> void:
	if light_tween and light_tween.is_running():
		light_tween.stop()
	light_tween = create_tween()
	light_tween.tween_property(canvas_modulate, "color", original_light_color, tween_time)
