extends CanvasLayer

@onready var return_button := %ReturnButton
@onready var music_slider := %MusicVolumeSlider
@onready var sfx_slider := %SfxVolumeSlider
@onready var screen_shake_slider := %ScreenShakeVolumeSlider

func _ready()->void:
	visible = false
	visibility_changed.connect(_on_visibility_changed)
	# TODO: persist these values instead
	AudioManager.set_sfx_balance(sfx_slider.value / 100.0)
	AudioManager.set_music_balance(music_slider.value / 100.0)
	VFX.set_shake_volume(screen_shake_slider.value / 100.0)


func _on_visibility_changed() -> void:
	if visible:
		return_button.grab_focus()

func _on_screen_shake_volume_slider_value_changed(value: float) -> void:
	VFX.set_shake_volume(value / 100.0)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_balance(value / 100.0)


func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioManager.set_music_balance(value / 100.0)


func _on_return_button_pressed() -> void:
	visible = false
