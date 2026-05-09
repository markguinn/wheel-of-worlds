extends CanvasLayer

@onready var return_button := %ReturnButton
@onready var music_slider := %MusicVolumeSlider
@onready var sfx_slider := %SfxVolumeSlider
@onready var screen_shake_slider := %ScreenShakeVolumeSlider
var music_bus := AudioServer.get_bus_index("Music")
var sfx_bus := AudioServer.get_bus_index("SFX")

func _ready()->void:
	visible = false
	music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_bus))
	sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_bus))
	


func _on_screen_shake_volume_slider_value_changed(_value: float) -> void:
	pass # Replace with function body.


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(sfx_bus,linear_to_db(value))


func _on_music_volume_slider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(music_bus,linear_to_db(value))


func _on_return_button_pressed() -> void:
	visible = false
