shader_type canvas_item;

uniform sampler2D data_texture : filter_nearest;

uniform vec2 view_pos;
uniform float depth_scale = 0.1;

uniform vec4 ceiling_colour : source_color;
uniform vec4 floor_colour : source_color;

uniform ivec2 atlas_dimensions;
uniform sampler2D tilemap_atlas : filter_nearest;
uniform sampler2D tilemap_normal_map;
uniform sampler2D tilemap_parallax_map;

uniform vec3 light_dir = vec3(0.0, 0.0, 1.0);
uniform vec4 light_colour : source_color = vec4(vec3(0.6), 1.0);

const vec3 TANGENT = vec3(0.0, 0.0, 1.0);

//===================

float lerp(float from, float to, float weight) {
    return from + (to - from) * weight;
}

vec2 lerp_vec2(vec2 from, vec2 to, vec2 weight) {
    return vec2(lerp(from.x, to.x, weight.x), lerp(from.y, to.y, weight.y));
}

mat2 rotation(float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(vec2(c, -s), vec2(s, c));
}

//===================

vec2 apply_parallax(vec2 uv, vec3 view_dir) {
	float depth = texture(tilemap_parallax_map, uv).r;
	return uv - view_dir.xy / view_dir.z * depth;// * depth_scale;
}

vec3 sample_normal_vector(mat3 tbn, vec2 uv) {
    return normalize(tbn * (2.0 * texture(tilemap_normal_map, uv).rgb - 1.0));
}

vec4 draw_ceiling() {
	return ceiling_colour;
}

vec4 draw_floor() {
	return floor_colour;
}

vec4 draw_wall(vec2 uv, vec2 atlas_coords, vec2 position, vec3 normal) {
	vec2 offset = 1.0 / vec2(atlas_dimensions);
	uv = lerp_vec2(offset * atlas_coords, offset * (atlas_coords + vec2(1.0)), uv);
	
	mat3 tbn = mat3(TANGENT, cross(normal, TANGENT), normal);
	vec3 view_dir = normalize(tbn * vec3(view_pos, 0.5) - tbn * vec3(position, uv.y));
	uv = apply_parallax(uv, view_dir);
	
	vec4 colour = vec4(vec3(0.0), 1.0);
	
	vec3 dir = normalize(vec3(normal.xy, 1.0));
	colour += texture(tilemap_atlas, uv) * light_colour * max(dot(dir, sample_normal_vector(tbn, uv)), 0);

	return colour;
}

vec4 calc_colour(vec2 uv) {
	vec4 data = texture(data_texture, vec2(uv.x, 0.0));
	float wall_offset = data.r;
	
	if (wall_offset >= 1.0) {
		if (uv.y < 0.5) {
			return draw_ceiling();
		}
		else {
			return draw_floor();
		}
	}
	
	float v = (uv.y - wall_offset / 2.0) / (1.0 - wall_offset);
	
	if (v < 0.0) {
		return draw_ceiling();
	}
	
	if (v > 1.0) {
		return draw_floor();
	}
	
	vec2 position = texture(data_texture, vec2(uv.x, 0.5)).rg;
	vec3 normal = texture(data_texture, vec2(uv.x, 1.0)).rgb;
	
	return draw_wall(vec2(data.g, v), data.ba, position, normal);
}

void fragment() {
	COLOR = calc_colour(UV);
}
