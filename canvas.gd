extends TextureRect
class_name Canvas

@export_node_path(Player) var player_path
@onready var player : Player = get_node(player_path)

@export_node_path(Maze) var maze_path
@onready var maze : Maze = get_node(maze_path)

@export var use_stretch := false

var rd : RenderingDevice
var shader : RID
var pipeline : RID
var canvas_texture : RID
var output_data_texture : RID
var uniforms : Array[RDUniform]

var canvas_size : Vector2i
var output_data_size : Vector2i


func _ready():
	_init_shader()
	_init_compute()
	_recreate_texture()
	
	
func _recreate_texture():
	canvas_size = get_viewport_rect().size
	output_data_size = Vector2i(canvas_size.x, 3)
	
	var image := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF)
	texture = ImageTexture.create_from_image(image)
	
	# rebuild canvas texture uniform since its size has changed
	_build_canvas_texture_uniform(image)
	_build_output_data_texture_uniform(Image.create(output_data_size.x, output_data_size.y, false, Image.FORMAT_RGBAF))


func _process(_delta : float):
	# rebuild data uniforms that change every frame
	_build_camera_data_uniform()
	material.set_shader_parameter("view_pos", player.position)
	
	_render_frame()
	

func _init_shader():
	material.set_shader_parameter("ceiling_colour", maze.ceiling_colour)
	material.set_shader_parameter("floor_colour", maze.floor_colour)
	
	material.set_shader_parameter("atlas_dimensions", maze.atlas_dim)
	#material.set_shader_parameter("tilemap_atlas", maze.tilemap_atlas)
	#material.set_shader_parameter("tilemap_normal_map", maze.tilemap_normal_map)


func _init_compute():
	rd = RenderingServer.create_local_rendering_device()
	uniforms = [RDUniform.new(), RDUniform.new(), RDUniform.new(), RDUniform.new(), RDUniform.new(), RDUniform.new(), RDUniform.new()]
	
	# init shader and pipeline
	var spirv := preload("res://raycasting.glsl").get_spirv()
	shader = rd.shader_create_from_spirv(spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	# create data uniforms that don't change
	_build_tilemap_uniform()
	_build_sampler_texture_uniform(maze.tilemap_atlas, 3)
	_build_sampler_texture_uniform(maze.tilemap_normal_map, 4)
	_build_light_data_uniform()


func _build_canvas_texture_uniform(image : Image):
	var fmt := RDTextureFormat.new()
	fmt.width = canvas_size.x
	fmt.height = canvas_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	canvas_texture = rd.texture_create(fmt, RDTextureView.new(), [image.get_data()])
	
	var canvas_uniform := RDUniform.new()
	canvas_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	canvas_uniform.binding = 0
	canvas_uniform.add_id(canvas_texture)
	
	uniforms[0] = canvas_uniform
	

func _build_output_data_texture_uniform(image : Image):
	var fmt := RDTextureFormat.new()
	fmt.width = output_data_size.x
	fmt.height = output_data_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	
	output_data_texture = rd.texture_create(fmt, RDTextureView.new(), [image.get_data()])
	
	var output_data_uniform := RDUniform.new()
	output_data_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_data_uniform.binding = 6
	output_data_uniform.add_id(output_data_texture)
	
	uniforms[6] = output_data_uniform


func _build_camera_data_uniform():
	var data : PackedByteArray = PackedFloat32Array([
		player.position.x, player.position.y,
		player.rotation,
		player.fov,
		player.far_plane,
	]).to_byte_array()

	_build_storage_buffer_uniform(data, 1)


func _build_tilemap_uniform():
	var data : PackedByteArray = []
	
	data.append_array(_colour_to_byte_array(maze.ceiling_colour))
	data.append_array(_colour_to_byte_array(maze.floor_colour))
	
	data.append_array(_rect2i_to_byte_array(maze.get_used_rect()))
	data.append_array(PackedInt32Array([
		maze.atlas_dim.x, maze.atlas_dim.y,
		maze.cell_size,
		0,
	]).to_byte_array())
	
	for tile in maze.get_tiles():
		data.append_array(_tile_to_byte_array(tile))
		
	_build_storage_buffer_uniform(data, 2)
	

func _build_light_data_uniform():
	var data : PackedByteArray = []
	
	data.append_array(_colour_to_byte_array(maze.ambient_colour))
	data.append_array(PackedFloat32Array([
		maze.light_att.x, maze.light_att.y, maze.light_att.z,
	]).to_byte_array())
	data.append_array(PackedInt32Array([
		maze.get_light_count(),
	]).to_byte_array())
	
	for light in maze.get_lights():
		data.append_array(_light_to_byte_array(light))
	
	_build_storage_buffer_uniform(data, 5)


func _build_storage_buffer_uniform(bytes : PackedByteArray, binding : int):
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = binding
	uniform.add_id(rd.storage_buffer_create(bytes.size(), bytes))
	
	uniforms[binding] = uniform
	

func _build_sampler_texture_uniform(tex : Texture2D, binding : int):
	var image := tex.get_image()
	image.convert(Image.FORMAT_RGBA8) # RGBA required for sampler texture
	
	var image_size := image.get_size()
	
	var fmt := RDTextureFormat.new()
	fmt.width = image_size.x;
	fmt.height = image_size.y;
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_SAMPLING_BIT
	fmt.format = RenderingDevice.DATA_FORMAT_R8G8B8A8_SRGB
	
	var sampler = rd.sampler_create(RDSamplerState.new())
	var atlas_texture = rd.texture_create(fmt, RDTextureView.new(), [image.get_data()])

	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_SAMPLER_WITH_TEXTURE
	uniform.binding = binding
	uniform.add_id(sampler)
	uniform.add_id(atlas_texture)
	
	uniforms[binding] = uniform
	

func _colour_to_byte_array(c : Color) -> PackedByteArray:
	return PackedFloat32Array([c.r, c.g, c.b, c.a]).to_byte_array()
	

func _rect2i_to_byte_array(rect : Rect2i) -> PackedByteArray:
	return PackedInt32Array([rect.position.x, rect.position.y, rect.end.x, rect.end.y]).to_byte_array()


func _tile_to_byte_array(tile : Maze.Tile) -> PackedByteArray:
	return PackedInt32Array([tile.atlas_coords.x, tile.atlas_coords.y]).to_byte_array()
	

func _light_to_byte_array(light : MazeLight) -> PackedByteArray:
	var data : PackedByteArray = []
	
	data.append_array(_colour_to_byte_array(light.color))
	data.append_array(PackedFloat32Array([
		light.position.x, light.position.y,
		light.z_offset,
		0.0,
	]).to_byte_array())
	
	return data


func _render_frame():	
	# start recording compute commands
	var compute_list := rd.compute_list_begin()
	
	# bind pipeline to tell GPU which shader to use
	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	
	# bind uniform set that contains our data bindings
	var uniform_set := rd.uniform_set_create(uniforms, shader, 0)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)
	
	# dispatch work groups so there are enough threads for every column
	@warning_ignore(integer_division)
	rd.compute_list_dispatch(compute_list, canvas_size.x / 64, 1, 1)
	
	# end compute commands
	rd.compute_list_end()
	
	# submit commands to the GPU
	rd.submit()
	
	# wait for the GPU to finish
	rd.sync()
	
	# get data from the output texture and update image
	#var data : PackedByteArray = rd.texture_get_data(canvas_texture, 0)
	#var image = Image.create_from_data(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF, data)
	#texture.update(image)
	
	var data : PackedByteArray = rd.texture_get_data(output_data_texture, 0)
	var image = Image.create_from_data(output_data_size.x, output_data_size.y, false, Image.FORMAT_RGBAF, data)
	material.set_shader_parameter("data_texture", ImageTexture.create_from_image(image))


func _on_resized():
	if rd == null or use_stretch:
		return
	
	_recreate_texture() # TODO: resolve bottle neck for large images


func _on_normal_mapping_toggled(button_pressed : bool):
	material.set_shader_parameter("use_normal_mapping", button_pressed)


func _on_parallax_mapping_toggled(button_pressed : bool):
	material.set_shader_parameter("use_parallax_mapping", button_pressed)
