shader_type canvas_item;

uniform sampler2D data_texture : filter_nearest;

uniform vec4 ceiling_colour : source_color;
uniform vec4 floor_colour : source_color;

uniform ivec2 atlas_dimensions;
uniform sampler2D tilemap_atlas : filter_nearest;
uniform sampler2D tilemap_normal_map;

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

vec3 sample_normal_vector(vec3 normal, vec2 uv) {
    mat3 tbn = mat3(TANGENT, cross(normal, TANGENT), normal);
    return tbn * (2.0 * texture(tilemap_normal_map, uv).xyz - 1.0);
}

vec4 draw_ceiling() {
	return ceiling_colour;
}

vec4 draw_floor() {
	return floor_colour;
}

vec4 draw_wall(vec2 uv, vec2 atlas_coords, vec3 normal) {
	vec2 offset = 1.0 / vec2(atlas_dimensions);
	uv = lerp_vec2(offset * atlas_coords, offset * (atlas_coords + vec2(1.0)), uv);
	
	vec4 colour = vec4(vec3(0.0), 1.0);
	
	for (int i = 0; i < 4; i++) {
		vec3 dir = vec3(vec2(1.0) * rotation(float(i) * PI / 2.0), 1.0);
		colour += texture(tilemap_atlas, uv) * max(dot(normalize(dir), sample_normal_vector(normal, uv)), 0) * light_colour;
	}

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
	
	return draw_wall(vec2(data.g, v), data.ba, texture(data_texture, vec2(uv.x, 1.0)).rgb);
}

void fragment() {
	COLOR = calc_colour(UV);
}
