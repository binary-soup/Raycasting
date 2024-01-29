shader_type canvas_item;

uniform sampler2D data_texture : filter_nearest;

uniform vec2 view_pos;
uniform float pitch;
uniform float depth_scale = 0.1;

uniform float far_plane;
uniform sampler2D fog_gradient;
uniform vec4 fog_colour : source_color;

uniform vec4 ceiling_colour : source_color;
uniform vec4 floor_colour : source_color;

uniform sampler2DArray diffuse_textures;
uniform sampler2D normal_map;
uniform sampler2D depth_map;

uniform vec4 light_colour : source_color = vec4(vec3(0.6), 1.0);

uniform bool use_normal_mapping = true;
uniform bool use_parallax_mapping = true;

const vec3 BITANGENT = vec3(0.0, 0.0, 1.0);

struct Wall {
	float dist;
	float texture_index;
	vec2 uv;
	vec2 position;
	vec3 normal;
};

//===================

vec2 apply_parallax(vec2 uv, vec3 view_dir) {
	float depth = texture(depth_map, uv).r;
	return uv - view_dir.xy / view_dir.z * depth * depth_scale;
}

vec3 sample_normal_vector(vec2 uv) {
	return 2.0 * texture(normal_map, uv).rgb - 1.0;
}

vec4 sample_fog(float dist) {
	return fog_colour * texture(fog_gradient, vec2(dist / far_plane, 0.0));
}

vec4 draw_ceiling(vec2 uv) {
	float dist = (0.5 / (0.5 - tan(pitch) - uv.y));
	return ceiling_colour + sample_fog(dist);
}

vec4 draw_floor(vec2 uv) {
	float dist = (0.5 / (uv.y - 0.5 + tan(pitch)));
	return floor_colour + sample_fog(dist);
}

vec4 draw_wall(Wall wall) {
	vec2 uv = wall.uv;
	vec3 normal = wall.normal;
	mat3 tbn = mat3(cross(wall.normal, BITANGENT), BITANGENT, normal);
	
	if (use_parallax_mapping) {
		vec3 view_dir = normalize((vec3(view_pos, 0.5) - vec3(wall.position, uv.y))) * tbn;
		uv = apply_parallax(uv, view_dir);
	}
	
	vec4 colour = texture(diffuse_textures, vec3(uv, wall.texture_index));
	vec3 light_dir = normalize(vec3(wall.normal.xy, -1.0)) * tbn;
	
	if (use_normal_mapping) {
		normal = sample_normal_vector(uv);
	}
	else {
		normal = vec3(0.0, 0.0, -1.0) * tbn;
	}
	
	colour *= light_colour * max(dot(light_dir, normal), 0);
	return colour + sample_fog(wall.dist);
}

vec4 calc_colour(vec2 uv) {
	vec4 data = texture(data_texture, vec2(uv.x, 0.0));
	
	Wall wall;
	wall.dist = data.r;
	
	float offset = 0.5 + wall.dist * tan(pitch);
	float v = wall.dist * uv.y - wall.dist * 0.5 + offset;
	
	if (v < 0.0) {
		return draw_ceiling(uv);
	}
	
	if (v > 1.0) {
		return draw_floor(uv);
	}
	
	if (wall.dist >= far_plane) {
		return fog_colour;
	}
	
	wall.uv = vec2(data.g, v);
	wall.texture_index = data.b;
	wall.position = texture(data_texture, vec2(uv.x, 0.5)).rg;
	wall.normal = texture(data_texture, vec2(uv.x, 1.0)).rgb;
	
	return draw_wall(wall);
}

void fragment() {
	COLOR = calc_colour(UV);
}
