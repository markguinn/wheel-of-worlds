extends Node2D


@onready var activator: Activator = $Activator
@onready var sprite: Sprite2D = $Sprite2D
@onready var dialog: AcceptDialog = $CanvasLayer/AcceptDialog


func _ready() -> void:
	dialog.hide()


func _on_activator_activated(_source: Activator) -> void:
	var player: Player = GameManager.get_player()
	player.has_music_box = true
	# TODO: use the crouch animation? change to a grab box?
	sprite.hide()
	#dialog.popup_exclusive_centered(self)
	dialog.show()
	Activator.clear_candidates()
	activator.enabled = false


func _on_accept_dialog_confirmed() -> void:
	queue_free()
