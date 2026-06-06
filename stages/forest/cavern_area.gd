class_name CavernArea
extends Area2D


@export var light_color := Color("#2a3426")
@export var tween_time := 0.5
@export var room_size := 2.0

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
	light_tween.parallel().tween_method(AudioManager.set_room_size, 0.0, room_size, tween_time)
	light_tween.parallel().tween_method(AudioManager.set_music_damping, 0.0, 1.0, tween_time)


func _on_body_exit(_node: Node2D) -> void:
	if light_tween and light_tween.is_running():
		light_tween.stop()
	light_tween = create_tween()
	light_tween.tween_property(canvas_modulate, "color", original_light_color, tween_time)
	light_tween.parallel().tween_method(AudioManager.set_room_size, room_size, 0.0, tween_time)
	light_tween.parallel().tween_method(AudioManager.set_music_damping, 1.0, 0.0, tween_time)


func _on_area_exited(area: Area2D) -> void:
	if area.get_parent() is ShadowBlob: area.get_parent().byebye()
