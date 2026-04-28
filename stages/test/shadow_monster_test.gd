extends Stage

#	_FORCE_INLINE_ real_t tdotx(const Vector2 &p_v) const { return columns[0][0] * p_v.x + columns[1][0] * p_v.y; }
static func tdotx(mat, vec):
	return mat.get_scale().x * vec.x  # Let's pretend for now that there is no rotation.. '^^
	
#	_FORCE_INLINE_ real_t tdoty(const Vector2 &p_v) const { return columns[0][1] * p_v.x + columns[1][1] * p_v.y; }
static func tdoty(mat, vec):
	return mat.get_scale().y * vec.y

static func xform(mat, vec) -> Vector2:
	return Vector2(tdotx(mat, vec), tdoty(mat, vec)) + mat.get_origin()

const shadow_blob_template: PackedScene = preload( "res://actors/shadow_monster/shadow_blob.tscn")
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		var global_mouse_pos = xform(get_viewport().get_canvas_transform().affine_inverse(), get_viewport().get_mouse_position())
		var blob: ShadowBlob = shadow_blob_template.instantiate()
		#blob.debug_image = true
		blob.target = $Player
		blob.global_position = global_mouse_pos
		add_child(blob)
