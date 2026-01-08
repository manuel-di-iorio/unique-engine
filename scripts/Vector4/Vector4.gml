/// @desc 4D vector functions using arrays [x, y, z, w]
/// All angles are in DEGREES.
/// All functions modify the first vector in-place when applicable for zero allocations.

// Global temp vectors in order to avoid allocations
global.UE_VEC4_TEMP0 = vec4_create();
global.UE_VEC4_TEMP1 = vec4_create();
global.UE_VEC4_TEMP2 = vec4_create();
global.UE_VEC4_TEMP3 = vec4_create();

// Vector4 Enum
enum VEC4 {
  x, y, z, w
}

/// @func vec4_create(x, y, z, w)
/// @desc Creates a new vec4 array with the given components.
/// @param {Real} [x=0] X component
/// @param {Real} [y=0] Y component
/// @param {Real} [z=0] Z component
/// @param {Real} [w=1] W component
/// @returns {Array<Real>} New vec4 array
function vec4_create(x = 0, y = 0, z = 0, w = 1) {
    gml_pragma("forceinline");
    return [x, y, z, w];
}

// ============================================================================
// SETTERS
// ============================================================================

/// @func vec4_set(vec, x, y, z, w)
/// @desc Sets the vector components.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} x The value of the x component
/// @param {Real} y The value of the y component
/// @param {Real} z The value of the z component
/// @param {Real} w The value of the w component
/// @returns {Array<Real>} The modified vector
function vec4_set(vec, x, y, z, w) {
    gml_pragma("forceinline");
    vec[0] = x;
    vec[1] = y;
    vec[2] = z;
    vec[3] = w;
    return vec;
}

/// @func vec4_set_scalar(vec, scalar)
/// @desc Sets the vector components to the same value.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} scalar The value to set for all components
/// @returns {Array<Real>} The modified vector
function vec4_set_scalar(vec, scalar) {
    gml_pragma("forceinline");
    vec[0] = scalar;
    vec[1] = scalar;
    vec[2] = scalar;
    vec[3] = scalar;
    return vec;
}

/// @func vec4_set_x(vec, x)
/// @desc Sets the vector's x component.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} x The value to set
/// @returns {Array<Real>} The modified vector
function vec4_set_x(vec, x) {
    gml_pragma("forceinline");
    vec[0] = x;
    return vec;
}

/// @func vec4_set_y(vec, y)
/// @desc Sets the vector's y component.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} y The value to set
/// @returns {Array<Real>} The modified vector
function vec4_set_y(vec, y) {
    gml_pragma("forceinline");
    vec[1] = y;
    return vec;
}

/// @func vec4_set_z(vec, z)
/// @desc Sets the vector's z component (alias for width).
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} z The value to set
/// @returns {Array<Real>} The modified vector
function vec4_set_z(vec, z) {
    gml_pragma("forceinline");
    vec[2] = z;
    return vec;
}

/// @func vec4_set_width(vec, width)
/// @desc Alias for vec4_set_z.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} width The value to set
/// @returns {Array<Real>} The modified vector
function vec4_set_width(vec, width) {
    gml_pragma("forceinline");
    vec[2] = width;
    return vec;
}

/// @func vec4_set_w(vec, w)
/// @desc Sets the vector's w component (alias for height).
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} w The value to set
/// @returns {Array<Real>} The modified vector
function vec4_set_w(vec, w) {
    gml_pragma("forceinline");
    vec[3] = w;
    return vec;
}

/// @func vec4_set_height(vec, height)
/// @desc Alias for vec4_set_w.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} height The value to set
/// @returns {Array<Real>} The modified vector
function vec4_set_height(vec, height) {
    gml_pragma("forceinline");
    vec[3] = height;
    return vec;
}

/// @func vec4_set_component(vec, index, value)
/// @desc Allows to set a vector component with an index.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} index The component index (0=x, 1=y, 2=z, 3=w)
/// @param {Real} value The value to set
/// @returns {Array<Real>} The modified vector
function vec4_set_component(vec, index, value) {
    gml_pragma("forceinline");
    vec[index] = value;
    return vec;
}

/// @func vec4_get_component(vec, index)
/// @desc Returns the value of the vector component which matches the given index.
/// @param {Array<Real>} vec The vector
/// @param {Real} index The component index (0=x, 1=y, 2=z, 3=w)
/// @returns {Real} The component value
function vec4_get_component(vec, index) {
    gml_pragma("forceinline");
    return vec[index];
}

// ============================================================================
// CLONE / COPY / FROM / TO
// ============================================================================

/// @func vec4_clone(vec)
/// @desc Returns a new vector with copied values from this instance.
/// @param {Array<Real>} vec The vector to clone
/// @returns {Array<Real>} A clone of the vector
function vec4_clone(vec) {
    gml_pragma("forceinline");
    return [vec[0], vec[1], vec[2], vec[3]];
}

/// @func vec4_copy(vec, v)
/// @desc Copies the values of the given vector to this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to copy (can be vec3 or vec4)
/// @returns {Array<Real>} The modified vector
function vec4_copy(vec, v) {
    gml_pragma("forceinline");
    vec[0] = v[0];
    vec[1] = v[1];
    vec[2] = v[2];
    vec[3] = (array_length(v) > 3) ? v[3] : 1;
    return vec;
}

/// @func vec4_from_array(vec, array, offset)
/// @desc Sets this vector from an array.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} array Array holding the vector component values
/// @param {Real} [offset=0] The offset into the array
/// @returns {Array<Real>} The modified vector
function vec4_from_array(vec, array, offset = 0) {
	gml_pragma("forceinline");
	vec[0] = array[offset];
	vec[1] = array[offset + 1];
	vec[2] = array[offset + 2];
	vec[3] = array[offset + 3];
	return vec;
}

/// @func vec4_to_array(vec, array, offset)
/// @desc Writes the components of this vector to the given array.
/// @param {Array<Real>} vec The vector
/// @param {Array<Real>} [array] The target array holding the vector components
/// @param {Real} [offset=0] Index of the first element in the array
/// @returns {Array<Real>} The vector components array
function vec4_to_array(vec, array = undefined, offset = 0) {
	gml_pragma("forceinline");
    array ??= array_create(4);
	array[offset] = vec[0];
	array[offset + 1] = vec[1];
	array[offset + 2] = vec[2];
	array[offset + 3] = vec[3];
	return array;
}

// ============================================================================
// ADDITION
// ============================================================================

/// @func vec4_add(vec, v)
/// @desc Adds the given vector to this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to add
/// @returns {Array<Real>} The modified vector
function vec4_add(vec, v) {
    gml_pragma("forceinline");
    vec[0] += v[0];
    vec[1] += v[1];
    vec[2] += v[2];
    vec[3] += v[3];
    return vec;
}

/// @func vec4_add_scalar(vec, s)
/// @desc Adds the given scalar value to all components of this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} s The scalar to add
/// @returns {Array<Real>} The modified vector
function vec4_add_scalar(vec, s) {
    gml_pragma("forceinline");
    vec[0] += s;
    vec[1] += s;
    vec[2] += s;
    vec[3] += s;
    return vec;
}

/// @func vec4_add_scaled_vector(vec, v, s)
/// @desc Adds the given vector scaled by the given factor to this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to scale and add
/// @param {Real} s The factor that scales v
/// @returns {Array<Real>} The modified vector
function vec4_add_scaled_vector(vec, v, s) {
    gml_pragma("forceinline");
    vec[0] += v[0] * s;
    vec[1] += v[1] * s;
    vec[2] += v[2] * s;
    vec[3] += v[3] * s;
    return vec;
}

/// @func vec4_add_vectors(vec, a, b)
/// @desc Adds the given vectors and stores the result in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} a The first vector
/// @param {Array<Real>} b The second vector
/// @returns {Array<Real>} The modified vector
function vec4_add_vectors(vec, a, b) {
    gml_pragma("forceinline");
    vec[0] = a[0] + b[0];
    vec[1] = a[1] + b[1];
    vec[2] = a[2] + b[2];
    vec[3] = a[3] + b[3];
    return vec;
}

// ============================================================================
// SUBTRACTION
// ============================================================================

/// @func vec4_sub(vec, v)
/// @desc Subtracts the given vector from this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to subtract
/// @returns {Array<Real>} The modified vector
function vec4_sub(vec, v) {
    gml_pragma("forceinline");
    vec[0] -= v[0];
    vec[1] -= v[1];
    vec[2] -= v[2];
    vec[3] -= v[3];
    return vec;
}

/// @func vec4_sub_scalar(vec, s)
/// @desc Subtracts the given scalar value from all components of this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} s The scalar to subtract
/// @returns {Array<Real>} The modified vector
function vec4_sub_scalar(vec, s) {
    gml_pragma("forceinline");
    vec[0] -= s;
    vec[1] -= s;
    vec[2] -= s;
    vec[3] -= s;
    return vec;
}

/// @func vec4_sub_vectors(vec, a, b)
/// @desc Subtracts the given vectors and stores the result in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} a The first vector
/// @param {Array<Real>} b The second vector
/// @returns {Array<Real>} The modified vector
function vec4_sub_vectors(vec, a, b) {
    gml_pragma("forceinline");
    vec[0] = a[0] - b[0];
    vec[1] = a[1] - b[1];
    vec[2] = a[2] - b[2];
    vec[3] = a[3] - b[3];
    return vec;
}

// ============================================================================
// MULTIPLICATION
// ============================================================================

/// @func vec4_multiply(vec, v)
/// @desc Multiplies the given vector with this instance (component-wise).
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to multiply
/// @returns {Array<Real>} The modified vector
function vec4_multiply(vec, v) {
    gml_pragma("forceinline");
    vec[0] *= v[0];
    vec[1] *= v[1];
    vec[2] *= v[2];
    vec[3] *= v[3];
    return vec;
}

/// @func vec4_multiply_scalar(vec, scalar)
/// @desc Multiplies the given scalar value with all components of this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} scalar The scalar to multiply
/// @returns {Array<Real>} The modified vector
function vec4_multiply_scalar(vec, scalar) {
    gml_pragma("forceinline");
    vec[0] *= scalar;
    vec[1] *= scalar;
    vec[2] *= scalar;
    vec[3] *= scalar;
    return vec;
}

// ============================================================================
// DIVISION
// ============================================================================

/// @func vec4_divide(vec, v)
/// @desc Divides this instance by the given vector (component-wise).
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to divide by
/// @returns {Array<Real>} The modified vector
function vec4_divide(vec, v) {
    gml_pragma("forceinline");
    vec[0] /= v[0];
    vec[1] /= v[1];
    vec[2] /= v[2];
    vec[3] /= v[3];
    return vec;
}

/// @func vec4_divide_scalar(vec, scalar)
/// @desc Divides this vector by the given scalar.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} scalar The scalar to divide by
/// @returns {Array<Real>} The modified vector
function vec4_divide_scalar(vec, scalar) {
    gml_pragma("forceinline");
    var inv = 1 / scalar;
    vec[0] *= inv;
    vec[1] *= inv;
    vec[2] *= inv;
    vec[3] *= inv;
    return vec;
}

// ============================================================================
// DOT
// ============================================================================

/// @func vec4_dot(vec, v)
/// @desc Calculates the dot product of the given vector with this instance.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to compute dot product with
/// @returns {Real} The result of the dot product
function vec4_dot(vec, v) {
    gml_pragma("forceinline");
    return vec[0] * v[0] + vec[1] * v[1] + vec[2] * v[2] + vec[3] * v[3];
}

// ============================================================================
// LENGTH
// ============================================================================

/// @func vec4_length(vec)
/// @desc Computes the Euclidean length (straight-line length) from (0, 0, 0, 0) to (x, y, z, w).
/// @param {Array<Real>} vec The vector
/// @returns {Real} The length of this vector
function vec4_length(vec) {
    gml_pragma("forceinline");
    return sqrt(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2] + vec[3] * vec[3]);
}

/// @func vec4_length_sq(vec)
/// @desc Computes the square of the Euclidean length. More efficient for comparisons.
/// @param {Array<Real>} vec The vector
/// @returns {Real} The square length of this vector
function vec4_length_sq(vec) {
    gml_pragma("forceinline");
    return vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2] + vec[3] * vec[3];
}

/// @func vec4_manhattan_length(vec)
/// @desc Computes the Manhattan length of this vector.
/// @param {Array<Real>} vec The vector
/// @returns {Real} The Manhattan length
function vec4_manhattan_length(vec) {
    gml_pragma("forceinline");
    return abs(vec[0]) + abs(vec[1]) + abs(vec[2]) + abs(vec[3]);
}

/// @func vec4_set_length(vec, length)
/// @desc Sets this vector to a vector with the same direction as this one, but with the specified length.
/// @param {Array<Real>} vec The vector to modify
/// @param {Real} length The new length
/// @returns {Array<Real>} The modified vector
function vec4_set_length(vec, length) {
    gml_pragma("forceinline");
    var current_len = vec4_length(vec);
    if (current_len > 0) {
        var scale = length / current_len;
        vec[0] *= scale;
        vec[1] *= scale;
        vec[2] *= scale;
        vec[3] *= scale;
    }
    return vec;
}

// ============================================================================
// NORMALIZE / NEGATE
// ============================================================================

/// @func vec4_normalize(vec)
/// @desc Converts this vector to a unit vector - sets it equal to a vector with the same direction but length 1.
/// @param {Array<Real>} vec The vector to normalize
/// @returns {Array<Real>} The modified vector
function vec4_normalize(vec) {
    gml_pragma("forceinline");
    var len = vec4_length(vec);
    if (len > 0) {
        var inv = 1 / len;
        vec[0] *= inv;
        vec[1] *= inv;
        vec[2] *= inv;
        vec[3] *= inv;
    }
    return vec;
}

/// @func vec4_negate(vec)
/// @desc Inverts this vector - i.e. sets x = -x, y = -y, z = -z and w = -w.
/// @param {Array<Real>} vec The vector to negate
/// @returns {Array<Real>} The modified vector
function vec4_negate(vec) {
    gml_pragma("forceinline");
    vec[0] = -vec[0];
    vec[1] = -vec[1];
    vec[2] = -vec[2];
    vec[3] = -vec[3];
    return vec;
}

// ============================================================================
// MIN / MAX / CLAMP
// ============================================================================

/// @func vec4_min(vec, v)
/// @desc If this vector's x, y, z or w value is greater than the given vector's value, replace with the min.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector
/// @returns {Array<Real>} The modified vector
function vec4_min(vec, v) {
    gml_pragma("forceinline");
    vec[0] = min(vec[0], v[0]);
    vec[1] = min(vec[1], v[1]);
    vec[2] = min(vec[2], v[2]);
    vec[3] = min(vec[3], v[3]);
    return vec;
}

/// @func vec4_max(vec, v)
/// @desc If this vector's x, y, z or w value is less than the given vector's value, replace with the max.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector
/// @returns {Array<Real>} The modified vector
function vec4_max(vec, v) {
    gml_pragma("forceinline");
    vec[0] = max(vec[0], v[0]);
    vec[1] = max(vec[1], v[1]);
    vec[2] = max(vec[2], v[2]);
    vec[3] = max(vec[3], v[3]);
    return vec;
}

/// @func vec4_clamp(vec, min_vec, max_vec)
/// @desc Clamps vec components between min and max vectors.
/// @param {Array<Real>} vec The vector to clamp
/// @param {Array<Real>} min_vec The minimum values
/// @param {Array<Real>} max_vec The maximum values in the desired range
/// @returns {Array<Real>} The modified vector
function vec4_clamp(vec, min_vec, max_vec) {
    gml_pragma("forceinline");
    vec[0] = clamp(vec[0], min_vec[0], max_vec[0]);
    vec[1] = clamp(vec[1], min_vec[1], max_vec[1]);
    vec[2] = clamp(vec[2], min_vec[2], max_vec[2]);
    vec[3] = clamp(vec[3], min_vec[3], max_vec[3]);
    return vec;
}

/// @func vec4_clamp_scalar(vec, min_val, max_val)
/// @desc Clamps vec components between scalar min and max values.
/// @param {Array<Real>} vec The vector to clamp
/// @param {Real} min_val The minimum value the components will be clamped to
/// @param {Real} max_val The maximum value the components will be clamped to
/// @returns {Array<Real>} The modified vector
function vec4_clamp_scalar(vec, min_val, max_val) {
    gml_pragma("forceinline");
    vec[0] = clamp(vec[0], min_val, max_val);
    vec[1] = clamp(vec[1], min_val, max_val);
    vec[2] = clamp(vec[2], min_val, max_val);
    vec[3] = clamp(vec[3], min_val, max_val);
    return vec;
}

/// @func vec4_clamp_length(vec, min_len, max_len)
/// @desc Clamps the vector length between min and max values.
/// @param {Array<Real>} vec The vector to clamp
/// @param {Real} min_len The minimum value the vector length will be clamped to
/// @param {Real} max_len The maximum value the vector length will be clamped to
/// @returns {Array<Real>} The modified vector
function vec4_clamp_length(vec, min_len, max_len) {
    gml_pragma("forceinline");
    var len = vec4_length(vec);
    if (len > 0) {
        var new_len = clamp(len, min_len, max_len);
        if (new_len != len) {
            var scale = new_len / len;
            vec[0] *= scale;
            vec[1] *= scale;
            vec[2] *= scale;
            vec[3] *= scale;
        }
    }
    return vec;
}

// ============================================================================
// ROUNDING
// ============================================================================

/// @func vec4_floor(vec)
/// @desc The components of this vector are rounded down to the nearest integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec4_floor(vec) {
    gml_pragma("forceinline");
    vec[0] = floor(vec[0]);
    vec[1] = floor(vec[1]);
    vec[2] = floor(vec[2]);
    vec[3] = floor(vec[3]);
    return vec;
}

/// @func vec4_ceil(vec)
/// @desc The components of this vector are rounded up to the nearest integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec4_ceil(vec) {
    gml_pragma("forceinline");
    vec[0] = ceil(vec[0]);
    vec[1] = ceil(vec[1]);
    vec[2] = ceil(vec[2]);
    vec[3] = ceil(vec[3]);
    return vec;
}

/// @func vec4_round(vec)
/// @desc The components of this vector are rounded to the nearest integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec4_round(vec) {
    gml_pragma("forceinline");
    vec[0] = round(vec[0]);
    vec[1] = round(vec[1]);
    vec[2] = round(vec[2]);
    vec[3] = round(vec[3]);
    return vec;
}

/// @func vec4_round_to_zero(vec)
/// @desc The components of this vector are rounded towards zero (up if negative, down if positive) to an integer value.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec4_round_to_zero(vec) {
    gml_pragma("forceinline");
    vec[0] = (vec[0] < 0) ? ceil(vec[0]) : floor(vec[0]);
    vec[1] = (vec[1] < 0) ? ceil(vec[1]) : floor(vec[1]);
    vec[2] = (vec[2] < 0) ? ceil(vec[2]) : floor(vec[2]);
    vec[3] = (vec[3] < 0) ? ceil(vec[3]) : floor(vec[3]);
    return vec;
}

// ============================================================================
// EQUALITY
// ============================================================================

/// @func vec4_equals(vec, v)
/// @desc Returns true if this vector is equal with the given one.
/// @param {Array<Real>} vec First vector
/// @param {Array<Real>} v The vector to test for equality
/// @returns {Bool} Whether this vector is equal with the given one
function vec4_equals(vec, v) {
    gml_pragma("forceinline");
    return vec[0] == v[0] && vec[1] == v[1] && vec[2] == v[2] && vec[3] == v[3];
}

// ============================================================================
// INTERPOLATION
// ============================================================================

/// @func vec4_lerp(vec, v, alpha)
/// @desc Linearly interpolates between the given vector and this instance.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} v The vector to interpolate towards
/// @param {Real} alpha The interpolation factor, typically in [0, 1]
/// @returns {Array<Real>} The modified vector
function vec4_lerp(vec, v, alpha) {
    gml_pragma("forceinline");
    vec[0] += (v[0] - vec[0]) * alpha;
    vec[1] += (v[1] - vec[1]) * alpha;
    vec[2] += (v[2] - vec[2]) * alpha;
    vec[3] += (v[3] - vec[3]) * alpha;
    return vec;
}

/// @func vec4_lerp_vectors(vec, v1, v2, alpha)
/// @desc Linearly interpolates between the given vectors. The result is stored in this instance.
/// @param {Array<Real>} vec The vector to store result
/// @param {Array<Real>} v1 The first vector
/// @param {Array<Real>} v2 The second vector
/// @param {Real} alpha The interpolation factor, typically in [0, 1]
/// @returns {Array<Real>} The modified vector
function vec4_lerp_vectors(vec, v1, v2, alpha) {
    gml_pragma("forceinline");
    vec[0] = v1[0] + (v2[0] - v1[0]) * alpha;
    vec[1] = v1[1] + (v2[1] - v1[1]) * alpha;
    vec[2] = v1[2] + (v2[2] - v1[2]) * alpha;
    vec[3] = v1[3] + (v2[3] - v1[3]) * alpha;
    return vec;
}

// ============================================================================
// RANDOM
// ============================================================================

/// @func vec4_random(vec)
/// @desc Sets each component of this vector to a pseudo-random value between 0 and 1, excluding 1.
/// @param {Array<Real>} vec The vector to modify
/// @returns {Array<Real>} The modified vector
function vec4_random(vec) {
    gml_pragma("forceinline");
    vec[0] = random(1);
    vec[1] = random(1);
    vec[2] = random(1);
    vec[3] = random(1);
    return vec;
}

// ============================================================================
// MATRIX / QUATERNION TRANSFORMS
// ============================================================================

/// @func vec4_apply_matrix4(vec, m)
/// @desc Multiplies this vector with the given 4x4 matrix.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} m The 4x4 matrix
/// @returns {Array<Real>} The modified vector
function vec4_apply_matrix4(vec, m) {
	gml_pragma("forceinline");
	var _x = vec[0], _y = vec[1], _z = vec[2], _w = vec[3];
	
	vec[0] = m[0] * _x + m[4] * _y + m[8] * _z + m[12] * _w;
	vec[1] = m[1] * _x + m[5] * _y + m[9] * _z + m[13] * _w;
	vec[2] = m[2] * _x + m[6] * _y + m[10] * _z + m[14] * _w;
	vec[3] = m[3] * _x + m[7] * _y + m[11] * _z + m[15] * _w;
	return vec;
}

/// @func vec4_set_axis_angle_from_quaternion(vec, q)
/// @desc Sets the x, y and z components of this vector to the quaternion's axis and w to the angle.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} q The quaternion [x, y, z, w]
/// @returns {Array<Real>} The modified vector
function vec4_set_axis_angle_from_quaternion(vec, q) {
	gml_pragma("forceinline");
	// http://www.euclideanspace.com/maths/geometry/rotations/conversions/quaternionToAngle/index.htm
	
	var qw = clamp(q[3], - 1, 1);
	vec[3] = 2 * darccos(qw);
	
	var s = sqrt(1 - qw * qw);
	if (s < 0.0001) {
		vec[0] = 1;
		vec[1] = 0;
		vec[2] = 0;
	} else {
		vec[0] = q[0] / s;
		vec[1] = q[1] / s;
		vec[2] = q[2] / s;
	}
	
	return vec;
}

/// @func vec4_set_axis_angle_from_rotation_matrix(vec, m)
/// @desc Sets the x, y and z components of this vector to the axis of rotation and w to the angle.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} m A 4x4 matrix of which the upper left 3x3 matrix is a pure rotation matrix.
/// @returns {Array<Real>} The modified vector
function vec4_set_axis_angle_from_rotation_matrix(vec, m) {
	gml_pragma("forceinline");
	// http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToAngle/index.htm
	
	var angle, _x, _y, _z; // variables for our calculations
	var epsilon = 0.01; // margin to allow for rounding errors
	var epsilon2 = 0.1; // margin to distinguish between 0 and 180 degrees
	
	var m11 = m[0], m12 = m[4], m13 = m[8];
	var m21 = m[1], m22 = m[5], m23 = m[9];
	var m31 = m[2], m32 = m[6], m33 = m[10];
	
	if ((abs(m12 - m21) < epsilon) && (abs(m13 - m31) < epsilon) && (abs(m23 - m32) < epsilon)) {
		// singularity found
		// first check for identity matrix which implies zero angle
		if ((abs(m12 + m21) < epsilon2) && (abs(m13 + m31) < epsilon2) && (abs(m23 + m32) < epsilon2) && (abs(m11 + m22 + m33 - 3) < epsilon2)) {
			// this singularity is identity matrix so angle = 0
			return vec4_set(vec, 1, 0, 0, 0);
		}
		// otherwise this singularity is angle = 180
		angle = 180;
		var xx = (m11 + 1) / 2;
		var yy = (m22 + 1) / 2;
		var zz = (m33 + 1) / 2;
		var xy = (m12 + m21) / 4;
		var xz = (m13 + m31) / 4;
		var yz = (m23 + m32) / 4;
		if ((xx > yy) && (xx > zz)) { // m[0] is the largest diagonal term
			if (xx < epsilon) {
				_x = 0; _y = 0.707106781; _z = 0.707106781;
			} else {
				_x = sqrt(xx); _y = xy / _x; _z = xz / _x;
			}
		} else if (yy > zz) { // m[5] is the largest diagonal term
			if (yy < epsilon) {
				_x = 0.707106781; _y = 0; _z = 0.707106781;
			} else {
				_y = sqrt(yy); _x = xy / _y; _z = yz / _y;
			}
		} else { // m[10] is the largest diagonal term
			if (zz < epsilon) {
				_x = 0.707106781; _y = 0.707106781; _z = 0;
			} else {
				_z = sqrt(zz); _x = xz / _z; _y = yz / _z;
			}
		}
		return vec4_set(vec, _x, _y, _z, angle);
	}
	
	// as we have no singularities we can compute normally
	var s = sqrt((m32 - m23) * (m32 - m23) + (m13 - m31) * (m13 - m31) + (m21 - m12) * (m21 - m12));
	if (abs(s) < 0.001) s = 1;
	// prevent divide by zero, should not happen if s is computed correctly
	
	vec[3] = darccos((m11 + m22 + m33 - 1) / 2);
	vec[0] = (m32 - m23) / s;
	vec[1] = (m13 - m31) / s;
	vec[2] = (m21 - m12) / s;
	
	return vec;
}

/// @func vec4_set_from_matrix_position(vec, m)
/// @desc Sets the vector components to the position elements of the given transformation matrix.
/// @param {Array<Real>} vec The vector to modify
/// @param {Array<Real>} m The 4x4 matrix
/// @returns {Array<Real>} The modified vector
function vec4_set_from_matrix_position(vec, m) {
	gml_pragma("forceinline");
	vec[0] = m[12];
	vec[1] = m[13];
	vec[2] = m[14];
	vec[3] = m[15];
	return vec;
}
