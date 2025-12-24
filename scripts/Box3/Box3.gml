/// @desc Box3 functions using arrays [minX, minY, minZ, maxX, maxY, maxZ]

/// @func box3_create(minX, minY, minZ, maxX, maxY, maxZ)
function box3_create(minX = infinity, minY = infinity, minZ = infinity, maxX = -infinity, maxY = -infinity, maxZ = -infinity) {
    gml_pragma("forceinline");
    return [minX, minY, minZ, maxX, maxY, maxZ];
}

function box3_set(b, minX, minY, minZ, maxX, maxY, maxZ) {
    gml_pragma("forceinline");
    b[0] = minX; b[1] = minY; b[2] = minZ;
    b[3] = maxX; b[4] = maxY; b[5] = maxZ;
}

function box3_copy(b, src) {
    gml_pragma("forceinline");
    array_copy(b, 0, src, 0, 6);
}

function box3_clone(b) {
    gml_pragma("forceinline");
    return [b[0], b[1], b[2], b[3], b[4], b[5]];
}

/// @func box3_expand_by_point(b, x, y, z)
function box3_expand_by_point(b, x, y, z) {
    gml_pragma("forceinline");
    if (x < b[0]) b[0] = x;
    if (y < b[1]) b[1] = y;
    if (z < b[2]) b[2] = z;
    if (x > b[3]) b[3] = x;
    if (y > b[4]) b[4] = y;
    if (z > b[5]) b[5] = z;
}

/// @func box3_contains_point(b, x, y, z)
function box3_contains_point(b, x, y, z) {
    gml_pragma("forceinline");
    return x >= b[0] && x <= b[3] &&
           y >= b[1] && y <= b[4] &&
           z >= b[2] && z <= b[5];
}

/// @func box3_intersects_box(b, b2)
function box3_intersects_box(b, b2) {
    gml_pragma("forceinline");
    // Intersects if overlap on all axes
    return b2[3] >= b[0] && b2[0] <= b[3] &&
           b2[4] >= b[1] && b2[1] <= b[4] &&
           b2[5] >= b[2] && b2[2] <= b[5];
}

/// @func box3_get_center(b, out)
/// @desc Stores the center in the output vector (or creates new).
function box3_get_center(b, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    out[0] = (b[0] + b[3]) * 0.5;
    out[1] = (b[1] + b[4]) * 0.5;
    out[2] = (b[2] + b[5]) * 0.5;
    return out;
}

/// @func box3_get_size(b, out)
/// @desc Stores the size in the output vector.
function box3_get_size(b, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    out[0] = b[3] - b[0];
    out[1] = b[4] - b[1];
    out[2] = b[5] - b[2];
    return out;
}

function box3_equals(b, b2) {
    gml_pragma("forceinline");
    return b[0]==b2[0] && b[1]==b2[1] && b[2]==b2[2] && b[3]==b2[3] && b[4]==b2[4] && b[5]==b2[5];
}

function box3_contains_box(b, b2) {
    gml_pragma("forceinline");
    return b2[0] >= b[0] && b2[1] >= b[1] && b2[2] >= b[2] &&
           b2[3] <= b[3] && b2[4] <= b[4] && b2[5] <= b[5];
}

function box3_clamp_point(b, x, y, z, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    out[0] = clamp(x, b[0], b[3]);
    out[1] = clamp(y, b[1], b[4]);
    out[2] = clamp(z, b[2], b[5]);
    return out;
}

function box3_distance_to_point(b, x, y, z) {
    gml_pragma("forceinline");

    var dx = 0;
    if (x < b[0]) dx = b[0] - x;
    else if (x > b[3]) dx = x - b[3];

    var dy = 0;
    if (y < b[1]) dy = b[1] - y;
    else if (y > b[4]) dy = y - b[4];

    var dz = 0;
    if (z < b[2]) dz = b[2] - z;
    else if (z > b[5]) dz = z - b[5];

    return sqrt(dx*dx + dy*dy + dz*dz);
}

function box3_expand_by_scalar(b, s) {
    gml_pragma("forceinline");
    b[0] -= s; b[1] -= s; b[2] -= s;
    b[3] += s; b[4] += s; b[5] += s;
}

function box3_expand_by_vector(b, v) {
    gml_pragma("forceinline");
    b[0] -= v[0]; b[1] -= v[1]; b[2] -= v[2];
    b[3] += v[0]; b[4] += v[1]; b[5] += v[2];
}

function box3_is_empty(b) {
    gml_pragma("forceinline");
    return b[0] > b[3] || b[1] > b[4] || b[2] > b[5];
}

function box3_make_empty(b) {
    gml_pragma("forceinline");
    b[0] = infinity; b[1] = infinity; b[2] = infinity;
    b[3] = -infinity; b[4] = -infinity; b[5] = -infinity;
}

function box3_union(b, b2) {
    gml_pragma("forceinline");
    b[0] = min(b[0], b2[0]); b[1] = min(b[1], b2[1]); b[2] = min(b[2], b2[2]);
    b[3] = max(b[3], b2[3]); b[4] = max(b[4], b2[4]); b[5] = max(b[5], b2[5]);
    return b;
}

function box3_intersect(b, b2) {
    gml_pragma("forceinline");
    b[0] = max(b[0], b2[0]); b[1] = max(b[1], b2[1]); b[2] = max(b[2], b2[2]);
    b[3] = min(b[3], b2[3]); b[4] = min(b[4], b2[4]); b[5] = min(b[5], b2[5]);
    if (box3_is_empty(b)) box3_make_empty(b);
    return b;
}

function box3_translate(b, ox, oy, oz) {
    gml_pragma("forceinline");
    b[0] += ox; b[1] += oy; b[2] += oz;
    b[3] += ox; b[4] += oy; b[5] += oz;
}

function box3_set_from_center_and_size(b, center, size) {
    gml_pragma("forceinline");
    var hx = size[0] * 0.5, hy = size[1] * 0.5, hz = size[2] * 0.5;
    b[0] = center[0] - hx; b[1] = center[1] - hy; b[2] = center[2] - hz;
    b[3] = center[0] + hx; b[4] = center[1] + hy; b[5] = center[2] + hz;
    return b;
}

function box3_set_from_points(b, points) {
    gml_pragma("forceinline");
    box3_make_empty(b);
    var n = array_length(points);
    for (var i=0; i<n; i++) {
        var p = points[i];
        box3_expand_by_point(b, p[0], p[1], p[2]);
    }
    return b;
}

function box3_set_from_array(b, arr, offset = 0) {
    gml_pragma("forceinline");
    box3_make_empty(b);
    var n = array_length(arr);
    if (n == 0 || offset >= n) return b;
    for (var i = offset; i < n; i += 3) {
        if (i + 2 >= n) break;
        box3_expand_by_point(b, arr[i], arr[i + 1], arr[i + 2]);
    }
    return b;
}

function box3_set_from_buffer_attribute(b, buffer, offset = 0) {
    gml_pragma("forceinline");
    // Alias of set_from_array for flat numeric buffers
    return box3_set_from_array(b, buffer, offset);
}

function box3_apply_matrix4(b, m) {
    gml_pragma("forceinline");
    if (box3_is_empty(b)) return b;
    var minX=b[0], minY=b[1], minZ=b[2], maxX=b[3], maxY=b[4], maxZ=b[5];
    var p = [minX, minY, minZ];
    box3_make_empty(b);
    vec3_apply_matrix4(p, m); box3_expand_by_point(b, p[0], p[1], p[2]);
    p = [minX, minY, maxZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p[0], p[1], p[2]);
    p = [minX, maxY, minZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p[0], p[1], p[2]);
    p = [minX, maxY, maxZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p[0], p[1], p[2]);
    p = [maxX, minY, minZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p[0], p[1], p[2]);
    p = [maxX, minY, maxZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p[0], p[1], p[2]);
    p = [maxX, maxY, minZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p[0], p[1], p[2]);
    p = [maxX, maxY, maxZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p[0], p[1], p[2]);
    return b;
}

function box3_get_bounding_sphere(b) {
    gml_pragma("forceinline");
    var c = box3_get_center(b);
    var s = box3_get_size(b);
    var r = 0.5 * sqrt(s[0]*s[0] + s[1]*s[1] + s[2]*s[2]);
    return sphere_create(c[0], c[1], c[2], r);
}

function box3_get_parameter(b, p, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    var sx = b[3] - b[0], sy = b[4] - b[1], sz = b[5] - b[2];
    out[0] = (sx != 0) ? ((p[0] - b[0]) / sx) : 0;
    out[1] = (sy != 0) ? ((p[1] - b[1]) / sy) : 0;
    out[2] = (sz != 0) ? ((p[2] - b[2]) / sz) : 0;
    return out;
}

function box3_intersects_plane(b, plane) {
    gml_pragma("forceinline");
    return plane_intersects_box(plane, b);
}

function box3_intersects_sphere(b, sphere) {
    gml_pragma("forceinline");
    return sphere_intersects_box(sphere, b);
}

function box3_intersects_triangle(b, a, c, d) {
    gml_pragma("forceinline");
    // Approximate by triangle AABB overlap
    var minX = min(a[0], min(c[0], d[0]));
    var minY = min(a[1], min(c[1], d[1]));
    var minZ = min(a[2], min(c[2], d[2]));
    var maxX = max(a[0], max(c[0], d[0]));
    var maxY = max(a[1], max(c[1], d[1]));
    var maxZ = max(a[2], max(c[2], d[2]));
    var triBox = [minX, minY, minZ, maxX, maxY, maxZ];
    return box3_intersects_box(b, triBox);
}

