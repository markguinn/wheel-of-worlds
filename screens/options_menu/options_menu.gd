extends CanvasLayer

@onready var return_button := %ReturnButton
@onready var music_slider := %MusicVolumeSlider
@onready var sfx_slider := %SfxVolumeSlider
@onready var screen_shake_slider := %ScreenShakeVolumeSlider
@onready var uisfx: UISFX = $UISFX

var prev_focus: Control

func _ready()->void:
	visible = false
	visibility_changed.connect(_on_visibility_changed)
	music_slider.value = AudioManager.get_music_balance() * 100.0
	sfx_slider.value = AudioManager.get_sfx_balance() * 100.0
	screen_shake_slider.value = VFX.get_shake_volume() * 100.0


func _on_visibility_changed() -> void:
	if visible:
		prev_focus = get_viewport().gui_get_focus_owner()
		return_button.grab_focus()
		uisfx.play_menu_open()
	else:
		prev_focus.grab_focus()
		uisfx.play_menu_close()
	for n in get_tree().get_nodes_in_group("hidden_for_options"):
		n.visible = !self.visible


func _on_screen_shake_volume_slider_value_changed(value: float) -> void:
	if visible:
		VFX.set_shake_volume(value / 100.0)


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	if visible:
		AudioManager.set_sfx_balance(value / 100.0)


func _on_music_volume_slider_value_changed(value: float) -> void:
	if visible:
		AudioManager.set_music_balance(value / 100.0)


func _on_return_button_pressed() -> void:
	visible = false
