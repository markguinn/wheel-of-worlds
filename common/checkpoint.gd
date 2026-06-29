class_name CheckPoint
extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_enter)


func _on_body_enter(body: Node2D) -> void:
	if body.has_method("set_checkpoint"):
		body.set_checkpoint()
		Log.info(self, "checkpoint set for", body.name, "at", get_path())
