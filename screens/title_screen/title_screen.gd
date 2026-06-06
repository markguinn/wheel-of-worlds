extends CanvasLayer

@onready var options_menu: CanvasLayer = $OptionsMenu
@onready var options_bg: Node = $OptionsBackground
@onready var options_btn: Button = %Options
@onready var start_btn: Button = %StartGame
@onready var quit_btn: Button = %QuitGame
@onready var wheel: Node2D = $WheelTiles
@onready var wheel_sfx: AudioStreamPlayer = $WheelTurn

var rotate_tween: Tween


func _ready() -> void:
	options_menu.visibility_changed.connect(_on_options_menu_vis)
	options_menu.hide()
	options_bg.hide()
	GameManager.is_in_game = false
	AudioManager.set_music("wheel")


func _on_quit_game_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	options_menu.show()


func _on_options_menu_vis() -> void:
	options_bg.visible = options_menu.visible
	

func _on_start_game_focus_entered() -> void:
	_rotate_wheel(0.0)


func _on_options_focus_entered() -> void:
	_rotate_wheel(-90.0)


func _on_quit_game_focus_entered() -> void:
	_rotate_wheel(90.0)


func _rotate_wheel(deg: float) -> void:
	if rotate_tween and rotate_tween.is_running():
		rotate_tween.stop()
	if wheel:
		wheel_sfx.play()
		rotate_tween = create_tween()
		rotate_tween.set_ease(Tween.EASE_IN_OUT)
		rotate_tween.set_trans(Tween.TRANS_BOUNCE)
		rotate_tween.tween_property(wheel, "rotation_degrees", deg, 0.4)
