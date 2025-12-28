/// @desc Box3 functions [minX, minY, minZ, maxX, maxY, maxZ]

global.UE_BOX3_TEMP0 = box3_create();

enum BOX3 {
  minX, minY, minZ, maxX, maxY, maxZ
}

/// @func box3_create(minVec, maxVec)
function box3_create(minVec = undefined, maxVec = undefined) {
    gml_pragma("forceinline");
    minVec ??= vec3_create(infinity, infinity, infinity);
    maxVec ??= vec3_create(-infinity, -infinity, -infinity);
    return [minVec[0], minVec[1], minVec[2], maxVec[0], maxVec[1], maxVec[2]];
}

/// @func box3_set(b, minVec, maxVec)
/// @desc Sets the box boundaries.
/// @param {Array<Real>} b The box to modify
/// @param {Real} minVec Minimum vector
/// @param {Real} maxVec Maximum vector
/// @returns {Array<Real>} The modified box
function box3_set(b, minVec, maxVec) {
    gml_pragma("forceinline");
    b[0] = minVec[0]; b[1] = minVec[1]; b[2] = minVec[2];
    b[3] = maxVec[0]; b[4] = maxVec[1]; b[5] = maxVec[2];
    return b;
}

/// @func box3_copy(b, src)
/// @desc Copies the properties of one box to another.
/// @param {Array<Real>} b The target box (will be modified)
/// @param {Array<Real>} src The source box
/// @returns {Array<Real>} The modified box
function box3_copy(b, src) {
    gml_pragma("forceinline");
    array_copy(b, 0, src, 0, 6);
    return b;
}

/// @func box3_clone(b)
/// @desc Creates a new box with the same properties.
/// @param {Array<Real>} b The box to clone
/// @returns {Array<Real>} A new box
function box3_clone(b) {
    gml_pragma("forceinline");
    return [b[0], b[1], b[2], b[3], b[4], b[5]];
}

/// @func box3_expand_by_point(b, p)
/// @desc Expands the box to include the given point.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} p The point vector [x, y, z]
/// @returns {Array<Real>} The modified box
function box3_expand_by_point(b, p) {
    gml_pragma("forceinline");
    if (p[0] < b[0]) b[0] = p[0];
    if (p[0] < b[0]) b[0] = p[0];
    if (p[1] < b[1]) b[1] = p[1];
    if (p[2] < b[2]) b[2] = p[2];
    if (p[0] > b[3]) b[3] = p[0];
    if (p[1] > b[4]) b[4] = p[1];
    if (p[2] > b[5]) b[5] = p[2];
    return b;
}

/// @func box3_contains_point(b, p)
/// @desc Checks if the box contains the given point.
/// @param {Array<Real>} b The box
/// @param {Real} p The point vector [x, y, z]
/// @returns {Bool}
function box3_contains_point(b, p) {
    gml_pragma("forceinline");
    return p[0] >= b[0] && p[0] <= b[3] &&
           p[1] >= b[1] && p[1] <= b[4] &&
           p[2] >= b[2] && p[2] <= b[5];
}

/// @func bo3_intersects_box(b, b2)
/// @desc Checks if two boxes intersect.
/// @param {Array<Real>} b The first box
/// @param {Array<Real>} b2 The second box
/// @returns {Bool}
function box3_intersects_box(b, b2) {
    gml_pragma("forceinline");
    // Intersects if overlap on all axes
    return b2[3] >= b[0] && b2[0] <= b[3] &&
           b2[4] >= b[1] && b2[1] <= b[4] &&
           b2[5] >= b[2] && b2[2] <= b[5];
}

/// @func box3_get_center(b, out)
/// @desc Stores the center in the output vector (or creates new).
/// @param {Array<Real>} b The box
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>} The center vector
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
/// @param {Array<Real>} b The box
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>} The size vector
function box3_get_size(b, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    out[0] = b[3] - b[0];
    out[1] = b[4] - b[1];
    out[2] = b[5] - b[2];
    return out;
}

/// @func box3_equals(b, b2)
/// @desc Checks if two boxes are equal.
/// @param {Array<Real>} b The first box
/// @param {Array<Real>} b2 The second box
/// @returns {Bool}
function box3_equals(b, b2) {
    gml_pragma("forceinline");
    return b[0]==b2[0] && b[1]==b2[1] && b[2]==b2[2] && b[3]==b2[3] && b[4]==b2[4] && b[5]==b2[5];
}

/// @func box3_contains_box(b, b2)
/// @desc Checks if the first box completely contains the second box.
/// @param {Array<Real>} b The first box
/// @param {Array<Real>} b2 The second box
/// @returns {Bool}
function box3_contains_box(b, b2) {
    gml_pragma("forceinline");
    return b2[0] >= b[0] && b2[1] >= b[1] && b2[2] >= b[2] &&
           b2[3] <= b[3] && b2[4] <= b[4] && b2[5] <= b[5];
}

/// @func box3_clamp_point(b, p, out = undefined)
/// @desc Clamps a point to the box boundaries.
/// @param {Array<Real>} b The box
/// @param {Array<Real>} p The point vector [x, y, z]
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>} The clamped point
function box3_clamp_point(b, p, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    out[0] = clamp(p[0], b[0], b[3]);
    out[1] = clamp(p[1], b[1], b[4]);
    out[2] = clamp(p[2], b[2], b[5]);
    return out;
}

/// @func box3_distance_to_point(b, p)
/// @desc Calculates the distance from the box to a point.
/// @param {Array<Real>} b The box
/// @param {Real} x The point's x coordinate
/// @param {Real} y The point's y coordinate
/// @param {Array<Real>} p The point vector [x, y, z]
/// @returns {Real} The distance
function box3_distance_to_point(b, p) {
    gml_pragma("forceinline");

    var dx = 0;
    if (p[0] < b[0]) dx = b[0] - p[0];
    else if (p[0] > b[3]) dx = p[0] - b[3];

    var dy = 0;
    if (p[1] < b[1]) dy = b[1] - p[1];
    else if (p[1] > b[4]) dy = p[1] - b[4];

    var dz = 0;
    if (p[2] < b[2]) dz = b[2] - p[2];
    else if (p[2] > b[5]) dz = p[2] - b[5];

    return sqrt(dx*dx + dy*dy + dz*dz);
}

/// @func box3_expand_by_scalar(b, s)
/// @desc Expands the box by a scalar value in all directions.
/// @param {Array<Real>} b The box to modify
/// @param {Real} s The scalar value
/// @returns {Array<Real>} The modified box
function box3_expand_by_scalar(b, s) {
    gml_pragma("forceinline");
    b[0] -= s; b[1] -= s; b[2] -= s;
    b[3] += s; b[4] += s; b[5] += s;
    return b;
}

/// @func box3_expand_by_vector(b, v)
/// @desc Expands the box by a vector's components.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} v The vector [x, y, z]
/// @returns {Array<Real>} The modified box
function box3_expand_by_vector(b, v) {
    gml_pragma("forceinline");
    b[0] -= v[0]; b[1] -= v[1]; b[2] -= v[2];
    b[3] += v[0]; b[4] += v[1]; b[5] += v[2];
    return b;
}

/// @func box3_is_empty(b)
/// @desc Checks if the box is empty (min > max).
/// @param {Array<Real>} b The box
/// @returns {Bool}
function box3_is_empty(b) {
    gml_pragma("forceinline");
    return b[0] > b[3] || b[1] > b[4] || b[2] > b[5];
}

/// @func box3_make_empty(b)
/// @desc Resets the box to an empty state.
/// @param {Array<Real>} b The box to modify
/// @returns {Array<Real>} The modified box
function box3_make_empty(b) {
    gml_pragma("forceinline");
    b[0] = infinity; b[1] = infinity; b[2] = infinity;
    b[3] = -infinity; b[4] = -infinity; b[5] = -infinity;
    return b;
}

/// @func box3_union(b, b2)
/// @desc Computes the union of two boxes.
/// @param {Array<Real>} b The first box (will be modified)
/// @param {Array<Real>} b2 The second box
/// @returns {Array<Real>} The modified box
function box3_union(b, b2) {
    gml_pragma("forceinline");
    b[0] = min(b[0], b2[0]); b[1] = min(b[1], b2[1]); b[2] = min(b[2], b2[2]);
    b[3] = max(b[3], b2[3]); b[4] = max(b[4], b2[4]); b[5] = max(b[5], b2[5]);
    return b;
}

/// @func box3_intersect(b, b2)
/// @desc Computes the intersection of two boxes.
/// @param {Array<Real>} b The first box (will be modified)
/// @param {Array<Real>} b2 The second box
/// @returns {Array<Real>} The modified box
function box3_intersect(b, b2) {
    gml_pragma("forceinline");
    b[0] = max(b[0], b2[0]); b[1] = max(b[1], b2[1]); b[2] = max(b[2], b2[2]);
    b[3] = min(b[3], b2[3]); b[4] = min(b[4], b2[4]); b[5] = min(b[5], b2[5]);
    if (box3_is_empty(b)) box3_make_empty(b);
    return b;
}

/// @func box3_translate(b, offset)
/// @desc Translates the box by the given offset.
/// @func box3_translate(b, offset)
/// @desc Translates the box by the given offset.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} offset The offset vector [ox, oy, oz]
function box3_translate(b, offset) {
    gml_pragma("forceinline");
    b[0] += offset[0]; b[1] += offset[1]; b[2] += offset[2];
    b[3] += offset[0]; b[4] += offset[1]; b[5] += offset[2];
    return b;
}

/// @func box3_set_from_center_and_size(b, center, size)
/// @desc Sets the box from a center point and a size vector.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} center The center point [x, y, z]
/// @param {Array<Real>} size The size vector [w, h, d]
/// @returns {Array<Real>} The modified box
function box3_set_from_center_and_size(b, center, size) {
    gml_pragma("forceinline");
    var hx = size[0] * 0.5, hy = size[1] * 0.5, hz = size[2] * 0.5;
    b[0] = center[0] - hx; b[1] = center[1] - hy; b[2] = center[2] - hz;
    b[3] = center[0] + hx; b[4] = center[1] + hy; b[5] = center[2] + hz;
    return b;
}

/// @func box3_set_from_points(b, points)
/// @desc Sets the box to encompass a set of points.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Array<Real>>} points An array of points [[x,y,z], ...]
/// @returns {Array<Real>} The modified box
function box3_set_from_points(b, points) {
    gml_pragma("forceinline");
    box3_make_empty(b);
    var n = array_length(points);
    for (var i=0; i<n; i++) {
        box3_expand_by_point(b, points[i]);
    }
    return b;
}

/// @func box3_set_from_array(b, arr, offset = 0)
/// @desc Sets the box from a flat array of coordinates.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} arr The flat array
/// @param {Real} [offset=0] Starting offset in the array
/// @returns {Array<Real>} The modified box
function box3_set_from_array(b, arr, offset = 0) {
    gml_pragma("forceinline");
    box3_make_empty(b);
    var n = array_length(arr);
    if (n == 0 || offset >= n) return b;
    for (var i = offset; i < n; i += 3) {
        if (i + 2 >= n) break;
        box3_expand_by_point(b, [arr[i], arr[i+1], arr[i+2]]);
    }
    return b;
}

/// @func box3_set_from_buffer_attribute(b, buffer, offset = 0)
/// @desc Sets the box from a buffer (alias for set_from_array).
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} buffer The buffer
/// @param {Real} [offset=0] Starting offset
/// @returns {Array<Real>} The modified box
function box3_set_from_buffer_attribute(b, buffer, offset = 0) {
    gml_pragma("forceinline");
    // Alias of set_from_array for flat numeric buffers
    return box3_set_from_array(b, buffer, offset);
}

/// @func box3_apply_matrix4(b, m)
/// @desc Transforms the box by the given matrix.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} m The matrix to apply
/// @returns {Array<Real>} The modified box
function box3_apply_matrix4(b, m) {
    gml_pragma("forceinline");
    if (box3_is_empty(b)) return b;
    var minX=b[0], minY=b[1], minZ=b[2], maxX=b[3], maxY=b[4], maxZ=b[5];
    var p = [minX, minY, minZ];
    box3_make_empty(b);
    vec3_apply_matrix4(p, m); box3_expand_by_point(b, p);
    p = [minX, minY, maxZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p);
    p = [minX, maxY, minZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p);
    p = [minX, maxY, maxZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p);
    p = [maxX, minY, minZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p);
    p = [maxX, minY, maxZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p);
    p = [maxX, maxY, minZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p);
    p = [maxX, maxY, maxZ]; vec3_apply_matrix4(p, m); box3_expand_by_point(b, p);
    return b;
}

/// @func box3_get_bounding_sphere(b)
/// @desc Calculates the bounding sphere of the box.
/// @param {Array<Real>} b The box
/// @returns {Array<Real>} A new sphere
function box3_get_bounding_sphere(b) {
    gml_pragma("forceinline");
    var c = box3_get_center(b);
    var s = box3_get_size(b);
    var r = 0.5 * sqrt(s[0]*s[0] + s[1]*s[1] + s[2]*s[2]);
    return sphere_create(c, r);
}

/// @func box3_get_parameter(b, p, out = undefined)
/// @desc Returns a point as a parameter [0..1] within the box.
/// @param {Array<Real>} b The box
/// @param {Array<Real>} p The point
/// @param {Array<Real>} [out] Optional output vector
/// @returns {Array<Real>} The parameter vector
function box3_get_parameter(b, p, out = undefined) {
    gml_pragma("forceinline");
    out ??= array_create(3);
    var sx = b[3] - b[0], sy = b[4] - b[1], sz = b[5] - b[2];
    out[0] = (sx != 0) ? ((p[0] - b[0]) / sx) : 0;
    out[1] = (sy != 0) ? ((p[1] - b[1]) / sy) : 0;
    out[2] = (sz != 0) ? ((p[2] - b[2]) / sz) : 0;
    return out;
}

/// @func box3_intersects_plane(b, plane)
/// @desc Checks if the box intersects a plane.
/// @param {Array<Real>} b The box
/// @param {Array<Real>} plane The plane
/// @returns {Bool}
function box3_intersects_plane(b, plane) {
    gml_pragma("forceinline");
    return plane_intersects_box(plane, b);
}

/// @func box3_intersects_sphere(b, sphere)
/// @desc Checks if the box intersects a sphere.
/// @param {Array<Real>} b The box
/// @param {Array<Real>} sphere The sphere
/// @returns {Bool}
function box3_intersects_sphere(b, sphere) {
    gml_pragma("forceinline");
    return sphere_intersects_box(sphere, b);
}

/// @func box3_intersects_triangle(b, a, c, d)
/// @desc Checks if the box intersects a triangle.
/// @param {Array<Real>} b The box
/// @param {Array<Real>} a Triangle point A
/// @param {Array<Real>} c Triangle point B
/// @param {Array<Real>} d Triangle point C
/// @returns {Bool}
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

