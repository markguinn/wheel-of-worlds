extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.has_method("reset_after_fall"):
		body.reset_after_fall.call_deferred()
	else:
		body.queue_free()
