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
    int atlas_coords;
};

struct Rect2i {
    ivec2 start;
    ivec2 end;
};

layout(set = 0, binding = 2, std430) restrict buffer Tilemap {
    int num_atlas_cols;
    int cell_size;
    Rect2i dim;
    Tile[] tiles;
}
tilemap;

layout(set = 0, binding = 3, std430) restrict buffer Params {
    vec4 ceil_colour;
    vec4 floor_colour;
}
params;

struct Ray {
    vec2 pos;
    vec2 dir;
};

struct RayHit {
    vec2 point;
    float dist;
    int atlas_coords;
};

struct Rect2 {
    vec2 start;
    vec2 end;
};

const vec2 UP = vec2(0.0, -1.0);
const vec2 STEP_OFFSET = vec2(0.01);

//============================

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

vec2 intersect_horizontal_line(float y, float slope, vec2 pos) {
    float initial = -slope * pos.x + pos.y;
    return vec2((y - initial) / slope, y);
}

vec2 intersect_vertical_line(float x, float slope, vec2 pos) {
    float initial = 1 / -slope * pos.y + pos.x;
    return vec2(x, (x - initial) * slope);
}

vec2 calc_intersection_point(Ray ray) {
    Rect2 cell = new_rect(floor_vec(ray.pos / tilemap.cell_size) * tilemap.cell_size - STEP_OFFSET, vec2(tilemap.cell_size) + STEP_OFFSET);
    
    if (ray.dir.y == -1.0) {
        return vec2(ray.pos.x, cell.start.y);
    }

    if (ray.dir.y == 1.0) {
        return vec2(ray.pos.x, cell.end.y);
    }

    if (ray.dir.x == -1.0) {
        return vec2(cell.start.x, ray.pos.y);
    }

    if (ray.dir.x == 1.0) {
        return vec2(cell.end.x, ray.pos.y);
    }

    vec2 point;
    float slope = ray.dir.y / ray.dir.x;

    if (ray.dir.y < 0) {
        point = intersect_horizontal_line(cell.start.y, slope, ray.pos);
    }
    else {
        point = intersect_horizontal_line(cell.end.y, slope, ray.pos);
    }

    if (point.x < cell.start.x) {
        return intersect_vertical_line(cell.start.x, slope, ray.pos);
    }

    if (point.x > cell.end.x) {
        return intersect_vertical_line(cell.end.x, slope, ray.pos);
    }

    return point;
}


Tile get_tile(vec2 point) {
    int x = clamp(int(floor(point.x / tilemap.cell_size)), tilemap.dim.start.x, tilemap.dim.end.x);
    int y = clamp(int(floor(point.y / tilemap.cell_size)), tilemap.dim.start.y, tilemap.dim.end.y);

    int num_cols = tilemap.dim.end.x - tilemap.dim.start.x;
    int index_offset = tilemap.dim.start.y * num_cols + tilemap.dim.start.x;

    int index = y * num_cols + x;
    return tilemap.tiles[index - index_offset];
}

RayHit raycast(float angle) {
    Ray ray;
    ray.pos = camera_data.origin;
    ray.dir = rotation(angle - camera_data.rotation) * UP;

    vec2 origin = ray.pos;

    while (true) {
        RayHit hit;
        hit.point = calc_intersection_point(ray);

        hit.dist = length(hit.point - origin) * cos(angle);
        if (hit.dist > camera_data.far_plane) {
            return hit;
        }

        hit.atlas_coords = get_tile(hit.point).atlas_coords;
        if (hit.atlas_coords >= 0) {
            return hit;
        }

        ray.pos = hit.point;
    }
}

vec4 get_atlas_colour(int coords) {
    switch (coords) {
        case 0:
            return vec4(1.0, 0.0, 0.0, 1.0);
        case 1:
            return vec4(1.0, 1.0, 0.0, 1.0);
        case 2:
            return vec4(0.0, 1.0, 0.0, 1.0);
        case 3:
            return vec4(0.117647, 0.564706, 1.0, 1.0);
    }

    return vec4(1.0);
}

void draw_coloured_line(int start, int end, vec4 colour) {
    for (int y = start; y < end; y++) {
        imageStore(canvas, ivec2(gl_GlobalInvocationID.x, y), colour);
    }
}

void draw_wall(RayHit ray) {
    int canvas_height = imageSize(canvas).y;

    int mid_point = canvas_height / 2;
    int height = int(floor(canvas_height / 2 / ray.dist * tilemap.cell_size));

    draw_coloured_line(0, mid_point - height, params.ceil_colour);
    draw_coloured_line(mid_point + height, canvas_height, params.floor_colour);

    if (ray.atlas_coords >= 0) {
        draw_coloured_line(mid_point - height, mid_point + height, get_atlas_colour(ray.atlas_coords));
    }
}

void main() {
    float canvas_width = imageSize(canvas).x;

    // RayHit ray;
    // ray.dist = 25000.0 / gl_GlobalInvocationID.x;
    // ray.atlas_coords = 3;

    RayHit ray = raycast(lerp(camera_data.fov, -camera_data.fov, gl_GlobalInvocationID.x / canvas_width));
    draw_wall(ray);
}
