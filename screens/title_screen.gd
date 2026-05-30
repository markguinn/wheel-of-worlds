extends CanvasLayer

@onready var options_menu: CanvasLayer = $OptionsMenu


func _ready() -> void:
	options_menu.hide()
	GameManager.is_in_game = false
	AudioManager.set_music("wheel")


func _on_quit_game_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	options_menu.show()
