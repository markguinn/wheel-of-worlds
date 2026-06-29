extends Node2D


@onready var sprite: Sprite2D = $Sprite2D
@onready var dialog: AcceptDialog = $CanvasLayer/AcceptDialog
@export var label: Label

func _ready() -> void:
	dialog.hide()
	if label:
		label.modulate = Color.TRANSPARENT


func _on_accept_dialog_confirmed() -> void:
	queue_free()
	get_tree().paused = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and not body.has_music_box:
		_get_the_box.call_deferred(body)

func _get_the_box(body: Node2D) -> void:
	Log.info(self, "picking up the box")
	body.has_music_box = true
	body.anim_player.play("pickup")
	await get_tree().create_timer(0.3).timeout
	sprite.hide()
	if label:
		_show_label()
	else:
		dialog.show()
		get_tree().paused = true


func _show_label() -> Tween:
	var t = label.create_tween()
	t.tween_property(label, "modulate", Color.WHITE, 0.5)
	return t
	

func _hide_label() -> void:
	var t = label.create_tween()
	t.tween_property(label, "modulate", Color.TRANSPARENT, 0.5)
	await t.finished
	queue_free()
	label.queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_released("music_box") and label and label.modulate.a == 1.0:
		_hide_label()
