class_name CavernArea
extends Area2D


@export var light_color := Color("#2a3426")
@export var tween_time := 0.5
@export var room_size := 1.0

var original_light_color: Color
static var light_tween: Tween
var is_active := false

static var total_active := 0

@onready var canvas_modulate: CanvasModulate = %CanvasModulate


func _ready() -> void:
	body_entered.connect(_on_body_enter)
	body_exited.connect(_on_body_exit)
	if not canvas_modulate:
		push_warning("Level doesn't have CanvasModulate node")
		canvas_modulate = CanvasModulate.new()
		add_sibling.call_deferred(canvas_modulate)
	original_light_color = canvas_modulate.color
	#collision_layer = 0
	#collision_mask = 0
	set_collision_mask_value(2, true)


func _on_body_enter(body: Node2D) -> void:
	Log.debug(self, "enter", body, total_active)
	if not body is Player and not body is PlayerRagdollBody:
		return
	is_active = true
	total_active += 1
	if light_tween and light_tween.is_running():
		Log.debug(self, "stopping previous tween")
		light_tween.stop()
	light_tween = create_tween()
	light_tween.tween_property(canvas_modulate, "color", light_color, tween_time)
	light_tween.parallel().tween_method(AudioManager.set_room_size, AudioManager.get_room_size(), room_size, tween_time)
	light_tween.parallel().tween_method(AudioManager.set_music_damping, AudioManager.get_music_damping(), 1.0, tween_time)


func _on_body_exit(body: Node2D) -> void:
	Log.debug(self, "exit", body, total_active)
	if not body is Player and not body is PlayerRagdollBody:
		return
	is_active = false
	if total_active > 0:
		total_active -= 1
	if total_active > 0:
		return
	if light_tween and light_tween.is_running():
		Log.debug(self, "stopping previous tween")
		light_tween.stop()
	light_tween = create_tween()
	light_tween.tween_property(canvas_modulate, "color", original_light_color, tween_time)
	light_tween.parallel().tween_method(AudioManager.set_room_size, AudioManager.get_room_size(), 0.0, tween_time)
	light_tween.parallel().tween_method(AudioManager.set_music_damping, AudioManager.get_music_damping(), 0.0, tween_time)


func _on_area_exited(area: Area2D) -> void:
	if area.get_parent() is ShadowBlob: area.get_parent().byebye()
