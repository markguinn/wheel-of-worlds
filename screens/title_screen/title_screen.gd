extends CanvasLayer

@onready var options_menu: CanvasLayer = $OptionsMenu
@onready var options_bg: Node = $OptionsBackground
@onready var options_btn: Button = %Options
@onready var start_btn: Button = %StartGame
@onready var quit_btn: Button = %QuitGame
@onready var wheel: Node2D = $RotatingBody
@onready var wheel_sfx: AudioStreamPlayer = $WheelTurn

var rotate_tween: Tween


func _ready() -> void:
	options_menu.visibility_changed.connect(_on_options_menu_vis)
	options_menu.hide()
	options_bg.hide()
	GameManager.is_in_game = false
	GameManager.hide_hud(true)
	AudioManager.reset_music()


func _on_quit_game_pressed() -> void:
	get_tree().quit()


func _on_options_pressed() -> void:
	options_menu.show()


func _on_options_menu_vis() -> void:
	options_bg.visible = options_menu.visible
	

func _on_wheel_button_focus_entered(btn) -> void:
	_rotate_wheel(-btn.rotation_degrees)


func _rotate_wheel(deg: float) -> void:
	if rotate_tween and rotate_tween.is_running():
		rotate_tween.stop()
	if wheel:
		wheel_sfx.play()
		rotate_tween = create_tween()
		rotate_tween.set_ease(Tween.EASE_IN_OUT)
		rotate_tween.set_trans(Tween.TRANS_BOUNCE)
		while absf(wheel.rotation_degrees - deg) > 180.0:
			if deg > wheel.rotation_degrees:
				deg -= 360.0
			else:
				deg += 360.0
		Log.debug(self, "rotating wheel", wheel.rotation_degrees, deg)
		rotate_tween.tween_property(wheel, "rotation_degrees", deg, 0.4)


func _on_start_game_pressed() -> void:
	GameManager.start_new_game()


func _on_continue_pressed() -> void:
	GameManager.resume_previous_scene()
