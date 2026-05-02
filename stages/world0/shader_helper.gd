@tool
extends CanvasGroup

func _process(delta: float) -> void:
	var vpr := get_viewport_rect().size / get_viewport_transform().get_scale()
	var shader_material: ShaderMaterial = material
	shader_material.set_shader_parameter("real_screen_size", vpr)
	#if Time.get_ticks_msec() % 1000 < 10:
		#prints(
			#Time.get_ticks_msec(),
			#Engine.is_editor_hint(),
			#vpr
		#)
	
