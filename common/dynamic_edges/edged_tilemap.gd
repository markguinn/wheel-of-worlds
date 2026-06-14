@tool
extends CanvasGroup

const BASE_PATH = "res://generated"

@export var target_layer: TileMapLayer
@export var tile_size := Vector2(128, 128)
@export var replace_color: Color = Color.WHITE
@export var textures: Array[EdgeTexture] = []
@export var bake_region: Rect2 = Rect2(0, 0, 25600, 12800)
# TODO: can we use a global something? resource name or guid?
@export var slug := "change_me"
@export_tool_button("Bake Edges") var bake_edges_fn := _bake_edges

var _cancel := false

var baking := false
var original_shader_bg: Color
var shader_material: ShaderMaterial
var original_scale: Vector2

var popup_scene = preload("res://common/dynamic_edges/baking_progress_dialog.tscn")
var popup: BakingProgressDialog

func _ready() -> void:
	shader_material = material
	original_shader_bg = shader_material.get_shader_parameter("base_color")
	shader_material.set_shader_parameter("fill_enabled", true)
	shader_material.set_shader_parameter("edge_enabled", Engine.is_editor_hint())
	target_layer.visible = !Engine.is_editor_hint()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint() and not baking:
		var vpr := get_viewport_rect().size / get_viewport_transform().get_scale()
		shader_material.set_shader_parameter("real_screen_size", vpr)


func _cancel_bake() -> void:
	_cleanup_bake()
	_cancel = true
	

func _cleanup_bake() -> void:
	shader_material.set_shader_parameter("fill_enabled", true)
	shader_material.set_shader_parameter("edge_enabled", true)
	shader_material.set_shader_parameter("base_color", original_shader_bg)
	baking = false
	get_parent().scale = original_scale
	var vpr := get_viewport_rect().size / get_viewport_transform().get_scale()
	shader_material.set_shader_parameter("real_screen_size", vpr)
	popup.hide()
	popup.queue_free()



func _bake_edges() -> void:
	if not target_layer:
		push_error("You must set a target layer!")
	if not target_layer.tile_set:
		target_layer.tile_set = TileSet.new()
		target_layer.tile_set.tile_size = tile_size
	while target_layer.tile_set.get_source_count() > 0:
		target_layer.tile_set.remove_source(target_layer.tile_set.get_source_id(0))
	var src := TileSetAtlasSource.new()
	target_layer.tile_set.add_source(src)
	
	var atlas_fn = _get_atlas_path()
	DirAccess.remove_absolute(atlas_fn)
	DirAccess.remove_absolute(atlas_fn + ".import")
	baking = true
	
	var subviewport = SubViewport.new()
	subviewport.transparent_bg = true
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subviewport.size = tile_size * 3
	subviewport.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
	var clone = self.duplicate()
	subviewport.add_child(clone)
	add_sibling(subviewport)
	
	original_scale = get_parent().scale
	get_parent().scale = Vector2.ONE
	target_layer.scale = Vector2.ONE
	self.scale = Vector2.ONE
	
	popup = popup_scene.instantiate()
	if Engine.is_editor_hint():
		var editor = Engine.get_singleton("EditorInterface")	
		editor.popup_dialog(popup)
	var popup_label:Label = popup.get_node("MarginContainer/VBoxContainer/Label")
	var popup_bar:ProgressBar = popup.get_node("MarginContainer/VBoxContainer/ProgressBar")
	var btn = popup.get_node("MarginContainer/VBoxContainer/Cancel")
	btn.pressed.connect(_cancel_bake)
	
	var start_pos: Vector2 = snapped(bake_region.position - bake_region.size / 2.0, tile_size)
	var tiles: Dictionary[String, Image] = {}
	var tile_idx: Dictionary[String, int] = {}
	var tile_atlas_coords: Dictionary[String, Vector2i] = {}
	var target_writes = []

	var cur_col: Color = shader_material.get_shader_parameter("base_color")
	if cur_col.a > 0.0:
		original_shader_bg = cur_col
	shader_material.set_shader_parameter("fill_enabled", false)
	shader_material.set_shader_parameter("edge_enabled", true)
	shader_material.set_shader_parameter("base_color", Color.TRANSPARENT)
	shader_material.set_shader_parameter("real_screen_size", Vector2(subviewport.size))

	_cancel = false
	var idx := 0
	for y in range(start_pos.y, start_pos.y + bake_region.size.y, tile_size.y):
		for x in range(start_pos.x, start_pos.x + bake_region.size.x, tile_size.x):
			if _cancel:
				clone.queue_free()
				subviewport.queue_free()
				return
			var img := await _capture_tile(clone, subviewport, Vector2(x, y))
			var sha := _get_hash(img)
			if sha not in tiles:
				tiles[sha] = img
				tile_idx[sha] = idx
				idx += 1
			target_writes.append([x, y, sha])
		popup_bar.value = 100.0 * (y - start_pos.y) / bake_region.size.y
		prints("baking", 100.0 * (y - start_pos.y) / bake_region.size.y)

	var atlas_width := ceili(sqrt(tiles.size()))
	var atlas_size := Vector2(
		float(atlas_width) * tile_size.x,
		float(atlas_width) * tile_size.y,
	)
	prints("constructing atlas from", tiles.size(), "tiles")
	popup_label.text = "Building tileset..."
	var atlas_img: Image = Image.create(
		int(atlas_size.x), 
		int(atlas_size.y), 
		false, 
		Image.FORMAT_RGBA8
	)
	for sha in tiles:
		var i := tile_idx[sha]
		var img := tiles[sha]
		@warning_ignore("integer_division")
		var tile_pos := Vector2(
			float(i % atlas_width) * tile_size.x,
			float(i / atlas_width) * tile_size.y,
		)
		var rect = Rect2i(0, 0, img.get_width(), img.get_height())
		prints("writing", sha, i, rect, tile_pos)
		atlas_img.blit_rect(img, rect, tile_pos)
	
	atlas_img.save_png(atlas_fn)
	
	popup_label.text = "Waiting for re-import..."
	popup_bar.value = 99.0
	while not FileAccess.file_exists(atlas_fn + ".import"):
		RenderingServer.force_draw()
		await RenderingServer.frame_post_draw
		if _cancel:
			return
	var atlas_tex = ResourceLoader.load(atlas_fn, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)
	popup_label.text = "Finishing..."
	src.texture = atlas_tex
	src.texture_region_size = tile_size
	prints(
		"tex", 
		src.texture.get_size(), 
		src.get_atlas_grid_size(), 
		src.get_tiles_count(), 
		#src.get_tiles
	)
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw

	for sha in tiles:
		var i := tile_idx[sha]
		@warning_ignore("integer_division")
		var tile_pos := Vector2i(i % atlas_width, i / atlas_width)
		prints("creating tile", i, tile_pos)
		src.create_tile(tile_pos, Vector2i.ONE)
		tile_atlas_coords[sha] = tile_pos # TODO: write this above
	
	for w in target_writes:
		var map_coords := target_layer.local_to_map(Vector2(w[0], w[1]))
		var atlas_coords := tile_atlas_coords[w[2]]
		prints("writing atlas coords", atlas_coords, "to map at", map_coords)
		target_layer.set_cell(map_coords, target_layer.tile_set.get_source_id(0), atlas_coords)

	# free up
	_cleanup_bake()
	clone.queue_free()
	subviewport.queue_free()


func _get_folder() -> String:
	var path = BASE_PATH + "/" + slug
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
	return path


func _clear_folder() -> void:
	for file in DirAccess.get_files_at(_get_folder()):
		DirAccess.remove_absolute(file)


func _get_img_path(fn: String) -> String:
	return _get_folder() + "/" + fn + ".png"


func _get_atlas_path() -> String:
	return BASE_PATH + "/" + slug + "_atlas.png"


func _get_hash(img: Image) -> String:
	var ctx: HashingContext = HashingContext.new()
	ctx.start(HashingContext.HASH_SHA1)
	ctx.update(img.get_data())
	return ctx.finish().hex_encode()


func _capture_tile(source: Node2D, subviewport: SubViewport, pos: Vector2) -> Image:
	var crop_region := Rect2(tile_size, tile_size)
	source.position = -pos + tile_size
	#prints("rendering", pos)
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var img = subviewport.get_texture().get_image()
	#await _apply_edges(img)
	return img.get_region(crop_region)


# TODO: experiment with blending vs a single source
# TODO: probably some dp/caching stuff. is it necessary? probably not?
# TODO: can we show a progress bar?
func _apply_edges(img: Image) -> void:
	var ray_cache: Dictionary[String, float] = {}
	for y in range(tile_size.y, tile_size.y * 2):
		for x in range(tile_size.x, tile_size.x * 2):
			if not img.get_pixel(x, y).is_equal_approx(replace_color):
				continue
			var min_dist := 1000.0
			var color := Color.TRANSPARENT
			var pos := Vector2(x, y)
			for deg in range(0.0, 360.0, 90.0):
				var dist = _cast_ray(img, pos, Vector2.from_angle(deg_to_rad(deg)), ray_cache)
				#prints("ray", x, y, deg, dist)
				if dist > 0.0 and dist < min_dist:
					min_dist = dist
					var tex = _get_texture_for_dir(deg)
					var tx := 0 # TODO
					if dist < tex.get_height():
						color = tex.get_pixel(tx, floori(dist))
				# keep things slightly responsive
				await RenderingServer.frame_post_draw
			img.set_pixel(x, y, color)
			if _cancel:
				return


func _cast_ray(img: Image, pos: Vector2, dir: Vector2, ray_cache: Dictionary[String, float]) -> float:
	var ck = str(pos) + str(dir) # faster way? floating point err?
	if ck in ray_cache:
		return ray_cache[ck]
	if pos.x < 0 or pos.x >= img.get_width() or pos.y < 0 or pos.y >= img.get_height():
		#prints("cache miss at edge", ck, pos, dir)
		ray_cache[ck] = 1000.0
		return 1000.0
	if is_zero_approx(img.get_pixelv(pos.floor()).a):
		ray_cache[ck] = 0.0
		return 0.0
	ray_cache[ck] = dir.length() + _cast_ray(img, pos + dir, dir, ray_cache)
	#prints("cache miss", ck, pos, dir, ray_cache[ck])
	return ray_cache[ck]


var tex_cache: Dictionary[float, Image] = {}
func _get_texture_for_dir(deg: float) -> Image:
	if deg not in tex_cache:
		for f in [-1.0, 0.0, 1.0]:
			var d = wrapf(deg, 0.0, 360.0) * f
			for t in textures:
				if d >= t.min_angle and d < t.max_angle:
					tex_cache[deg] = t.texture.get_image()
					break
	return tex_cache[deg]
