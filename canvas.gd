extends TextureRect
class_name Canvas

@export_node_path("Player") var player_path
@onready var player : Player = get_node(player_path)

@export_node_path("Maze") var maze_path
@onready var maze : Maze = get_node(maze_path)

var rd : RenderingDevice
var shader : RID
var pipeline : RID
var output_data_texture : RID
var uniforms : Array[RDUniform]

var data_texture : ImageTexture
var canvas_size : Vector2i
var output_data_size : Vector2i


func _ready():
	_init_shader_parameters()
	_init_compute()
	_on_resized()
	
	player.connect("physics_changed", _calculate_frame)
	_calculate_frame()


func _init_shader_parameters():
	material.set_shader_parameter("far_plane", player.far_plane)


func _init_compute():
	rd = RenderingServer.create_local_rendering_device()
	uniforms = [RDUniform.new(), RDUniform.new(), RDUniform.new(), RDUniform.new()]
	
	# init shader and pipeline
	var spirv := preload("res://raycasting.glsl").get_spirv()
	shader = rd.shader_create_from_spirv(spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	# create data uniforms that don't change
	_build_tilemap_uniform()
	_build_warps_uniform()


func _on_resized():
	if rd == null:
		return
	
	canvas_size = get_viewport_rect().size
	var image := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF)
	texture = ImageTexture.create_from_image(image)
	
	output_data_size = Vector2i(canvas_size.x, 2)
	_build_output_data_texture_uniform()
	
	_calculate_frame()


func _build_output_data_texture_uniform():
	var fmt := RDTextureFormat.new()
	fmt.width = output_data_size.x
	fmt.height = output_data_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	var image := Image.create(output_data_size.x, output_data_size.y, false, Image.FORMAT_RGBAF)
	data_texture = ImageTexture.create_from_image(image)
	material.set_shader_parameter("data_texture", data_texture)
	
	output_data_texture = rd.texture_create(fmt, RDTextureView.new(), [image.get_data()])
	
	var output_data_uniform := RDUniform.new()
	output_data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_data_uniform.binding = 0
	output_data_uniform.add_id(output_data_texture)
	
	uniforms[0] = output_data_uniform


func _build_camera_data_uniform():
	var origin := player.get_physical_origin()
	
	var data : PackedByteArray = PackedFloat32Array([
		origin.x, origin.y,
		player.rotation,
		player.far_plane,
		player.fov,
	]).to_byte_array()

	_build_storage_buffer_uniform(data, 1)


func _build_tilemap_uniform():
	var data : PackedByteArray = []
	
	data.append_array(_rect2i_to_byte_array(maze.get_used_rect()))
	
	for tile in maze.build_tiles_array():
		data.append_array(_tile_to_byte_array(tile))
		
	_build_storage_buffer_uniform(data, 2)


func _build_warps_uniform():
	var data : PackedByteArray = []
	
	for warp in maze.build_warps_array():
		data.append_array(_warp_to_byte_array(warp))
	
	_build_storage_buffer_uniform(data, 3)


func _build_storage_buffer_uniform(bytes : PackedByteArray, binding : int):
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = binding
	uniform.add_id(rd.storage_buffer_create(bytes.size(), bytes))
	
	uniforms[binding] = uniform


func _rect2i_to_byte_array(rect : Rect2i) -> PackedByteArray:
	return PackedInt32Array([rect.position.x, rect.position.y, rect.end.x, rect.end.y]).to_byte_array()


func _tile_to_byte_array(tile : Maze.Tile) -> PackedByteArray:
	return PackedInt32Array([
		tile.texture_index, tile.warp_index, tile.num_warps, 0
	]).to_byte_array()


func _warp_to_byte_array(warp : Warp) -> PackedByteArray:
	return PackedFloat32Array([
		warp.dir.x, warp.dir.y, warp.offset.x, warp.offset.y, 0.0, 0.0, 0.0, warp.angle
	]).to_byte_array()


func _calculate_frame():
	# rebuild data uniforms that change every frame
	_build_camera_data_uniform()
	material.set_shader_parameter("origin", player.virtual_pos)
	material.set_shader_parameter("view_dir", player.get_virtual_view_dir())
	
	# start recording compute commands
	var compute_list := rd.compute_list_begin()
	
	# bind pipeline to tell GPU which shader to use
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	
	# bind uniform set that contains our data bindings
	var uniform_set := rd.uniform_set_create(uniforms, shader, 0)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	
	# dispatch work groups so there are enough threads for every column
	@warning_ignore("integer_division")
	rd.compute_list_dispatch(compute_list, canvas_size.x / 64, 1, 1)
	
	# end compute commands
	rd.compute_list_end()
	
	# submit commands to the GPU
	rd.submit()
	
	# wait for the GPU to finish
	rd.sync()
	
	# update data texture for shader
	var data : PackedByteArray = rd.texture_get_data(output_data_texture, 0)
	data_texture.update(Image.create_from_data(output_data_size.x, output_data_size.y, false, Image.FORMAT_RGBAF, data))


# DebugOptions group
func _on_normal_mapping_toggled(val : bool):
	material.set_shader_parameter("use_normal_mapping", val)


# DebugOptions group
func _on_parallax_mapping_toggled(val : bool):
	material.set_shader_parameter("use_parallax_mapping", val)


# DebugOptions group
func _on_far_plane_value_changed(val : float):
	material.set_shader_parameter("far_plane", val)
