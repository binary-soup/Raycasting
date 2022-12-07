extends TextureRect
class_name Canvas

@export_node_path(Player) var player_path
@onready var player : Player = get_node(player_path)

@export_node_path(Maze) var maze_path
@onready var maze : Maze = get_node(maze_path)

@export var tilemap_atlas : Texture2D

var rd : RenderingDevice
var shader : RID
var pipeline : RID
var canvas_texture : RID
var uniforms : Array[RDUniform]

var canvas_size : Vector2i


func _ready():
	_init_compute()
	_recreate_texture()
	
	
func _recreate_texture():
	canvas_size = get_viewport_rect().size
	
	var image := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF)
	texture = ImageTexture.create_from_image(image)
	
	# rebuild canvas texture uniform since its size has changed
	_build_canvas_texture_uniform(image)


func _process(_delta : float):
	# rebuild data uniforms that change every frame
	_build_camera_data_uniform()
	
	_render_frame()
	

func _init_compute():
	rd = RenderingServer.create_local_rendering_device()
	uniforms = [null, null, null, null]
	
	# init shader and pipeline
	var spirv := preload("res://raycasting.glsl").get_spirv()
	shader = rd.shader_create_from_spirv(spirv)
	pipeline = rd.compute_pipeline_create(shader)
	
	# create data uniforms that don't change
	_build_tilemap_uniform()
	_build_tilemap_atlas_uniform()


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


func _build_tilemap_atlas_uniform():
	var image := tilemap_atlas.get_image()
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
	uniform.binding = 3 
	uniform.add_id(sampler)
	uniform.add_id(atlas_texture)
	
	uniforms[3] = uniform


func _build_storage_buffer_uniform(bytes : PackedByteArray, binding : int):
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = binding
	uniform.add_id(rd.storage_buffer_create(bytes.size(), bytes))
	
	uniforms[binding] = uniform
	

func _colour_to_byte_array(c : Color) -> PackedByteArray:
	return PackedFloat32Array([c.r, c.g, c.b, c.a]).to_byte_array()
	

func _rect2i_to_byte_array(rect : Rect2i) -> PackedByteArray:
	return PackedInt32Array([rect.position.x, rect.position.y, rect.end.x, rect.end.y]).to_byte_array()


func _tile_to_byte_array(tile : Maze.Tile) -> PackedByteArray:
	return PackedInt32Array([tile.atlas_coords.x, tile.atlas_coords.y]).to_byte_array()


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
	var data : PackedByteArray = rd.texture_get_data(canvas_texture, 0)
	var image = Image.create_from_data(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBAF, data)
	texture.update(image)


func _on_resized():
	if rd == null:
		return
	
	#_recreate_texture() # TODO: resolve bottle neck for large images
