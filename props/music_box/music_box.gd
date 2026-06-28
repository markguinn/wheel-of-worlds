extends Node2D


@onready var sprite: Sprite2D = $Sprite2D
@onready var dialog: AcceptDialog = $CanvasLayer/AcceptDialog


func _ready() -> void:
	dialog.hide()


func _on_accept_dialog_confirmed() -> void:
	queue_free()
	get_tree().paused = false


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player and not body.has_music_box:
		body.has_music_box = true
		body.anim_player.play("pickup")
		await body.anim_player.animation_finished
		# TODO: use the crouch animation? change to a grab box?
		sprite.hide()
		dialog.show()
		get_tree().paused = true
