/// @desc 2D vector functions using arrays [x, y]
/// All angles are in DEGREES.
/// All functions modify the first vector in-place when applicable for zero allocations.

// Global dummy array for temporary operations - reuse to avoid allocations
global.UE_VEC2_TEMP0 = [0, 0];

enum VEC2 {
  x, y
}

/// @func vec2_create(x, y)
/// @desc Creates a new vec2 array with the given components.
/// @param {Real} [x=0] X component
/// @param {Real} [y=0] Y component
/// @returns {Array<Real>} New vec2 array
function vec2_create(x = 0, y = 0) {
    gml_pragma("forceinline");
    return [x, y];
}

// ============================================================================
// SETTERS
// ============================================================================

/// @func vec2_set(vec, x, y)
/// @desc Sets the vector components.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} x The value of the x component
/// @param {Real} y The value of the y component
/// @returns {Array<Real>} The modified vector
function vec2_set(vec, x, y) {
    gml_pragma("forceinline");
    vec[0] = x;
    vec[1] = y;
    return vec;
}

/// @func vec2_set_scalar(vec, scalar)
/// @desc Sets the vector components to the same value.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} scalar The value to set for all components
/// @returns {Array<Real>} The modified vector
function vec2_set_scalar(vec, scalar) {
    gml_pragma("forceinline");
    vec[0] = scalar;
    vec[1] = scalar;
    return vec;
}

/// @func vec2_set_x(vec, x)
/// @desc Sets the vector's x component.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} x The value to set
/// @returns {Array<Real>} The modified vector
function vec2_set_x(vec, x) {
    gml_pragma("forceinline");
    vec[0] = x;
    return vec;
}

/// @func vec2_set_y(vec, y)
/// @desc Sets the vector's y component.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} y The value to set
/// @returns {Array<Real>} The modified vector
function vec2_set_y(vec, y) {
    gml_pragma("forceinline");
    vec[1] = y;
    return vec;
}

/// @func vec2_set_component(vec, index, value)
/// @desc Allows to set a vector component with an index.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} index The component index (0=x, 1=y)
/// @param {Real} value The value to set
/// @returns {Array<Real>} The modified vector
function vec2_set_component(vec, index, value) {
    gml_pragma("forceinline");
    vec[index] = value;
    return vec;
}

/// @func vec2_get_component(vec, index)
/// @desc Returns the value of the vector component which matches the given index.
/// @param {Array<Real>} vec The vector
/// @param {Real} index The component index (0=x, 1=y)
/// @returns {Real} The component value
function vec2_get_component(vec, index) {
    gml_pragma("forceinline");
    return vec[index];
}

// ============================================================================
// CLONE / COPY
// ============================================================================

/// @func vec2_clone(vec)
/// @desc Returns a new vector with copied values from this instance.
/// @param {Array<Real>} vec The vector to clone
/// @returns {Array<Real>} A clone of the vector
function vec2_clone(vec) {
    gml_pragma("forceinline");
    return [vec[0], vec[1]];
}

/// @func vec2_copy(vec, v)
/// @desc Copies the values of the given vector to this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to copy
/// @returns {Array<Real>} The modified vector
function vec2_copy(vec, v) {
    gml_pragma("forceinline");
    vec[0] = v[0];
    vec[1] = v[1];
    return vec;
}

// ============================================================================
// ADDITION
// ============================================================================

/// @func vec2_add(vec, v)
/// @desc Adds the given vector to this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to add
/// @returns {Array<Real>} The modified vector
function vec2_add(vec, v) {
    gml_pragma("forceinline");
    vec[0] += v[0];
    vec[1] += v[1];
    return vec;
}

/// @func vec2_add_scalar(vec, s)
/// @desc Adds the given scalar value to all components of this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} s The scalar to add
/// @returns {Array<Real>} The modified vector
function vec2_add_scalar(vec, s) {
    gml_pragma("forceinline");
    vec[0] += s;
    vec[1] += s;
    return vec;
}

/// @func vec2_add_scaled_vector(vec, v, s)
/// @desc Adds the given vector scaled by the given factor to this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to scale and add
/// @param {Real} s The factor that scales v
/// @returns {Array<Real>} The modified vector
function vec2_add_scaled_vector(vec, v, s) {
    gml_pragma("forceinline");
    vec[0] += v[0] * s;
    vec[1] += v[1] * s;
    return vec;
}

/// @func vec2_add_vectors(vec, a, b)
/// @desc Adds the given vectors and stores the result in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} a The first vector
/// @param {Array<Real>} b The second vector
/// @returns {Array<Real>} The modified vector
function vec2_add_vectors(vec, a, b) {
    gml_pragma("forceinline");
    vec[0] = a[0] + b[0];
    vec[1] = a[1] + b[1];
    return vec;
}

// ============================================================================
// SUBTRACTION
// ============================================================================

/// @func vec2_sub(vec, v)
/// @desc Subtracts the given vector from this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to subtract
/// @returns {Array<Real>} The modified vector
function vec2_sub(vec, v) {
    gml_pragma("forceinline");
    vec[0] -= v[0];
    vec[1] -= v[1];
    return vec;
}

/// @func vec2_sub_scalar(vec, s)
/// @desc Subtracts the given scalar value from all components of this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} s The scalar to subtract
/// @returns {Array<Real>} The modified vector
function vec2_sub_scalar(vec, s) {
    gml_pragma("forceinline");
    vec[0] -= s;
    vec[1] -= s;
    return vec;
}

/// @func vec2_sub_vectors(vec, a, b)
/// @desc Subtracts the given vectors and stores the result in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} a The first vector
/// @param {Array<Real>} b The second vector
/// @returns {Array<Real>} The modified vector
function vec2_sub_vectors(vec, a, b) {
    gml_pragma("forceinline");
    vec[0] = a[0] - b[0];
    vec[1] = a[1] - b[1];
    return vec;
}

// ============================================================================
// MULTIPLICATION
// ============================================================================

/// @func vec2_multiply(vec, v)
/// @desc Multiplies the given vector with this instance (component-wise).
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to multiply
/// @returns {Array<Real>} The modified vector
function vec2_multiply(vec, v) {
    gml_pragma("forceinline");
    vec[0] *= v[0];
    vec[1] *= v[1];
    return vec;
}

/// @func vec2_multiply_scalar(vec, scalar)
/// @desc Multiplies the given scalar value with all components of this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} scalar The scalar to multiply
/// @returns {Array<Real>} The modified vector
function vec2_multiply_scalar(vec, scalar) {
    gml_pragma("forceinline");
    vec[0] *= scalar;
    vec[1] *= scalar;
    return vec;
}

// ============================================================================
// DIVISION
// ============================================================================

/// @func vec2_divide(vec, v)
/// @desc Divides this instance by the given vector (component-wise).
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to divide by
/// @returns {Array<Real>} The modified vector
function vec2_divide(vec, v) {
    gml_pragma("forceinline");
    vec[0] /= v[0];
    vec[1] /= v[1];
    return vec;
}

/// @func vec2_divide_scalar(vec, scalar)
/// @desc Divides this vector by the given scalar.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} scalar The scalar to divide by
/// @returns {Array<Real>} The modified vector
function vec2_divide_scalar(vec, scalar) {
    gml_pragma("forceinline");
    var inv = 1 / scalar;
    vec[0] *= inv;
    vec[1] *= inv;
    return vec;
}

// ============================================================================
// DOT / CROSS
// ============================================================================

/// @func vec2_dot(vec, v)
/// @desc Calculates the dot product of the given vector with this instance.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute dot product with
/// @returns {Real} The result of the dot product
function vec2_dot(vec, v) {
    gml_pragma("forceinline");
    return vec[0] * v[0] + vec[1] * v[1];
}

/// @func vec2_cross(vec, v)
/// @desc Calculates the cross product of the given vector with this instance (2D pseudo-cross).
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute cross product with
/// @returns {Real} The result of the cross product (scalar in 2D)
function vec2_cross(vec, v) {
    gml_pragma("forceinline");
    return vec[0] * v[1] - vec[1] * v[0];
}

// ============================================================================
// LENGTH
// ============================================================================

/// @func vec2_length(vec)
/// @desc Computes the Euclidean length (straight-line length) from (0, 0) to (x, y).
/// @param {Array<Real>} vec The vector
/// @returns {Real} The length of this vector
function vec2_length(vec) {
    gml_pragma("forceinline");
    return sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
}

/// @func vec2_length_sq(vec)
/// @desc Computes the square of the Euclidean length. More efficient for comparisons.
/// @param {Array<Real>} vec The vector
/// @returns {Real} The square length of this vector
function vec2_length_sq(vec) {
    gml_pragma("forceinline");
    return vec[0] * vec[0] + vec[1] * vec[1];
}

/// @func vec2_manhattan_length(vec)
/// @desc Computes the Manhattan length of this vector.
/// @param {Array<Real>} vec The vector
/// @returns {Real} The Manhattan length
function vec2_manhattan_length(vec) {
    gml_pragma("forceinline");
    return abs(vec[0]) + abs(vec[1]);
}

/// @func vec2_set_length(vec, length)
/// @desc Sets this vector to a vector with the same direction as this one, but with the specified length.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} length The new length
/// @returns {Array<Real>} The modified vector
function vec2_set_length(vec, length) {
    gml_pragma("forceinline");
    var current_len = sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
    if (current_len > 0) {
        var scale = length / current_len;
        vec[0] *= scale;
        vec[1] *= scale;
    }
    return vec;
}

// ============================================================================
// NORMALIZE / NEGATE
// ============================================================================

/// @func vec2_normalize(vec)
/// @desc Converts this vector to a unit vector - sets it equal to a vector with the same direction but length 1.
/// @param {Array<Real>} vec The vector to normalize
/// @returns {Array<Real>} The modified vector
function vec2_normalize(vec) {
    gml_pragma("forceinline");
    var len = sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
    if (len > 0) {
        var inv = 1 / len;
        vec[0] *= inv;
        vec[1] *= inv;
    }
    return vec;
}

/// @func vec2_negate(vec)
/// @desc Inverts this vector - i.e. sets x = -x and y = -y.
/// @param {Array<Real>} vec The vector to negate
/// @returns {Array<Real>} The modified vector
function vec2_negate(vec) {
    gml_pragma("forceinline");
    vec[0] = -vec[0];
    vec[1] = -vec[1];
    return vec;
}

// ============================================================================
// DISTANCE
// ============================================================================

/// @func vec2_distance_to(vec, v)
/// @desc Computes the distance from the given vector to this instance.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute distance to
/// @returns {Real} The distance
function vec2_distance_to(vec, v) {
    gml_pragma("forceinline");
    var dx = vec[0] - v[0];
    var dy = vec[1] - v[1];
    return sqrt(dx * dx + dy * dy);
}

/// @func vec2_distance_to_squared(vec, v)
/// @desc Computes the squared distance from the given vector to this instance. More efficient for comparisons.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute squared distance to
/// @returns {Real} The squared distance
function vec2_distance_to_squared(vec, v) {
    gml_pragma("forceinline");
    var dx = vec[0] - v[0];
    var dy = vec[1] - v[1];
    return dx * dx + dy * dy;
}

/// @func vec2_manhattan_distance_to(vec, v)
/// @desc Computes the Manhattan distance from the given vector to this instance.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute Manhattan distance to
/// @returns {Real} The Manhattan distance
function vec2_manhattan_distance_to(vec, v) {
    gml_pragma("forceinline");
    return abs(vec[0] - v[0]) + abs(vec[1] - v[1]);
}

// ============================================================================
// MIN / MAX / CLAMP
// ============================================================================

/// @func vec2_min(vec, v)
/// @desc If this vector's x or y value is greater than the given vector's x or y value, replace that value with the corresponding min value.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector
/// @returns {Array<Real>} The modified vector
function vec2_min(vec, v) {
    gml_pragma("forceinline");
    vec[0] = min(vec[0], v[0]);
    vec[1] = min(vec[1], v[1]);
    return vec;
}

/// @func vec2_max(vec, v)
/// @desc If this vector's x or y value is less than the given vector's x or y value, replace that value with the corresponding max value.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector
/// @returns {Array<Real>} The modified vector
function vec2_max(vec, v) {
    gml_pragma("forceinline");
    vec[0] = max(vec[0], v[0]);
    vec[1] = max(vec[1], v[1]);
    return vec;
}

/// @func vec2_clamp(vec, min_vec, max_vec)
/// @desc Clamps vec components between min and max vectors.
/// @param {Array<Real>} vec The vector to clamp
/// @param {Array<Real>} min_vec The minimum x and y values
/// @param {Array<Real>} max_vec The maximum x and y values in the desired range
/// @returns {Array<Real>} The modified vector
function vec2_clamp(vec, min_vec, max_vec) {
    gml_pragma("forceinline");
    vec[0] = clamp(vec[0], min_vec[0], max_vec[0]);
    vec[1] = clamp(vec[1], min_vec[1], max_vec[1]);
    return vec;
}

/// @func vec2_clamp_scalar(vec, min_val, max_val)
/// @desc Clamps vec components between scalar min and max values.
/// @param {Array<Real>} vec The vector to clamp
/// @param {Real} min_val The minimum value the components will be clamped to
/// @param {Real} max_val The maximum value the components will be clamped to
/// @returns {Array<Real>} The modified vector
function vec2_clamp_scalar(vec, min_val, max_val) {
    gml_pragma("forceinline");
    vec[0] = clamp(vec[0], min_val, max_val);
    vec[1] = clamp(vec[1], min_val, max_val);
    return vec;
}

/// @func vec2_clamp_length(vec, min_len, max_len)
/// @desc Clamps the vector length between min and max values.
/// @param {Array<Real>} vec The vector to clamp
/// @param {Real} min_len The minimum value the vector length will be clamped to
/// @param {Real} max_len The maximum value the vector length will be clamped to
/// @returns {Array<Real>} The modified vector
function vec2_clamp_length(vec, min_len, max_len) {
    gml_pragma("forceinline");
    var len_sq = vec[0] * vec[0] + vec[1] * vec[1];
    if (len_sq > 0) {
        var len = sqrt(len_sq);
        var new_len = clamp(len, min_len, max_len);
        if (new_len != len) {
            var scale = new_len / len;
            vec[0] *= scale;
            vec[1] *= scale;
        }
    }
    return vec;
}

// ============================================================================
// ROUNDING
// ============================================================================

/// @func vec2_floor(vec)
/// @desc The components of this vector are rounded down to the nearest integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec2_floor(vec) {
    gml_pragma("forceinline");
    vec[0] = floor(vec[0]);
    vec[1] = floor(vec[1]);
    return vec;
}

/// @func vec2_ceil(vec)
/// @desc The components of this vector are rounded up to the nearest integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec2_ceil(vec) {
    gml_pragma("forceinline");
    vec[0] = ceil(vec[0]);
    vec[1] = ceil(vec[1]);
    return vec;
}

/// @func vec2_round(vec)
/// @desc The components of this vector are rounded to the nearest integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec2_round(vec) {
    gml_pragma("forceinline");
    vec[0] = round(vec[0]);
    vec[1] = round(vec[1]);
    return vec;
}

/// @func vec2_round_to_zero(vec)
/// @desc The components of this vector are rounded towards zero (up if negative, down if positive) to an integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec2_round_to_zero(vec) {
    gml_pragma("forceinline");
    vec[0] = (vec[0] < 0) ? ceil(vec[0]) : floor(vec[0]);
    vec[1] = (vec[1] < 0) ? ceil(vec[1]) : floor(vec[1]);
    return vec;
}

// ============================================================================
// EQUALITY
// ============================================================================

/// @func vec2_equals(vec, v)
/// @desc Returns true if this vector is equal with the given one.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to test for equality
/// @returns {Bool} Whether this vector is equal with the given one
function vec2_equals(vec, v) {
    gml_pragma("forceinline");
    return vec[0] == v[0] && vec[1] == v[1];
}

// ============================================================================
// INTERPOLATION
// ============================================================================

/// @func vec2_lerp(vec, v, alpha)
/// @desc Linearly interpolates between the given vector and this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to interpolate towards
/// @param {Real} alpha The interpolation factor, typically in [0, 1]
/// @returns {Array<Real>} The modified vector
function vec2_lerp(vec, v, alpha) {
    gml_pragma("forceinline");
    vec[0] += (v[0] - vec[0]) * alpha;
    vec[1] += (v[1] - vec[1]) * alpha;
    return vec;
}

/// @func vec2_lerp_vectors(vec, v1, v2, alpha)
/// @desc Linearly interpolates between the given vectors. The result is stored in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} v1 The first vector
/// @param {Array<Real>} v2 The second vector
/// @param {Real} alpha The interpolation factor, typically in [0, 1]
/// @returns {Array<Real>} The modified vector
function vec2_lerp_vectors(vec, v1, v2, alpha) {
    gml_pragma("forceinline");
    vec[0] = v1[0] + (v2[0] - v1[0]) * alpha;
    vec[1] = v1[1] + (v2[1] - v1[1]) * alpha;
    return vec;
}

// ============================================================================
// ANGLE
// ============================================================================

/// @func vec2_angle(vec)
/// @desc Computes the angle in degrees of this vector with respect to the positive x-axis.
/// @param {Array<Real>} vec The vector
/// @returns {Real} The angle in degrees
function vec2_angle(vec) {
    gml_pragma("forceinline");
    // Negate Y for mathematical convention (Y up = 90°)
    return point_direction(0, 0, vec[0], -vec[1]);
}

/// @func vec2_angle_to(vec, v)
/// @desc Returns the angle between the given vector and this instance in degrees.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute the angle with
/// @returns {Real} The angle in degrees
function vec2_angle_to(vec, v) {
    gml_pragma("forceinline");
    var _dot = vec[0] * v[0] + vec[1] * v[1];
    var _len1 = sqrt(vec[0] * vec[0] + vec[1] * vec[1]);
    var _len2 = sqrt(v[0] * v[0] + v[1] * v[1]);
    var _denom = _len1 * _len2;
    if (_denom == 0) return 0;

    var cos_theta = clamp(_dot / _denom, -1, 1);
    return darccos(cos_theta);
}

// ============================================================================
// ROTATION
// ============================================================================

/// @func vec2_rotate_around(vec, center, angle)
/// @desc Rotates this vector around the given center by the given angle.
/// @param {Array<Real>} vec The vector to rotate
/// @param {Array<Real>} center The point around which to rotate
/// @param {Real} angle The angle to rotate, in degrees
/// @returns {Array<Real>} The modified vector
function vec2_rotate_around(vec, center, angle) {
    gml_pragma("forceinline");
    var cosA = dcos(angle);
    var sinA = dsin(angle);
    var dx = vec[0] - center[0];
    var dy = vec[1] - center[1];
    vec[0] = center[0] + dx * cosA - dy * sinA;
    vec[1] = center[1] + dx * sinA + dy * cosA;
    return vec;
}

// ============================================================================
// RANDOM
// ============================================================================

/// @func vec2_random(vec)
/// @desc Sets each component of this vector to a pseudo-random value between 0 and 1, excluding 1.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec2_random(vec) {
    gml_pragma("forceinline");
    vec[0] = random(1);
    vec[1] = random(1);
    return vec;
}

// ============================================================================
// ARRAY CONVERSION
// ============================================================================

/// @func vec2_from_array(vec, array, offset)
/// @desc Sets this vector's x value to be array[offset] and y value to be array[offset + 1].
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} array An array holding the vector component values
/// @param {Real} [offset=0] The offset into the array
/// @returns {Array<Real>} The modified vector
function vec2_from_array(vec, array, offset = 0) {
    gml_pragma("forceinline");
    vec[0] = array[offset];
    vec[1] = array[offset + 1];
    return vec;
}

/// @func vec2_to_array(vec, array, offset)
/// @desc Copies vec2 components into an array at the given offset.
/// @param {Array<Real>} vec The source vector
/// @param {Array<Real>} [array] Target array (creates new if undefined)
/// @param {Real} [offset=0] Start index
/// @returns {Array<Real>} The target array
function vec2_to_array(vec, array = undefined, offset = 0) {
    gml_pragma("forceinline");
    array ??= array_create(2);
    array[offset] = vec[0];
    array[offset + 1] = vec[1];
    return array;
}

/// @func vec2_from_buffer_attribute(vec, attribute, index)
/// @desc Sets the components of this vector from the given buffer attribute.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} attribute The buffer attribute holding vector data (flat array [x0,y0,x1,y1,...])
/// @param {Real} index The index into the attribute (vertex index, not array index)
/// @returns {Array<Real>} The modified vector
function vec2_from_buffer_attribute(vec, attribute, index) {
    gml_pragma("forceinline");
    var offset = index * 2;
    vec[0] = attribute[offset];
    vec[1] = attribute[offset + 1];
    return vec;
}

// ============================================================================
// MATRIX TRANSFORMATION
// ============================================================================

/// @func vec2_apply_matrix3(vec, m)
/// @desc Multiplies this vector (with an implicit 1 as the 3rd component) by the given 3x3 matrix.
/// @param {Array<Real>} vec The vector to transform
/// @param {Array<Real>} m The 3x3 matrix (9 elements, column-major)
/// @returns {Array<Real>} The modified vector
function vec2_apply_matrix3(vec, m) {
    gml_pragma("forceinline");
    var _x = vec[0];
    var _y = vec[1];
    vec[0] = m[0] * _x + m[3] * _y + m[6];
    vec[1] = m[1] * _x + m[4] * _y + m[7];
    return vec;
}

// ============================================================================
// EXTRA UTILITY
// ============================================================================

/// @func vec2_abs(vec)
/// @desc Sets both components to their absolute values.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec2_abs(vec) {
    gml_pragma("forceinline");
    vec[0] = abs(vec[0]);
    vec[1] = abs(vec[1]);
    return vec;
}

/// @func vec2_reflect(vec, normal)
/// @desc Reflects vec across a normal vector.
/// @param {Array<Real>} vec The vector to reflect
/// @param {Array<Real>} normal The normal vector (should be normalized)
/// @returns {Array<Real>} The modified vector
function vec2_reflect(vec, normal) {
    gml_pragma("forceinline");
    var dot2 = 2 * (vec[0] * normal[0] + vec[1] * normal[1]);
    vec[0] -= dot2 * normal[0];
    vec[1] -= dot2 * normal[1];
    return vec;
}

/// @func vec2_project(vec, onto)
/// @desc Projects vec onto another vector.
/// @param {Array<Real>} vec The vector to project
/// @param {Array<Real>} onto The vector to project onto
/// @returns {Array<Real>} The modified vector
function vec2_project(vec, onto) {
    gml_pragma("forceinline");
    var dot_ab = vec[0] * onto[0] + vec[1] * onto[1];
    var dot_bb = onto[0] * onto[0] + onto[1] * onto[1];
    if (dot_bb == 0) {
        vec[0] = 0;
        vec[1] = 0;
        return vec;
    }
    var scalar = dot_ab / dot_bb;
    vec[0] = onto[0] * scalar;
    vec[1] = onto[1] * scalar;
    return vec;
}

/// @func vec2_perp(vec)
/// @desc Sets vec to its perpendicular (rotated 90 degrees CCW).
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec2_perp(vec) {
    gml_pragma("forceinline");
    var temp = vec[0];
    vec[0] = -vec[1];
    vec[1] = temp;
    return vec;
}
