/// @desc 3D vector functions using arrays [x, y, z]
/// All angles are in DEGREES.
/// All functions modify the first vector in-place when applicable for zero allocations.

// Global temp vectors in order to avoid allocations
global.UE_VEC3_TEMP0 = vec3_create();
global.UE_VEC3_TEMP1 = vec3_create();
global.UE_VEC3_TEMP2 = vec3_create();
global.UE_VEC3_TEMP3 = vec3_create();

// Vector3 Enum
enum VEC3 {
  x, y, z
}

/// @func vec3_create(x, y, z)
/// @desc Creates a new vec3 array with the given components.
/// @param {Real} [x=0] X component
/// @param {Real} [y=0] Y component
/// @param {Real} [z=0] Z component
/// @returns {Array<Real>} New vec3 array
function vec3_create(x = 0, y = 0, z = 0) {
    gml_pragma("forceinline");
    return [x, y, z];
}

// ============================================================================
// SETTERS
// ============================================================================

/// @func vec3_set(vec, x, y, z)
/// @desc Sets the vector components.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} x The value of the x component
/// @param {Real} y The value of the y component
/// @param {Real} z The value of the z component
/// @returns {Array<Real>} The modified vector
function vec3_set(vec, x, y, z) {
    gml_pragma("forceinline");
    vec[0] = x;
    vec[1] = y;
    vec[2] = z;
    return vec;
}

/// @func vec3_set_scalar(vec, scalar)
/// @desc Sets the vector components to the same value.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} scalar The value to set for all components
/// @returns {Array<Real>} The modified vector
function vec3_set_scalar(vec, scalar) {
    gml_pragma("forceinline");
    vec[0] = scalar;
    vec[1] = scalar;
    vec[2] = scalar;
    return vec;
}

/// @func vec3_set_x(vec, x)
/// @desc Sets the vector's x component.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} x The value to set
/// @returns {Array<Real>} The modified vector
function vec3_set_x(vec, x) {
    gml_pragma("forceinline");
    vec[0] = x;
    return vec;
}

/// @func vec3_set_y(vec, y)
/// @desc Sets the vector's y component.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} y The value to set
/// @returns {Array<Real>} The modified vector
function vec3_set_y(vec, y) {
    gml_pragma("forceinline");
    vec[1] = y;
    return vec;
}

/// @func vec3_set_z(vec, z)
/// @desc Sets the vector's z component.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} z The value to set
/// @returns {Array<Real>} The modified vector
function vec3_set_z(vec, z) {
    gml_pragma("forceinline");
    vec[2] = z;
    return vec;
}

/// @func vec3_set_component(vec, index, value)
/// @desc Allows to set a vector component with an index.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} index The component index (0=x, 1=y, 2=z)
/// @param {Real} value The value to set
/// @returns {Array<Real>} The modified vector
function vec3_set_component(vec, index, value) {
    gml_pragma("forceinline");
    vec[index] = value;
    return vec;
}

/// @func vec3_get_component(vec, index)
/// @desc Returns the value of the vector component which matches the given index.
/// @param {Array<Real>} vec The vector
/// @param {Real} index The component index (0=x, 1=y, 2=z)
/// @returns {Real} The component value
function vec3_get_component(vec, index) {
    gml_pragma("forceinline");
    return vec[index];
}

// ============================================================================
// CLONE / COPY
// ============================================================================

/// @func vec3_clone(vec)
/// @desc Returns a new vector with copied values from this instance.
/// @param {Array<Real>} vec The vector to clone
/// @returns {Array<Real>} A clone of the vector
function vec3_clone(vec) {
    gml_pragma("forceinline");
    return [vec[0], vec[1], vec[2]];
}

/// @func vec3_copy(vec, v)
/// @desc Copies the values of the given vector to this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to copy
/// @returns {Array<Real>} The modified vector
function vec3_copy(vec, v) {
    gml_pragma("forceinline");
    vec[0] = v[0];
    vec[1] = v[1];
    vec[2] = v[2];
    return vec;
}

// ============================================================================
// ADDITION
// ============================================================================

/// @func vec3_add(vec, v)
/// @desc Adds the given vector to this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to add
/// @returns {Array<Real>} The modified vector
function vec3_add(vec, v) {
    gml_pragma("forceinline");
    vec[0] += v[0];
    vec[1] += v[1];
    vec[2] += v[2];
    return vec;
}

/// @func vec3_add_scalar(vec, s)
/// @desc Adds the given scalar value to all components of this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} s The scalar to add
/// @returns {Array<Real>} The modified vector
function vec3_add_scalar(vec, s) {
    gml_pragma("forceinline");
    vec[0] += s;
    vec[1] += s;
    vec[2] += s;
    return vec;
}

/// @func vec3_add_scaled_vector(vec, v, s)
/// @desc Adds the given vector scaled by the given factor to this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to scale and add
/// @param {Real} s The factor that scales v
/// @returns {Array<Real>} The modified vector
function vec3_add_scaled_vector(vec, v, s) {
    gml_pragma("forceinline");
    vec[0] += v[0] * s;
    vec[1] += v[1] * s;
    vec[2] += v[2] * s;
    return vec;
}

/// @func vec3_add_vectors(vec, a, b)
/// @desc Adds the given vectors and stores the result in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} a The first vector
/// @param {Array<Real>} b The second vector
/// @returns {Array<Real>} The modified vector
function vec3_add_vectors(vec, a, b) {
    gml_pragma("forceinline");
    vec[0] = a[0] + b[0];
    vec[1] = a[1] + b[1];
    vec[2] = a[2] + b[2];
    return vec;
}

// ============================================================================
// SUBTRACTION
// ============================================================================

/// @func vec3_sub(vec, v)
/// @desc Subtracts the given vector from this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to subtract
/// @returns {Array<Real>} The modified vector
function vec3_sub(vec, v) {
    gml_pragma("forceinline");
    vec[0] -= v[0];
    vec[1] -= v[1];
    vec[2] -= v[2];
    return vec;
}

/// @func vec3_sub_scalar(vec, s)
/// @desc Subtracts the given scalar value from all components of this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} s The scalar to subtract
/// @returns {Array<Real>} The modified vector
function vec3_sub_scalar(vec, s) {
    gml_pragma("forceinline");
    vec[0] -= s;
    vec[1] -= s;
    vec[2] -= s;
    return vec;
}

/// @func vec3_sub_vectors(vec, a, b)
/// @desc Subtracts the given vectors and stores the result in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} a The first vector
/// @param {Array<Real>} b The second vector
/// @returns {Array<Real>} The modified vector
function vec3_sub_vectors(vec, a, b) {
    gml_pragma("forceinline");
    vec[0] = a[0] - b[0];
    vec[1] = a[1] - b[1];
    vec[2] = a[2] - b[2];
    return vec;
}

// ============================================================================
// MULTIPLICATION
// ============================================================================

/// @func vec3_multiply(vec, v)
/// @desc Multiplies the given vector with this instance (component-wise).
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to multiply
/// @returns {Array<Real>} The modified vector
function vec3_multiply(vec, v) {
    gml_pragma("forceinline");
    vec[0] *= v[0];
    vec[1] *= v[1];
    vec[2] *= v[2];
    return vec;
}

/// @func vec3_multiply_scalar(vec, scalar)
/// @desc Multiplies the given scalar value with all components of this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} scalar The scalar to multiply
/// @returns {Array<Real>} The modified vector
function vec3_multiply_scalar(vec, scalar) {
    gml_pragma("forceinline");
    vec[0] *= scalar;
    vec[1] *= scalar;
    vec[2] *= scalar;
    return vec;
}

/// @func vec3_multiply_vectors(vec, a, b)
/// @desc Multiplies the given vectors and stores the result in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} a The first vector
/// @param {Array<Real>} b The second vector
/// @returns {Array<Real>} The modified vector
function vec3_multiply_vectors(vec, a, b) {
    gml_pragma("forceinline");
    vec[0] = a[0] * b[0];
    vec[1] = a[1] * b[1];
    vec[2] = a[2] * b[2];
    return vec;
}

// ============================================================================
// DIVISION
// ============================================================================

/// @func vec3_divide(vec, v)
/// @desc Divides this instance by the given vector (component-wise).
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to divide by
/// @returns {Array<Real>} The modified vector
function vec3_divide(vec, v) {
    gml_pragma("forceinline");
    vec[0] /= v[0];
    vec[1] /= v[1];
    vec[2] /= v[2];
    return vec;
}

/// @func vec3_divide_scalar(vec, scalar)
/// @desc Divides this vector by the given scalar.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} scalar The scalar to divide by
/// @returns {Array<Real>} The modified vector
function vec3_divide_scalar(vec, scalar) {
    gml_pragma("forceinline");
    var inv = 1 / scalar;
    vec[0] *= inv;
    vec[1] *= inv;
    vec[2] *= inv;
    return vec;
}

// ============================================================================
// DOT / CROSS
// ============================================================================

/// @func vec3_dot(vec, v)
/// @desc Calculates the dot product of the given vector with this instance.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute dot product with
/// @returns {Real} The result of the dot product
function vec3_dot(vec, v) {
    gml_pragma("forceinline");
    return vec[0] * v[0] + vec[1] * v[1] + vec[2] * v[2];
}

/// @func vec3_cross(vec, v)
/// @desc Calculates the cross product of the given vector with this instance. Modifies vec in-place.
/// @param {Array<Real>} vec The vector to modify (stores result)
/// @param {Array<Real>} v The vector to compute cross product with
/// @returns {Array<Real>} The modified vector
function vec3_cross(vec, v) {
    gml_pragma("forceinline");
    var ax = vec[0], ay = vec[1], az = vec[2];
    var bx = v[0], by = v[1], bz = v[2];
    vec[0] = ay * bz - az * by;
    vec[1] = az * bx - ax * bz;
    vec[2] = ax * by - ay * bx;
    return vec;
}

/// @func vec3_cross_vectors(vec, a, b)
/// @desc Calculates the cross product of the given vectors and stores the result in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} a The first vector
/// @param {Array<Real>} b The second vector
/// @returns {Array<Real>} The modified vector
function vec3_cross_vectors(vec, a, b) {
    gml_pragma("forceinline");
    vec[0] = a[1] * b[2] - a[2] * b[1];
    vec[1] = a[2] * b[0] - a[0] * b[2];
    vec[2] = a[0] * b[1] - a[1] * b[0];
    return vec;
}

// ============================================================================
// LENGTH
// ============================================================================

/// @func vec3_length(vec)
/// @desc Computes the Euclidean length (straight-line length) from (0, 0, 0) to (x, y, z).
/// @param {Array<Real>} vec The vector
/// @returns {Real} The length of this vector
function vec3_length(vec) {
    gml_pragma("forceinline");
    return sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
}

/// @func vec3_length_sq(vec)
/// @desc Computes the square of the Euclidean length. More efficient for comparisons.
/// @param {Array<Real>} vec The vector
/// @returns {Real} The square length of this vector
function vec3_length_sq(vec) {
    gml_pragma("forceinline");
    return vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2];
}

/// @func vec3_manhattan_length(vec)
/// @desc Computes the Manhattan length of this vector.
/// @param {Array<Real>} vec The vector
/// @returns {Real} The Manhattan length
function vec3_manhattan_length(vec) {
    gml_pragma("forceinline");
    return abs(vec[0]) + abs(vec[1]) + abs(vec[2]);
}

/// @func vec3_set_length(vec, length)
/// @desc Sets this vector to a vector with the same direction as this one, but with the specified length.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} length The new length
/// @returns {Array<Real>} The modified vector
function vec3_set_length(vec, length) {
    gml_pragma("forceinline");
    var current_len = sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
    if (current_len > 0) {
        var scale = length / current_len;
        vec[0] *= scale;
        vec[1] *= scale;
        vec[2] *= scale;
    }
    return vec;
}

// ============================================================================
// NORMALIZE / NEGATE
// ============================================================================

/// @func vec3_normalize(vec)
/// @desc Converts this vector to a unit vector - sets it equal to a vector with the same direction but length 1.
/// @param {Array<Real>} vec The vector to normalize
/// @returns {Array<Real>} The modified vector
function vec3_normalize(vec) {
    gml_pragma("forceinline");
    var len = sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
    if (len > 0) {
        var inv = 1 / len;
        vec[0] *= inv;
        vec[1] *= inv;
        vec[2] *= inv;
    }
    return vec;
}

/// @func vec3_negate(vec)
/// @desc Inverts this vector - i.e. sets x = -x, y = -y and z = -z.
/// @param {Array<Real>} vec The vector to negate
/// @returns {Array<Real>} The modified vector
function vec3_negate(vec) {
    gml_pragma("forceinline");
    vec[0] = -vec[0];
    vec[1] = -vec[1];
    vec[2] = -vec[2];
    return vec;
}

// ============================================================================
// DISTANCE
// ============================================================================

/// @func vec3_distance_to(vec, v)
/// @desc Computes the distance from the given vector to this instance.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute distance to
/// @returns {Real} The distance
function vec3_distance_to(vec, v) {
    gml_pragma("forceinline");
    var dx = vec[0] - v[0];
    var dy = vec[1] - v[1];
    var dz = vec[2] - v[2];
    return sqrt(dx * dx + dy * dy + dz * dz);
}

/// @func vec3_distance_to_squared(vec, v)
/// @desc Computes the squared distance from the given vector to this instance. More efficient for comparisons.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute squared distance to
/// @returns {Real} The squared distance
function vec3_distance_to_squared(vec, v) {
    gml_pragma("forceinline");
    var dx = vec[0] - v[0];
    var dy = vec[1] - v[1];
    var dz = vec[2] - v[2];
    return dx * dx + dy * dy + dz * dz;
}

/// @func vec3_manhattan_distance_to(vec, v)
/// @desc Computes the Manhattan distance from the given vector to this instance.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute Manhattan distance to
/// @returns {Real} The Manhattan distance
function vec3_manhattan_distance_to(vec, v) {
    gml_pragma("forceinline");
    return abs(vec[0] - v[0]) + abs(vec[1] - v[1]) + abs(vec[2] - v[2]);
}

// ============================================================================
// MIN / MAX / CLAMP
// ============================================================================

/// @func vec3_min(vec, v)
/// @desc If this vector's x, y or z value is greater than the given vector's value, replace with the min.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector
/// @returns {Array<Real>} The modified vector
function vec3_min(vec, v) {
    gml_pragma("forceinline");
    vec[0] = min(vec[0], v[0]);
    vec[1] = min(vec[1], v[1]);
    vec[2] = min(vec[2], v[2]);
    return vec;
}

/// @func vec3_max(vec, v)
/// @desc If this vector's x, y or z value is less than the given vector's value, replace with the max.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector
/// @returns {Array<Real>} The modified vector
function vec3_max(vec, v) {
    gml_pragma("forceinline");
    vec[0] = max(vec[0], v[0]);
    vec[1] = max(vec[1], v[1]);
    vec[2] = max(vec[2], v[2]);
    return vec;
}

/// @func vec3_clamp(vec, min_vec, max_vec)
/// @desc Clamps vec components between min and max vectors.
/// @param {Array<Real>} vec The vector to clamp
/// @param {Array<Real>} min_vec The minimum x, y and z values
/// @param {Array<Real>} max_vec The maximum x, y and z values in the desired range
/// @returns {Array<Real>} The modified vector
function vec3_clamp(vec, min_vec, max_vec) {
    gml_pragma("forceinline");
    vec[0] = clamp(vec[0], min_vec[0], max_vec[0]);
    vec[1] = clamp(vec[1], min_vec[1], max_vec[1]);
    vec[2] = clamp(vec[2], min_vec[2], max_vec[2]);
    return vec;
}

/// @func vec3_clamp_scalar(vec, min_val, max_val)
/// @desc Clamps vec components between scalar min and max values.
/// @param {Array<Real>} vec The vector to clamp
/// @param {Real} min_val The minimum value the components will be clamped to
/// @param {Real} max_val The maximum value the components will be clamped to
/// @returns {Array<Real>} The modified vector
function vec3_clamp_scalar(vec, min_val, max_val) {
    gml_pragma("forceinline");
    vec[0] = clamp(vec[0], min_val, max_val);
    vec[1] = clamp(vec[1], min_val, max_val);
    vec[2] = clamp(vec[2], min_val, max_val);
    return vec;
}

/// @func vec3_clamp_length(vec, min_len, max_len)
/// @desc Clamps the vector length between min and max values.
/// @param {Array<Real>} vec The vector to clamp
/// @param {Real} min_len The minimum value the vector length will be clamped to
/// @param {Real} max_len The maximum value the vector length will be clamped to
/// @returns {Array<Real>} The modified vector
function vec3_clamp_length(vec, min_len, max_len) {
    gml_pragma("forceinline");
    var len_sq = vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2];
    if (len_sq > 0) {
        var len = sqrt(len_sq);
        var new_len = clamp(len, min_len, max_len);
        if (new_len != len) {
            var scale = new_len / len;
            vec[0] *= scale;
            vec[1] *= scale;
            vec[2] *= scale;
        }
    }
    return vec;
}

// ============================================================================
// ROUNDING
// ============================================================================

/// @func vec3_floor(vec)
/// @desc The components of this vector are rounded down to the nearest integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec3_floor(vec) {
    gml_pragma("forceinline");
    vec[0] = floor(vec[0]);
    vec[1] = floor(vec[1]);
    vec[2] = floor(vec[2]);
    return vec;
}

/// @func vec3_ceil(vec)
/// @desc The components of this vector are rounded up to the nearest integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec3_ceil(vec) {
    gml_pragma("forceinline");
    vec[0] = ceil(vec[0]);
    vec[1] = ceil(vec[1]);
    vec[2] = ceil(vec[2]);
    return vec;
}

/// @func vec3_round(vec)
/// @desc The components of this vector are rounded to the nearest integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec3_round(vec) {
    gml_pragma("forceinline");
    vec[0] = round(vec[0]);
    vec[1] = round(vec[1]);
    vec[2] = round(vec[2]);
    return vec;
}

/// @func vec3_round_to_zero(vec)
/// @desc The components of this vector are rounded towards zero (up if negative, down if positive) to an integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec3_round_to_zero(vec) {
    gml_pragma("forceinline");
    vec[0] = (vec[0] < 0) ? ceil(vec[0]) : floor(vec[0]);
    vec[1] = (vec[1] < 0) ? ceil(vec[1]) : floor(vec[1]);
    vec[2] = (vec[2] < 0) ? ceil(vec[2]) : floor(vec[2]);
    return vec;
}

// ============================================================================
// EQUALITY
// ============================================================================

/// @func vec3_equals(vec, v)
/// @desc Returns true if this vector is equal with the given one.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to test for equality
/// @returns {Bool} Whether this vector is equal with the given one
function vec3_equals(vec, v) {
    gml_pragma("forceinline");
    return vec[0] == v[0] && vec[1] == v[1] && vec[2] == v[2];
}

// ============================================================================
// INTERPOLATION
// ============================================================================

/// @func vec3_lerp(vec, v, alpha)
/// @desc Linearly interpolates between the given vector and this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to interpolate towards
/// @param {Real} alpha The interpolation factor, typically in [0, 1]
/// @returns {Array<Real>} The modified vector
function vec3_lerp(vec, v, alpha) {
    gml_pragma("forceinline");
    vec[0] += (v[0] - vec[0]) * alpha;
    vec[1] += (v[1] - vec[1]) * alpha;
    vec[2] += (v[2] - vec[2]) * alpha;
    return vec;
}

/// @func vec3_lerp_vectors(vec, v1, v2, alpha)
/// @desc Linearly interpolates between the given vectors. The result is stored in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} v1 The first vector
/// @param {Array<Real>} v2 The second vector
/// @param {Real} alpha The interpolation factor, typically in [0, 1]
/// @returns {Array<Real>} The modified vector
function vec3_lerp_vectors(vec, v1, v2, alpha) {
    gml_pragma("forceinline");
    vec[0] = v1[0] + (v2[0] - v1[0]) * alpha;
    vec[1] = v1[1] + (v2[1] - v1[1]) * alpha;
    vec[2] = v1[2] + (v2[2] - v1[2]) * alpha;
    return vec;
}

// ============================================================================
// ANGLE (in DEGREES)
// ============================================================================

/// @func vec3_angle_to(vec, v)
/// @desc Returns the angle between the given vector and this instance in degrees.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute the angle with
/// @returns {Real} The angle in degrees
function vec3_angle_to(vec, v) {
    gml_pragma("forceinline");
    var _dot = vec[0] * v[0] + vec[1] * v[1] + vec[2] * v[2];
    var _len1 = sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]);
    var _len2 = sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2]);
    var _denom = _len1 * _len2;
    if (_denom == 0) return 0;

    var cos_theta = clamp(_dot / _denom, -1, 1);
    return darccos(cos_theta);
}

// ============================================================================
// ROTATION (in DEGREES)
// ============================================================================

/// @func vec3_apply_axis_angle(vec, axis, angle)
/// @desc Applies a rotation specified by an axis and an angle to this vector.
/// @param {Array<Real>} vec The vector to rotate
/// @param {Array<Real>} axis A normalized vector representing the rotation axis
/// @param {Real} angle The angle in degrees
/// @returns {Array<Real>} The modified vector
function vec3_apply_axis_angle(vec, axis, angle) {
    gml_pragma("forceinline");
    var xx = vec[0], yy = vec[1], zz = vec[2];
    var ax = axis[0], ay = axis[1], az = axis[2];

    var cosA = dcos(angle);
    var sinA = dsin(angle);
    var t = 1 - cosA;

    // Rodrigues' rotation formula
    vec[0] = (t * ax * ax + cosA) * xx + (t * ax * ay - sinA * az) * yy + (t * ax * az + sinA * ay) * zz;
    vec[1] = (t * ax * ay + sinA * az) * xx + (t * ay * ay + cosA) * yy + (t * ay * az - sinA * ax) * zz;
    vec[2] = (t * ax * az - sinA * ay) * xx + (t * ay * az + sinA * ax) * yy + (t * az * az + cosA) * zz;
    return vec;
}

/// @func vec3_apply_quaternion(vec, q)
/// @desc Applies the given quaternion (array [x, y, z, w]) to this vector.
/// @param {Array<Real>} vec The vector to transform
/// @param {Array<Real>} q The quaternion [x, y, z, w]
/// @returns {Array<Real>} The modified vector
function vec3_apply_quaternion(vec, q) {
    gml_pragma("forceinline");
    var xx = vec[0], yy = vec[1], zz = vec[2];
    var qx = q[0], qy = q[1], qz = q[2], qw = q[3];

    var ix = qw * xx + qy * zz - qz * yy;
    var iy = qw * yy + qz * xx - qx * zz;
    var iz = qw * zz + qx * yy - qy * xx;
    var iw = -qx * xx - qy * yy - qz * zz;

    vec[0] = ix * qw + iw * -qx + iy * -qz - iz * -qy;
    vec[1] = iy * qw + iw * -qy + iz * -qx - ix * -qz;
    vec[2] = iz * qw + iw * -qz + ix * -qy - iy * -qx;
    return vec;
}

// ============================================================================
// RANDOM
// ============================================================================

/// @func vec3_random(vec)
/// @desc Sets each component of this vector to a pseudo-random value between 0 and 1, excluding 1.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec3_random(vec) {
    gml_pragma("forceinline");
    vec[0] = random(1);
    vec[1] = random(1);
    vec[2] = random(1);
    return vec;
}

/// @func vec3_random_direction(vec)
/// @desc Sets this vector to a uniformly random point on a unit sphere.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec3_random_direction(vec) {
    gml_pragma("forceinline");
    var theta = random(2 * pi);
    var phi = arccos(random_range(-1, 1));
    var sinPhi = sin(phi);
    vec[0] = sinPhi * cos(theta);
    vec[1] = sinPhi * sin(theta);
    vec[2] = cos(phi);
    return vec;
}

// ============================================================================
// PROJECTION / REFLECTION
// ============================================================================

/// @func vec3_project_on_vector(vec, v)
/// @desc Projects this vector onto the given one.
/// @param {Array<Real>} vec The vector to project
/// @param {Array<Real>} v The vector to project onto
/// @returns {Array<Real>} The modified vector
function vec3_project_on_vector(vec, v) {
    gml_pragma("forceinline");
    var dot_ab = vec[0] * v[0] + vec[1] * v[1] + vec[2] * v[2];
    var dot_bb = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
    if (dot_bb == 0) {
        vec[0] = 0;
        vec[1] = 0;
        vec[2] = 0;
        return vec;
    }
    var scalar = dot_ab / dot_bb;
    vec[0] = v[0] * scalar;
    vec[1] = v[1] * scalar;
    vec[2] = v[2] * scalar;
    return vec;
}

/// @func vec3_project_on_plane(vec, plane_normal)
/// @desc Projects this vector onto a plane by subtracting this vector projected onto the plane's normal.
/// @param {Array<Real>} vec The vector to project
/// @param {Array<Real>} plane_normal The plane normal
/// @returns {Array<Real>} The modified vector
function vec3_project_on_plane(vec, plane_normal) {
    gml_pragma("forceinline");
    var dot = vec[0] * plane_normal[0] + vec[1] * plane_normal[1] + vec[2] * plane_normal[2];
    vec[0] -= plane_normal[0] * dot;
    vec[1] -= plane_normal[1] * dot;
    vec[2] -= plane_normal[2] * dot;
    return vec;
}

/// @func vec3_reflect(vec, normal)
/// @desc Reflects this vector off a plane orthogonal to the given normal vector.
/// @param {Array<Real>} vec The vector to reflect
/// @param {Array<Real>} normal The (normalized) normal vector
/// @returns {Array<Real>} The modified vector
function vec3_reflect(vec, normal) {
    gml_pragma("forceinline");
    var dot2 = 2 * (vec[0] * normal[0] + vec[1] * normal[1] + vec[2] * normal[2]);
    vec[0] -= dot2 * normal[0];
    vec[1] -= dot2 * normal[1];
    vec[2] -= dot2 * normal[2];
    return vec;
}

// ============================================================================
// ARRAY CONVERSION
// ============================================================================

/// @func vec3_from_array(vec, array, offset)
/// @desc Sets this vector's x, y, z values from the array.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} array An array holding the vector component values
/// @param {Real} [offset=0] The offset into the array
/// @returns {Array<Real>} The modified vector
function vec3_from_array(vec, array, offset = 0) {
    gml_pragma("forceinline");
    vec[0] = array[offset];
    vec[1] = array[offset + 1];
    vec[2] = array[offset + 2];
    return vec;
}

/// @func vec3_to_array(vec, array, offset)
/// @desc Copies vec3 components into an array at the given offset.
/// @param {Array<Real>} vec The source vector
/// @param {Array<Real>} [array] Target array (creates new if undefined)
/// @param {Real} [offset=0] Start index
/// @returns {Array<Real>} The target array
function vec3_to_array(vec, array = undefined, offset = 0) {
    gml_pragma("forceinline");
    array ??= array_create(3);
    array[offset] = vec[0];
    array[offset + 1] = vec[1];
    array[offset + 2] = vec[2];
    return array;
}

/// @func vec3_from_buffer_attribute(vec, attribute, index)
/// @desc Sets the components of this vector from the given buffer attribute.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} attribute The buffer attribute holding vector data (flat array [x0,y0,z0,x1,y1,z1,...])
/// @param {Real} index The index into the attribute (vertex index, not array index)
/// @returns {Array<Real>} The modified vector
function vec3_from_buffer_attribute(vec, attribute, index) {
    gml_pragma("forceinline");
    var offset = index * 3;
    vec[0] = attribute[offset];
    vec[1] = attribute[offset + 1];
    vec[2] = attribute[offset + 2];
    return vec;
}

// ============================================================================
// MATRIX TRANSFORMATION
// ============================================================================

/// @func vec3_apply_matrix3(vec, m)
/// @desc Multiplies this vector with the given 3x3 matrix.
/// @param {Array<Real>} vec The vector to transform
/// @param {Array<Real>} m The 3x3 matrix (9 elements, column-major)
/// @returns {Array<Real>} The modified vector
function vec3_apply_matrix3(vec, m) {
    gml_pragma("forceinline");
    var _x = vec[0], _y = vec[1], _z = vec[2];
    vec[0] = m[0] * _x + m[3] * _y + m[6] * _z;
    vec[1] = m[1] * _x + m[4] * _y + m[7] * _z;
    vec[2] = m[2] * _x + m[5] * _y + m[8] * _z;
    return vec;
}

/// @func vec3_apply_matrix4(vec, m)
/// @desc Multiplies this vector (with an implicit 1 in the 4th dimension) by m, and divides by perspective.
/// @param {Array<Real>} vec The vector to transform
/// @param {Array<Real>} m The 4x4 matrix (16 elements, column-major)
/// @returns {Array<Real>} The modified vector
function vec3_apply_matrix4(vec, m) {
    gml_pragma("forceinline");
    var _x = vec[0], _y = vec[1], _z = vec[2];

    var w = m[3] * _x + m[7] * _y + m[11] * _z + m[15];
    w = (w != 0) ? (1 / w) : 1;
    vec[0] = (m[0] * _x + m[4] * _y + m[8] * _z + m[12]) * w;
    vec[1] = (m[1] * _x + m[5] * _y + m[9] * _z + m[13]) * w;
    vec[2] = (m[2] * _x + m[6] * _y + m[10] * _z + m[14]) * w;
    return vec;
}

/// @func vec3_apply_normal_matrix(vec, m)
/// @desc Multiplies this vector by the given normal matrix and normalizes the result.
/// @param {Array<Real>} vec The vector to transform
/// @param {Array<Real>} m The 3x3 normal matrix
/// @returns {Array<Real>} The modified vector
function vec3_apply_normal_matrix(vec, m) {
    gml_pragma("forceinline");
    vec3_apply_matrix3(vec, m);
    vec3_normalize(vec);
    return vec;
}

/// @func vec3_transform_direction(vec, m)
/// @desc Transforms the direction of this vector by a matrix (the upper left 3x3 subset of the given 4x4 matrix) and then normalizes the result.
/// @param {Array<Real>} vec The vector to transform
/// @param {Array<Real>} m The 4x4 matrix
/// @returns {Array<Real>} The modified vector
function vec3_transform_direction(vec, m) {
    gml_pragma("forceinline");
    var _x = vec[0], _y = vec[1], _z = vec[2];
    vec[0] = m[0] * _x + m[4] * _y + m[8] * _z;
    vec[1] = m[1] * _x + m[5] * _y + m[9] * _z;
    vec[2] = m[2] * _x + m[6] * _y + m[10] * _z;
    vec3_normalize(vec);
    return vec;
}

// ============================================================================
// MATRIX EXTRACTION
// ============================================================================

/// @func vec3_set_from_matrix_column(vec, m, index)
/// @desc Sets the vector components from the specified 4x4 matrix column.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} m The 4x4 matrix
/// @param {Real} index The column index
/// @returns {Array<Real>} The modified vector
function vec3_set_from_matrix_column(vec, m, index) {
    gml_pragma("forceinline");
    var offset = index * 4;
    vec[0] = m[offset];
    vec[1] = m[offset + 1];
    vec[2] = m[offset + 2];
    return vec;
}

/// @func vec3_set_from_matrix3_column(vec, m, index)
/// @desc Sets the vector components from the specified 3x3 matrix column.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} m The 3x3 matrix
/// @param {Real} index The column index
/// @returns {Array<Real>} The modified vector
function vec3_set_from_matrix3_column(vec, m, index) {
    gml_pragma("forceinline");
    var offset = index * 3;
    vec[0] = m[offset];
    vec[1] = m[offset + 1];
    vec[2] = m[offset + 2];
    return vec;
}

/// @func vec3_set_from_matrix_position(vec, m)
/// @desc Sets the vector components to the position elements of the given 4x4 transformation matrix.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} m The 4x4 matrix
/// @returns {Array<Real>} The modified vector
function vec3_set_from_matrix_position(vec, m) {
    gml_pragma("forceinline");
    vec[0] = m[12];
    vec[1] = m[13];
    vec[2] = m[14];
    return vec;
}

/// @func vec3_set_from_matrix_scale(vec, m)
/// @desc Sets the vector components to the scale elements of the given 4x4 transformation matrix.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} m The 4x4 matrix
/// @returns {Array<Real>} The modified vector
function vec3_set_from_matrix_scale(vec, m) {
    gml_pragma("forceinline");
    vec[0] = sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2]);
    vec[1] = sqrt(m[4] * m[4] + m[5] * m[5] + m[6] * m[6]);
    vec[2] = sqrt(m[8] * m[8] + m[9] * m[9] + m[10] * m[10]);
    return vec;
}

// ============================================================================
// SPHERICAL / CYLINDRICAL COORDINATES
// ============================================================================

/// @func vec3_set_from_spherical_coords(vec, radius, phi, theta)
/// @desc Sets the vector components from the given spherical coordinates.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} radius The radius
/// @param {Real} phi The phi angle in radians
/// @param {Real} theta The theta angle in radians
/// @returns {Array<Real>} The modified vector
function vec3_set_from_spherical_coords(vec, radius, phi, theta) {
    gml_pragma("forceinline");
    var sinPhi = sin(phi);
    vec[0] = radius * sinPhi * cos(theta);
    vec[1] = radius * cos(phi);
    vec[2] = radius * sinPhi * sin(theta);
    return vec;
}

/// @func vec3_set_from_cylindrical_coords(vec, radius, theta, y)
/// @desc Sets the vector components from the given cylindrical coordinates.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} radius The radius
/// @param {Real} theta The theta angle in radians
/// @param {Real} _y The y value
/// @returns {Array<Real>} The modified vector
function vec3_set_from_cylindrical_coords(vec, radius, theta, _y) {
    gml_pragma("forceinline");
    vec[0] = radius * cos(theta);
    vec[1] = _y;
    vec[2] = radius * sin(theta);
    return vec;
}

// ============================================================================
// EXTRA UTILITY
// ============================================================================

/// @func vec3_abs(vec)
/// @desc Sets all components to their absolute values.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec3_abs(vec) {
    gml_pragma("forceinline");
    vec[0] = abs(vec[0]);
    vec[1] = abs(vec[1]);
    vec[2] = abs(vec[2]);
    return vec;
}

// ============================================================================
// EULER ROTATION
// ============================================================================

/// @func vec3_apply_euler(vec, euler, order)
/// @desc Applies the given Euler rotation to this vector.
/// @param {Array<Real>} vec The vector to rotate
/// @param {Array<Real>} euler The Euler angles [x, y, z] in degrees
/// @param {String} [order="XYZ"] The rotation order (e.g., "XYZ", "YXZ", etc.)
/// @returns {Array<Real>} The modified vector
function vec3_apply_euler(vec, euler, order = "XYZ") {
    gml_pragma("forceinline");
    // Convert Euler to quaternion, then apply quaternion
    var quat = __vec3_euler_to_quaternion(euler[0], euler[1], euler[2], order);
    vec3_apply_quaternion(vec, quat);
    return vec;
}

/// @func vec3_set_from_euler(vec, euler)
/// @desc Sets the vector components from the given Euler angles (just copies x, y, z).
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} euler The Euler angles [x, y, z] in degrees
/// @returns {Array<Real>} The modified vector
function vec3_set_from_euler(vec, euler) {
    gml_pragma("forceinline");
    vec[0] = euler[0];
    vec[1] = euler[1];
    vec[2] = euler[2];
    return vec;
}

/// @func __vec3_euler_to_quaternion(x, y, z, order)
/// @desc Internal helper: converts Euler angles (degrees) to quaternion [qx, qy, qz, qw].
/// @param {Real} x X rotation in degrees
/// @param {Real} y Y rotation in degrees
/// @param {Real} z Z rotation in degrees
/// @param {String} order Rotation order
/// @returns {Array<Real>} Quaternion [x, y, z, w]
function __vec3_euler_to_quaternion(x, y, z, order) {
    gml_pragma("forceinline");
    // Convert to radians and half angles
    var c1 = dcos(x * 0.5), s1 = dsin(x * 0.5);
    var c2 = dcos(y * 0.5), s2 = dsin(y * 0.5);
    var c3 = dcos(z * 0.5), s3 = dsin(z * 0.5);

    var qx, qy, qz, qw;

    switch (order) {
        case "XYZ":
            qx = s1 * c2 * c3 + c1 * s2 * s3;
            qy = c1 * s2 * c3 - s1 * c2 * s3;
            qz = c1 * c2 * s3 + s1 * s2 * c3;
            qw = c1 * c2 * c3 - s1 * s2 * s3;
            break;
        case "YXZ":
            qx = s1 * c2 * c3 + c1 * s2 * s3;
            qy = c1 * s2 * c3 - s1 * c2 * s3;
            qz = c1 * c2 * s3 - s1 * s2 * c3;
            qw = c1 * c2 * c3 + s1 * s2 * s3;
            break;
        case "ZXY":
            qx = s1 * c2 * c3 - c1 * s2 * s3;
            qy = c1 * s2 * c3 + s1 * c2 * s3;
            qz = c1 * c2 * s3 + s1 * s2 * c3;
            qw = c1 * c2 * c3 - s1 * s2 * s3;
            break;
        case "ZYX":
            qx = s1 * c2 * c3 - c1 * s2 * s3;
            qy = c1 * s2 * c3 + s1 * c2 * s3;
            qz = c1 * c2 * s3 - s1 * s2 * c3;
            qw = c1 * c2 * c3 + s1 * s2 * s3;
            break;
        case "YZX":
            qx = s1 * c2 * c3 + c1 * s2 * s3;
            qy = c1 * s2 * c3 + s1 * c2 * s3;
            qz = c1 * c2 * s3 - s1 * s2 * c3;
            qw = c1 * c2 * c3 - s1 * s2 * s3;
            break;
        case "XZY":
            qx = s1 * c2 * c3 - c1 * s2 * s3;
            qy = c1 * s2 * c3 - s1 * c2 * s3;
            qz = c1 * c2 * s3 + s1 * s2 * c3;
            qw = c1 * c2 * c3 + s1 * s2 * s3;
            break;
        default:
            // Default to XYZ
            qx = s1 * c2 * c3 + c1 * s2 * s3;
            qy = c1 * s2 * c3 - s1 * c2 * s3;
            qz = c1 * c2 * s3 + s1 * s2 * c3;
            qw = c1 * c2 * c3 - s1 * s2 * s3;
    }

    return [qx, qy, qz, qw];
}

// ============================================================================
// SPHERICAL / CYLINDRICAL
// ============================================================================

/// @func vec3_set_from_spherical(vec, spherical)
/// @desc Sets the vector components from the given spherical coordinates array.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} spherical The spherical coords [radius, phi, theta] (phi/theta in radians)
/// @returns {Array<Real>} The modified vector
function vec3_set_from_spherical(vec, spherical) {
    gml_pragma("forceinline");
    var radius = spherical[0];
    var phi = spherical[1];
    var theta = spherical[2];
    var sinPhi = sin(phi);
    vec[0] = radius * sinPhi * cos(theta);
    vec[1] = radius * cos(phi);
    vec[2] = radius * sinPhi * sin(theta);
    return vec;
}

/// @func vec3_set_from_cylindrical(vec, cylindrical)
/// @desc Sets the vector components from the given cylindrical coordinates array.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} cylindrical The cylindrical coords [radius, theta, y] (theta in radians)
/// @returns {Array<Real>} The modified vector
function vec3_set_from_cylindrical(vec, cylindrical) {
    gml_pragma("forceinline");
    var radius = cylindrical[0];
    var theta = cylindrical[1];
    var _y = cylindrical[2];
    vec[0] = radius * cos(theta);
    vec[1] = _y;
    vec[2] = radius * sin(theta);
    return vec;
}

// ============================================================================
// COLOR
// ============================================================================

/// @func vec3_set_from_color(vec, color)
/// @desc Sets the vector components from the RGB components of the given color.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} color The color [r, g, b] with values 0-1
/// @returns {Array<Real>} The modified vector
function vec3_set_from_color(vec, color) {
    gml_pragma("forceinline");
    vec[0] = color[0];
    vec[1] = color[1];
    vec[2] = color[2];
    return vec;
}

/// @func vec3_set_from_color_gml(vec, color)
/// @desc Sets the vector from a GML color value (0-255 per channel).
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} color GameMaker color value
/// @returns {Array<Real>} The modified vector
function vec3_set_from_color_gml(vec, color) {
    gml_pragma("forceinline");
    vec[0] = colour_get_red(color) / 255;
    vec[1] = colour_get_green(color) / 255;
    vec[2] = colour_get_blue(color) / 255;
    return vec;
}
