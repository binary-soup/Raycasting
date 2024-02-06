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
    float dist;
    float u;
    vec2 normal;
    int texture_index;
};

struct Rect2 {
    vec2 start;
    vec2 end;
};

const vec2 STEP_OFFSET = vec2(0.001);
const vec2 UP = vec2(0.0, -1.0);
const vec2 DOWN = vec2(0.0, 1.0);
const vec2 LEFT = vec2(-1.0, 0.0);
const vec2 RIGHT = vec2(1.0, 0.0);

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

Ray calc_intersection(Ray ray) {
    Rect2 cell = new_rect(floor_vec(ray.pos) - STEP_OFFSET, vec2(1.0, 1.0) + STEP_OFFSET);

    if (ray.dir.y == -1.0) {
        ray.pos = vec2(ray.pos.x, cell.start.y);
        ray.u = calc_u(cell.start.x, cell.end.x, ray.pos.x);
        ray.normal = DOWN;
        return ray;
    }

    if (ray.dir.y == 1.0) {
        ray.pos = vec2(ray.pos.x, cell.end.y);
        ray.u = calc_u(cell.end.x, cell.start.x, ray.pos.x);
        ray.normal = UP;
        return ray;
    }

    if (ray.dir.x == -1.0) {
        ray.pos = vec2(cell.start.x, ray.pos.y);
        ray.u = calc_u(cell.end.y, cell.start.y, ray.pos.y);
        ray.normal = RIGHT;
        return ray;
    }

    if (ray.dir.x == 1.0) {
        ray.pos = vec2(cell.end.x, ray.pos.y);
        ray.u = calc_u(cell.start.y, cell.end.y, ray.pos.y);
        ray.normal = LEFT;
        return ray;
    }

    float slope = ray.dir.y / ray.dir.x;

    if (ray.dir.y < 0) {
        ray.pos = intersect_horizontal_line(cell.start.y, slope, ray.pos);
        ray.u = calc_u(cell.start.x, cell.end.x, ray.pos.x);
        ray.normal = DOWN;
    }
    else {
        ray.pos = intersect_horizontal_line(cell.end.y, slope, ray.pos);
        ray.u = calc_u(cell.end.x, cell.start.x, ray.pos.x);
        ray.normal = UP;
    }

    if (ray.pos.x < cell.start.x) {
        ray.pos = intersect_vertical_line(cell.start.x, slope, ray.pos);
        ray.u = calc_u(cell.end.y, cell.start.y, ray.pos.y);
        ray.normal = RIGHT;
    }
    else if (ray.pos.x > cell.end.x) {
        ray.pos = intersect_vertical_line(cell.end.x, slope, ray.pos);
        ray.u = calc_u(cell.start.y, cell.end.y, ray.pos.y);
        ray.normal = LEFT;
    }

    return ray;
}

Tile get_tile(vec2 point) {
    int x = clamp(int(floor(point.x)), tilemap.dim.start.x, tilemap.dim.end.x);
    int y = clamp(int(floor(point.y)), tilemap.dim.start.y, tilemap.dim.end.y);

    int index = y * tilemap_num_cols + x;
    return tilemap.tiles[index - tilemap_index_offset];
}

Ray warp_ray(Ray ray, Tile tile) {
    if (tile.warp_offset == vec2(0.0, 0.0)) {
        return ray;
    }

    vec2 origin = floor_vec(ray.pos) + vec2(0.5, 0.5);
    mat2 rot = rotation(tile.warp_angle);

    ray.pos = (ray.pos - ray.normal - origin) * rot + origin + tile.warp_offset;
    ray.dir *= rot;

    return ray;
}

Ray raycast(float angle) {
    Ray ray;
    ray.pos = camera_data.origin;
    ray.dir = rotation(angle - camera_data.rotation) * vec2(0.0, -1.0);
    ray.dist = 0.0;

    while (true) {
        vec2 prev_pos = ray.pos;
        ray = calc_intersection(ray);

        ray.dist += length(ray.pos - prev_pos) * cos(angle);

        if (ray.dist > camera_data.far_plane) {
            ray.dist = camera_data.far_plane;
            return ray;
        }

        Tile tile = get_tile(ray.pos);

        ray.texture_index = tile.texture_index;
        if (ray.texture_index >= 0) {
            return ray;
        }

        ray = warp_ray(ray, tile);
    }
}

void main() {
    tilemap_num_cols = tilemap.dim.end.x - tilemap.dim.start.x;
    tilemap_index_offset = tilemap.dim.start.y * tilemap_num_cols + tilemap.dim.start.x;

    float x = lerp(tan(camera_data.fov), tan(-camera_data.fov), gl_GlobalInvocationID.x / float(gl_NumWorkGroups * 64));
    Ray ray = raycast(atan(x));

    imageStore(output_data, ivec2(gl_GlobalInvocationID.x, 0), vec4(ray.dist, ray.u, ray.texture_index, 0.0));
    imageStore(output_data, ivec2(gl_GlobalInvocationID.x, 1), vec4(ray.normal, ray.dir));
}
