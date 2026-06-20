extends Node2D


@onready var sprite: Sprite2D = $Sprite2D
@onready var dialog: AcceptDialog = $CanvasLayer/AcceptDialog


func _ready() -> void:
	dialog.hide()


func _on_accept_dialog_confirmed() -> void:
	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.has_music_box = true
		# TODO: use the crouch animation? change to a grab box?
		sprite.hide()
		#dialog.popup_exclusive_centered(self)
		dialog.show()
