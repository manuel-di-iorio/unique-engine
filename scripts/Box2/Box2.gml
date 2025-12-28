/// @desc Box2 functions using arrays [minX, minY, maxX, maxY]

enum BOX2 {
  minX, minY, maxX, maxY
}

function box2_create(minVec = undefined, maxVec = undefined) {
    gml_pragma("forceinline");
    minVec ??= vec2_create(infinity, infinity);
    maxVec ??= vec2_create(-infinity, -infinity);
    return [minVec[0], minVec[1], maxVec[0], maxVec[1]];
}

/// @func box2_set(b, minVec, maxVec)
/// @desc Sets the box boundaries.
/// @param {Array<Real>} b The box to modify
/// @param {Real} minX Minimum X
/// @param {Real} minY Minimum Y
/// @param {Real} maxX Maximum X
/// @param {Real} maxY Maximum Y
/// @returns {Array<Real>} The modified box
function box2_set(b, minVec, maxVec) {
    gml_pragma("forceinline");
    b[0] = minVec[0]; b[1] = minVec[1];
    b[2] = maxVec[0]; b[3] = maxVec[1];
    return b;
}

/// @func box2_copy(b, src)
/// @desc Copies the properties of one box to another.
/// @param {Array<Real>} b The target box (will be modified)
/// @param {Array<Real>} src The source box
/// @returns {Array<Real>} The modified box
function box2_copy(b, src) {
    gml_pragma("forceinline");
    b[0] = src[0]; b[1] = src[1];
    b[2] = src[2]; b[3] = src[3];
    return b;
}

/// @func box2_clone(b)
/// @desc Creates a new box with the same properties.
/// @param {Array<Real>} b The box to clone
/// @returns {Array<Real>} A new box
function box2_clone(b) {
    gml_pragma("forceinline");
    return [b[0], b[1], b[2], b[3]];
}

/// @func box2_expand_by_point(b, x, y)
/// @desc Expands the box to include the given point.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} point The point to include
/// @returns {Array<Real>} The modified box
function box2_expand_by_point(b, point) {
    gml_pragma("forceinline");
    if (point[0] < b[0]) b[0] = point[0];
    if (point[1] < b[1]) b[1] = point[1];
    if (point[0] > b[2]) b[2] = point[0];
    if (point[1] > b[3]) b[3] = point[1];
    return b;
}

function box2_contains_point(b, point) {
    gml_pragma("forceinline");
    return point[0] >= b[0] && point[0] <= b[2] && point[1] >= b[1] && point[1] <= b[3];
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

function box2_distance_to_point(b, point) {
    gml_pragma("forceinline");

    var dx = 0;
    if (point[0] < b[0]) dx = b[0] - point[0];
    else if (point[0] > b[2]) dx = point[0] - b[2];

    var dy = 0;
    if (point[1] < b[1]) dy = b[1] - point[1];
    else if (point[1] > b[3]) dy = point[1] - b[3];

    return sqrt(dx*dx + dy*dy);
}

/// @func box2_expand_by_scalar(b, s)
/// @desc Expands the box by a scalar value in all directions.
/// @param {Array<Real>} b The box to modify
/// @param {Real} s The scalar value
/// @returns {Array<Real>} The modified box
function box2_expand_by_scalar(b, s) {
    gml_pragma("forceinline");
    b[0] -= s; b[1] -= s;
    b[2] += s; b[3] += s;
    return b;
}

/// @func box2_expand_by_vector(b, v)
/// @desc Expands the box by a vector's components.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} v The vector [x, y]
/// @returns {Array<Real>} The modified box
function box2_expand_by_vector(b, v) {
    gml_pragma("forceinline");
    b[0] -= v[0]; b[1] -= v[1];
    b[2] += v[0]; b[3] += v[1];
    return b;
}

/// @func box2_get_center(b, out = undefined)
/// @desc Calculates the center of the box.
/// @param {Array<Real>} b The box
/// @param {Array<Real>} [out] Optional output array
/// @returns {Array<Real>} The center point
function box2_get_center(b, out = undefined) {
    gml_pragma("forceinline");
    out ??= [0, 0];
    out[0] = (b[0] + b[2]) * 0.5;
    out[1] = (b[1] + b[3]) * 0.5;
    return out;
}

/// @func box2_get_size(b, out = undefined)
/// @desc Calculates the size of the box.
/// @param {Array<Real>} b The box
/// @param {Array<Real>} [out] Optional output array
/// @returns {Array<Real>} The size vector
function box2_get_size(b, out = undefined) {
    gml_pragma("forceinline");
    out ??= [0, 0];
    out[0] = b[2] - b[0];
    out[1] = b[3] - b[1];
    return out;
}

/// @func box2_get_parameter(b, p, out = undefined)
/// @desc Returns a point as a parameter [0..1] within the box.
/// @param {Array<Real>} b The box
/// @param {Array<Real>} p The point
/// @param {Array<Real>} [out] Optional output array
/// @returns {Array<Real>} The parameter vector
function box2_get_parameter(b, p, out = undefined) {
    gml_pragma("forceinline");
    out ??= [0, 0];
    var sx = b[2] - b[0];
    var sy = b[3] - b[1];
    out[0] = (sx != 0) ? ((p[0] - b[0]) / sx) : 0;
    out[1] = (sy != 0) ? ((p[1] - b[1]) / sy) : 0;
    return out;
}

/// @func box2_is_empty(b)
/// @desc Checks if the box is empty (min > max).
/// @param {Array<Real>} b The box
/// @returns {Bool}
function box2_is_empty(b) {
    gml_pragma("forceinline");
    return b[0] > b[2] || b[1] > b[3];
}

/// @func box2_make_empty(b)
/// @desc Resets the box to an empty state.
/// @param {Array<Real>} b The box to modify
/// @returns {Array<Real>} The modified box
function box2_make_empty(b) {
    gml_pragma("forceinline");
    b[0] = infinity; b[1] = infinity;
    b[2] = -infinity; b[3] = -infinity;
    return b;
}

/// @func box2_intersect(b, b2)
/// @desc Computes the intersection of two boxes.
/// @param {Array<Real>} b The first box (will be modified)
/// @param {Array<Real>} b2 The second box
/// @returns {Array<Real>} The modified box
function box2_intersect(b, b2) {
    gml_pragma("forceinline");
    b[0] = max(b[0], b2[0]);
    b[1] = max(b[1], b2[1]);
    b[2] = min(b[2], b2[2]);
    b[3] = min(b[3], b2[3]);
    if (box2_is_empty(b)) box2_make_empty(b);
    return b;
}

/// @func box2_union(b, b2)
/// @desc Computes the union of two boxes.
/// @param {Array<Real>} b The first box (will be modified)
/// @param {Array<Real>} b2 The second box
/// @returns {Array<Real>} The modified box
function box2_union(b, b2) {
    gml_pragma("forceinline");
    b[0] = min(b[0], b2[0]);
    b[1] = min(b[1], b2[1]);
    b[2] = max(b[2], b2[2]);
    b[3] = max(b[3], b2[3]);
    return b;
}

/// @func box2_translate(b, offset)
/// @desc Translates the box by the given offset.
/// @param {Array<Real>} b The box to modify
/// @param {Real} offset offset
/// @returns {Array<Real>} The modified box
function box2_translate(b, offset) {
    gml_pragma("forceinline");
    b[0] += offset[0]; b[1] += offset[1];
    b[2] += offset[0]; b[3] += offset[1];
    return b;
}

/// @func box2_set_from_center_and_size(b, center, size)
/// @desc Sets the box from a center point and a size vector.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Real>} center The center point [x, y]
/// @param {Array<Real>} size The size vector [w, h]
/// @returns {Array<Real>} The modified box
function box2_set_from_center_and_size(b, center, size) {
    gml_pragma("forceinline");
    var hx = size[0] * 0.5;
    var hy = size[1] * 0.5;
    b[0] = center[0] - hx; b[1] = center[1] - hy;
    b[2] = center[0] + hx; b[3] = center[1] + hy;
    return b;
}

/// @func box2_set_from_points(b, points)
/// @desc Sets the box to encompass a set of points.
/// @param {Array<Real>} b The box to modify
/// @param {Array<Array<Real>>} points An array of points [[x,y], [x,y], ...]
/// @returns {Array<Real>} The modified box
function box2_set_from_points(b, points) {
    gml_pragma("forceinline");
    box2_make_empty(b);
    var n = array_length(points);
    for (var i=0; i<n; i++) {
        box2_expand_by_point(b, points[i]);
    }
    return b;
}
