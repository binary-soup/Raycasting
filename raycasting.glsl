#[compute]
#version 450

layout(local_size_x = 64, local_size_y = 1, local_size_z = 1) in;

layout(rgba32f, binding = 0) uniform image2D output_data;

layout(set = 0, binding = 1, std430) restrict buffer CameraData {
    vec2 origin;
    float rotation;
    float far_plane;
    float fov;
    float pitch;
}
camera_data;

struct Tile {
    int texture_index;
    float warp_angle;
    vec2 warp_offset;
};

struct Rect2i {
    ivec2 start;
    ivec2 end;
};

layout(set = 0, binding = 2, std430) restrict buffer Tilemap {
    Rect2i dim;
    Tile[] tiles;
}
tilemap;

struct Ray {
    vec2 pos;
    vec2 dir;
};

struct RayHit {
    vec2 point;
    float dist;
    float u;
    vec3 normal;
    int texture_index;
};

struct Rect2 {
    vec2 start;
    vec2 end;
};

const vec2 STEP_OFFSET = vec2(0.001);
const vec3 UP = vec3(0.0, -1.0, 0.0);
const vec3 DOWN = vec3(0.0, 1.0, 0.0);
const vec3 LEFT = vec3(-1.0, 0.0, 0.0);
const vec3 RIGHT = vec3(1.0, 0.0, 0.0);

//============================

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
    Rect2 cell = new_rect(floor_vec(ray.pos) - STEP_OFFSET, vec2(1.0, 1.0) + STEP_OFFSET);
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
    int x = clamp(int(floor(point.x)), tilemap.dim.start.x, tilemap.dim.end.x);
    int y = clamp(int(floor(point.y)), tilemap.dim.start.y, tilemap.dim.end.y);

    int index = y * tilemap_num_cols + x;
    return tilemap.tiles[index - tilemap_index_offset];
}

RayHit raycast(float angle) {
    Ray ray;
    ray.pos = camera_data.origin;
    ray.dir = rotation(angle - camera_data.rotation) * vec2(0.0, -1.0);

    vec2 origin = ray.pos;

    while (true) {
        RayHit hit = calc_intersection(ray);

        hit.dist = length(hit.point - origin) * cos(angle);
        if (hit.dist > camera_data.far_plane) {
            hit.dist = camera_data.far_plane;
            return hit;
        }

        hit.texture_index = get_tile(hit.point).texture_index;
        if (hit.texture_index >= 0) {
            return hit;
        }

        ray.pos = hit.point;
    }
}

void main() {
    tilemap_num_cols = tilemap.dim.end.x - tilemap.dim.start.x;
    tilemap_index_offset = tilemap.dim.start.y * tilemap_num_cols + tilemap.dim.start.x;

    float x = lerp(tan(camera_data.fov), tan(-camera_data.fov), gl_GlobalInvocationID.x / float(gl_NumWorkGroups * 64));
    RayHit ray = raycast(atan(x));

    imageStore(output_data, ivec2(gl_GlobalInvocationID.x, 0), vec4(ray.dist, ray.u, ray.texture_index, 0.0));
    imageStore(output_data, ivec2(gl_GlobalInvocationID.x, 1), vec4(ray.point, 0.0, 0.0));
    imageStore(output_data, ivec2(gl_GlobalInvocationID.x, 2), vec4(ray.normal, 0.0));
}
