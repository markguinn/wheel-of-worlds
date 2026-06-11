@tool
extends TileMapLayer

const BASE_PATH = "res://generated"

@export var target_layer: TileMapLayer
@export var tile_size := Vector2(128, 128)
@export var edge_color: Color = Color.WHITE
@export var textures: Array[EdgeTexture] = []
@export var bake_region: Rect2 = Rect2(0, 0, 25600, 12800)
# TODO: can we use a global something? resource name or guid?
@export var slug := "change_me"
@export_tool_button("Bake Edges") var bake_edges_fn := _bake_edges


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
	
	var working_size := tile_size
	var subviewport = SubViewport.new()
	subviewport.transparent_bg = true
	subviewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	subviewport.size = working_size * 3
	var clone = self.duplicate()
	subviewport.add_child(clone)
	add_sibling(subviewport)
	
	var start_pos := bake_region.position - bake_region.size / 2.0
	var tiles: Dictionary[String, Image] = {}
	var tile_idx: Dictionary[String, int] = {}
	var tile_atlas_coords: Dictionary[String, Vector2i] = {}
	var target_writes = []
	
	var idx := 0
	prints("starting bake")
	for y in range(start_pos.y, start_pos.y + bake_region.size.y, working_size.y):
		for x in range(start_pos.x, start_pos.x + bake_region.size.x, working_size.x):
			var img := await _capture_tile(clone, subviewport, Vector2(x, y), working_size)
			var sha := _get_hash(img)
			if sha not in tiles:
				tiles[sha] = img
				tile_idx[sha] = idx
				idx += 1
			target_writes.append([x, y, sha])

	var atlas_width := ceili(sqrt(tiles.size()))
	var atlas_size := Vector2(
		float(atlas_width) * working_size.x,
		float(atlas_width) * working_size.y,
	)
	prints("constructing atlas from", tiles.size(), "tiles")
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
			float(i % atlas_width) * working_size.x,
			float(i / atlas_width) * working_size.y,
		)
		var rect = Rect2i(0, 0, img.get_width(), img.get_height())
		prints("writing", sha, i, rect, tile_pos)
		atlas_img.blit_rect(img, rect, tile_pos)
	
	var atlas_fn = _get_atlas_path()
	atlas_img.save_png(atlas_fn)
	var atlas_tex = ResourceLoader.load(atlas_fn, "", ResourceLoader.CACHE_MODE_REPLACE_DEEP)
	src.texture = atlas_tex
	src.texture_region_size = working_size
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


func _capture_tile(
	source: Node2D,
	subviewport: SubViewport,
	pos: Vector2,
	tile_size: Vector2
) -> Image:
	var crop_region := Rect2(tile_size, tile_size)
	source.position = -pos + tile_size
	prints("rendering", pos)
	RenderingServer.force_draw()
	await RenderingServer.frame_post_draw
	var tex: Texture2D = subviewport.get_texture()
	return tex.get_image().get_region(crop_region)
