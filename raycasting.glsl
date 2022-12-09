#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(rgba32f, binding = 0) uniform image2D canvas;

layout(set = 0, binding = 1, std430) restrict buffer CameraData {
    vec2 origin;
    float rotation;
    float fov;
    float far_plane;
}
camera_data;

struct Tile {
    ivec2 atlas_coords;
};

struct Rect2i {
    ivec2 start;
    ivec2 end;
};

layout(set = 0, binding = 2, std430) restrict buffer Tilemap {
    vec4 ceil_colour;
    vec4 floor_colour;

    Rect2i dim;
    ivec2 atlas_dim;

    int cell_size;
    int pad;

    Tile[] tiles;
}
tilemap;

layout(set = 0, binding = 3) uniform sampler2D tilemap_atlas;

struct PointLight {
    vec4 colour;
    vec2 position;
    float z_offset;
    float pad;
};

layout(set = 0, binding = 4, std430) restrict buffer LightData {
    vec4 ambient;
    vec3 att;
    int num_lights;
    PointLight[] lights;
} light_data;

struct Ray {
    vec2 pos;
    vec2 dir;
};

struct RayHit {
    vec2 point;
    float dist;
    float u;
    vec2 normal;
    ivec2 atlas_coords;
};

struct Rect2 {
    vec2 start;
    vec2 end;
};

const vec2 UP = vec2(0.0, -1.0);
const vec2 DOWN = vec2(0.0, 1.0);
const vec2 LEFT = vec2(-1.0, 0.0);
const vec2 RIGHT = vec2(1.0, 0.0);
const vec2 STEP_OFFSET = vec2(0.01);

//============================

ivec2 canvas_size;
int max_wall_height;

int tilemap_num_cols;
int tilemap_index_offset;

mat2 rotation(float a) {
	float s = sin(a);
	float c = cos(a);
	return mat2(c, -s, s, c);
}

float lerp(float from, float to, float weight) {
    return from + (to - from) * weight;
}

vec2 lerp_vec2(vec2 from, vec2 to, vec2 weight) {
    return vec2(lerp(from.x, to.x, weight.x), lerp(from.y, to.y, weight.y));
}

vec2 floor_vec(vec2 v) {
    return vec2(floor(v.x), floor(v.y));
}

Rect2 new_rect(vec2 start, vec2 size) {
    Rect2 rect;
    rect.start = start;
    rect.end = start + size;
    return rect;
}

//============================

float calc_u(float start, float end, float point) {
    return (point - start) / (end - start);
}

vec2 intersect_horizontal_line(float y, float slope, vec2 pos) {
    float initial = -slope * pos.x + pos.y;
    return vec2((y - initial) / slope, y);
}

vec2 intersect_vertical_line(float x, float slope, vec2 pos) {
    float initial = 1 / -slope * pos.y + pos.x;
    return vec2(x, (x - initial) * slope);
}

RayHit calc_intersection(Ray ray) {
    Rect2 cell = new_rect(floor_vec(ray.pos / tilemap.cell_size) * tilemap.cell_size - STEP_OFFSET, vec2(tilemap.cell_size) + STEP_OFFSET);
    RayHit hit;

    if (ray.dir.y == -1.0) {
        hit.point = vec2(ray.pos.x, cell.start.y);
        hit.u = calc_u(cell.start.x, cell.end.x, hit.point.x);
        hit.normal = DOWN;
        return hit;
    }

    if (ray.dir.y == 1.0) {
        hit.point = vec2(ray.pos.x, cell.end.y);
        hit.u = calc_u(cell.end.x, cell.start.x, hit.point.x);
        hit.normal = UP;
        return hit;
    }

    if (ray.dir.x == -1.0) {
        hit.point = vec2(cell.start.x, ray.pos.y);
        hit.u = calc_u(cell.end.y, cell.start.y, hit.point.y);
        hit.normal = RIGHT;
        return hit;
    }

    if (ray.dir.x == 1.0) {
        hit.point = vec2(cell.end.x, ray.pos.y);
        hit.u = calc_u(cell.start.y, cell.end.y, hit.point.y);
        hit.normal = LEFT;
        return hit;
    }

    float slope = ray.dir.y / ray.dir.x;

    if (ray.dir.y < 0) {
        hit.point = intersect_horizontal_line(cell.start.y, slope, ray.pos);
        hit.u = calc_u(cell.start.x, cell.end.x, hit.point.x);
        hit.normal = DOWN;
    }
    else {
        hit.point = intersect_horizontal_line(cell.end.y, slope, ray.pos);
        hit.u = calc_u(cell.end.x, cell.start.x, hit.point.x);
        hit.normal = UP;
    }

    if (hit.point.x < cell.start.x) {
        hit.point = intersect_vertical_line(cell.start.x, slope, ray.pos);
        hit.u = calc_u(cell.end.y, cell.start.y, hit.point.y);
        hit.normal = RIGHT;
    }
    else if (hit.point.x > cell.end.x) {
        hit.point = intersect_vertical_line(cell.end.x, slope, ray.pos);
        hit.u = calc_u(cell.start.y, cell.end.y, hit.point.y);
        hit.normal = LEFT;
    }

    return hit;
}

Tile get_tile(vec2 point) {
    int x = clamp(int(floor(point.x / tilemap.cell_size)), tilemap.dim.start.x, tilemap.dim.end.x);
    int y = clamp(int(floor(point.y / tilemap.cell_size)), tilemap.dim.start.y, tilemap.dim.end.y);

    int index = y * tilemap_num_cols + x;
    return tilemap.tiles[index - tilemap_index_offset];
}

RayHit raycast(float angle) {
    Ray ray;
    ray.pos = camera_data.origin;
    ray.dir = rotation(angle - camera_data.rotation) * UP;

    vec2 origin = ray.pos;

    while (true) {
        RayHit hit = calc_intersection(ray);

        hit.dist = length(hit.point - origin) * cos(angle);
        if (hit.dist > min(max_wall_height, camera_data.far_plane)) {
            hit.dist = max_wall_height + 1;
            return hit;
        }

        hit.atlas_coords = get_tile(hit.point).atlas_coords;
        if (hit.atlas_coords.x >= 0 && hit.atlas_coords.y >= 0) {
            return hit;
        }

        ray.pos = hit.point;
    }
}

void draw_coloured_line(int start, int end, vec4 colour) {
    for (int y = start; y < end; y++) {
        imageStore(canvas, ivec2(gl_GlobalInvocationID.x, y), colour);
    }
}

vec4 calc_light_colour(RayHit ray, float v) {
    vec4 colour = light_data.ambient;

    for (int i = 0; i < light_data.num_lights; i++) {
        PointLight light = light_data.lights[i];

        vec3 light_pos = vec3(light.position.x, light.position.y, (1.0 - light.z_offset) * tilemap.cell_size);
        vec3 point = vec3(ray.point.x, ray.point.y, (1.0 - v) * tilemap.cell_size);

        vec3 light_vec = light_pos - point;
        float len = length(light_vec);

        vec3 normal = vec3(ray.normal.x, ray.normal.y, 0.0);
        colour += max(dot(light_vec / len, normal), 0) * light.colour / dot(light_data.att, vec3(1.0, len, len * len));
    }

    return colour;
}

void draw_textured_line(int start, int end, RayHit ray) {
    vec2 offset = 1.0 / tilemap.atlas_dim;

    for (int y = start; y < end; y++) {
        float v = lerp(0.0, 1.0, float(y - start) / (end - start));

        vec4 light_colour = calc_light_colour(ray, v);

        vec2 uv = lerp_vec2(offset * ray.atlas_coords, offset * (ray.atlas_coords + ivec2(1)), vec2(ray.u, v));
        imageStore(canvas, ivec2(gl_GlobalInvocationID.x, y), texture(tilemap_atlas, uv) * light_colour);
    }
}

void draw_wall(RayHit ray) {
    int mid_point = canvas_size.y / 2;
    int height = int(floor(max_wall_height / ray.dist));

    draw_coloured_line(0, mid_point - height, tilemap.ceil_colour);
    draw_textured_line(mid_point - height, mid_point + height, ray);
    draw_coloured_line(mid_point + height, canvas_size.y, tilemap.floor_colour);
}

void main() {
    canvas_size = imageSize(canvas);
    max_wall_height = canvas_size.y / 2 * tilemap.cell_size;

    tilemap_num_cols = tilemap.dim.end.x - tilemap.dim.start.x;
    tilemap_index_offset = tilemap.dim.start.y * tilemap_num_cols + tilemap.dim.start.x;

    float x = lerp(tan(camera_data.fov), tan(-camera_data.fov), float(gl_GlobalInvocationID.x) / canvas_size.x);
    RayHit ray = raycast(atan(x));

    draw_wall(ray);
}
