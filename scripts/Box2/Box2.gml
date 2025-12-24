/// @desc Box2 functions using arrays [minX, minY, maxX, maxY]

function box2_create(minX = infinity, minY = infinity, maxX = -infinity, maxY = -infinity) {
    gml_pragma("forceinline");
    return [minX, minY, maxX, maxY];
}

function box2_set(b, minX, minY, maxX, maxY) {
    gml_pragma("forceinline");
    b[0] = minX; b[1] = minY;
    b[2] = maxX; b[3] = maxY;
}

function box2_copy(b, src) {
    gml_pragma("forceinline");
    b[0] = src[0]; b[1] = src[1];
    b[2] = src[2]; b[3] = src[3];
}

function box2_clone(b) {
    gml_pragma("forceinline");
    return [b[0], b[1], b[2], b[3]];
}

function box2_expand_by_point(b, x, y) {
    gml_pragma("forceinline");
    if (x < b[0]) b[0] = x;
    if (y < b[1]) b[1] = y;
    if (x > b[2]) b[2] = x;
    if (y > b[3]) b[3] = y;
}

function box2_contains_point(b, x, y) {
    gml_pragma("forceinline");
    return x >= b[0] && x <= b[2] && y >= b[1] && y <= b[3];
}

function box2_intersects_box(b, b2) {
    gml_pragma("forceinline");
    return b2[2] >= b[0] && b2[0] <= b[2] &&
           b2[3] >= b[1] && b2[1] <= b[3];
}

function box2_contains_box(b, b2) {
    gml_pragma("forceinline");
    return b2[0] >= b[0] && b2[1] >= b[1] && b2[2] <= b[2] && b2[3] <= b[3];
}

function box2_equals(b, b2) {
    gml_pragma("forceinline");
    return b[0]==b2[0] && b[1]==b2[1] && b[2]==b2[2] && b[3]==b2[3];
}

function box2_clamp_point(b, x, y, out = undefined) {
    gml_pragma("forceinline");
    out ??= [0, 0];
    var cx = clamp(x, b[0], b[2]);
    var cy = clamp(y, b[1], b[3]);
    out[0] = cx; out[1] = cy;
    return out;
}

function box2_distance_to_point(b, x, y) {
    gml_pragma("forceinline");

    var dx = 0;
    if (x < b[0]) dx = b[0] - x;
    else if (x > b[2]) dx = x - b[2];

    var dy = 0;
    if (y < b[1]) dy = b[1] - y;
    else if (y > b[3]) dy = y - b[3];

    return sqrt(dx*dx + dy*dy);
}

function box2_expand_by_scalar(b, s) {
    gml_pragma("forceinline");
    b[0] -= s; b[1] -= s;
    b[2] += s; b[3] += s;
}

function box2_expand_by_vector(b, v) {
    gml_pragma("forceinline");
    b[0] -= v[0]; b[1] -= v[1];
    b[2] += v[0]; b[3] += v[1];
}

function box2_get_center(b, out = undefined) {
    gml_pragma("forceinline");
    out ??= [0, 0];
    out[0] = (b[0] + b[2]) * 0.5;
    out[1] = (b[1] + b[3]) * 0.5;
    return out;
}

function box2_get_size(b, out = undefined) {
    gml_pragma("forceinline");
    out ??= [0, 0];
    out[0] = b[2] - b[0];
    out[1] = b[3] - b[1];
    return out;
}

function box2_get_parameter(b, p, out = undefined) {
    gml_pragma("forceinline");
    out ??= [0, 0];
    var sx = b[2] - b[0];
    var sy = b[3] - b[1];
    out[0] = (sx != 0) ? ((p[0] - b[0]) / sx) : 0;
    out[1] = (sy != 0) ? ((p[1] - b[1]) / sy) : 0;
    return out;
}

function box2_is_empty(b) {
    gml_pragma("forceinline");
    return b[0] > b[2] || b[1] > b[3];
}

function box2_make_empty(b) {
    gml_pragma("forceinline");
    b[0] = infinity; b[1] = infinity;
    b[2] = -infinity; b[3] = -infinity;
}

function box2_intersect(b, b2) {
    gml_pragma("forceinline");
    b[0] = max(b[0], b2[0]);
    b[1] = max(b[1], b2[1]);
    b[2] = min(b[2], b2[2]);
    b[3] = min(b[3], b2[3]);
    if (box2_is_empty(b)) box2_make_empty(b);
    return b;
}

function box2_union(b, b2) {
    gml_pragma("forceinline");
    b[0] = min(b[0], b2[0]);
    b[1] = min(b[1], b2[1]);
    b[2] = max(b[2], b2[2]);
    b[3] = max(b[3], b2[3]);
    return b;
}

function box2_translate(b, ox, oy) {
    gml_pragma("forceinline");
    b[0] += ox; b[1] += oy;
    b[2] += ox; b[3] += oy;
}

function box2_set_from_center_and_size(b, center, size) {
    gml_pragma("forceinline");
    var hx = size[0] * 0.5;
    var hy = size[1] * 0.5;
    b[0] = center[0] - hx; b[1] = center[1] - hy;
    b[2] = center[0] + hx; b[3] = center[1] + hy;
    return b;
}

function box2_set_from_points(b, points) {
    gml_pragma("forceinline");
    box2_make_empty(b);
    var n = array_length(points);
    for (var i=0; i<n; i++) {
        var p = points[i];
        box2_expand_by_point(b, p[0], p[1]);
    }
    return b;
}
