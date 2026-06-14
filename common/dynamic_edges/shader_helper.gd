@tool
extends CanvasGroup

func _process(_delta: float) -> void:
	var vpr := get_viewport_rect().size / get_viewport_transform().get_scale()
	var shader_material: ShaderMaterial = material
	shader_material.set_shader_parameter("real_screen_size", vpr)
