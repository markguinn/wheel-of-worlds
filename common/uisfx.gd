class_name UISFX
extends Node

func play_menu_open() -> void:
	$MenuOpen.play()
	
func play_menu_close() -> void:
	$MenuClose.play()

func play_press() -> void:
	$Press.play()

func play_focus() -> void:
	$Focus.play()
