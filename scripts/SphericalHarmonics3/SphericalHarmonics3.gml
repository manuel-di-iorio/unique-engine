/// @desc 3rd-order Spherical Harmonics (SH)
/// coefficients is an array of 9 Vector3 arrays.

/// @func sh3_create()
/// @desc Creates a new spherical harmonics instance.
/// @returns {Array<Array<Real>>} New SH instance
function sh3_create() {
    gml_pragma("forceinline");
    var coeffs = array_create(9);
    for (var i = 0; i < 9; i++) coeffs[i] = vec3_create();
    return coeffs;
}

/// @func sh3_set(sh, coefficients)
/// @desc Sets the SH coefficients by copying values.
/// @param {Array<Array<Real>>} sh The SH instance to modify
/// @param {Array<Array<Real>>} coefficients Array of 9 Vector3 coefficients
/// @returns {Array<Array<Real>>} The modified SH instance
function sh3_set(sh, coefficients) {
    gml_pragma("forceinline");
    for (var i = 0; i < 9; i++) {
        vec3_copy(sh[i], coefficients[i]);
    }
    return sh;
}

/// @func sh3_zero(sh)
/// @desc Sets all SH coefficients to 0.
/// @param {Array<Array<Real>>} sh The SH instance to modify
/// @returns {Array<Array<Real>>} The modified SH instance
function sh3_zero(sh) {
    gml_pragma("forceinline");
    for (var i = 0; i < 9; i++) {
        vec3_set_scalar(sh[i], 0);
    }
    return sh;
}

/// @func sh3_copy(sh, other)
/// @desc Copies the values of the given SH to this instance.
/// @param {Array<Array<Real>>} sh The SH instance to modify
/// @param {Array<Array<Real>>} other The source SH
/// @returns {Array<Array<Real>>} The modified SH instance
function sh3_copy(sh, other) {
    gml_pragma("forceinline");
    for (var i = 0; i < 9; i++) {
        vec3_copy(sh[i], other[i]);
    }
    return sh;
}

/// @func sh3_clone(sh)
/// @desc Returns a new SH with copied values from this instance.
/// @param {Array<Array<Real>>} sh The SH instance to clone
/// @returns {Array<Array<Real>>} A clone of the SH
function sh3_clone(sh) {
    gml_pragma("forceinline");
    var n = sh3_create();
    for (var i = 0; i < 9; i++) {
        vec3_copy(n[i], sh[i]);
    }
    return n;
}

/// @func sh3_add(sh, other)
/// @desc Adds the given SH to this instance.
/// @param {Array<Array<Real>>} sh The SH instance to modify
/// @param {Array<Array<Real>>} other The SH to add
/// @returns {Array<Array<Real>>} The modified SH instance
function sh3_add(sh, other) {
    gml_pragma("forceinline");
    for (var i = 0; i < 9; i++) {
        vec3_add(sh[i], other[i]);
    }
    return sh;
}

/// @func sh3_add_scaled_sh(sh, other, s)
/// @desc Adds the given SH scaled by s to this instance.
/// @param {Array<Array<Real>>} sh The SH instance to modify
/// @param {Array<Array<Real>>} other The SH to add
/// @param {Real} s The scale factor
/// @returns {Array<Array<Real>>} The modified SH instance
function sh3_add_scaled_sh(sh, other, s) {
    gml_pragma("forceinline");
    for (var i = 0; i < 9; i++) {
        vec3_add_scaled_vector(sh[i], other[i], s);
    }
    return sh;
}

/// @func sh3_scale(sh, s)
/// @desc Scales this SH by the given scale factor.
/// @param {Array<Array<Real>>} sh The SH instance to modify
/// @param {Real} s The scale factor
/// @returns {Array<Array<Real>>} The modified SH instance
function sh3_scale(sh, s) {
    gml_pragma("forceinline");
    for (var i = 0; i < 9; i++) {
        vec3_multiply_scalar(sh[i], s);
    }
    return sh;
}

/// @func sh3_lerp(sh, other, alpha)
/// @desc Linear interpolates between the given SH and this instance by alpha.
/// @param {Array<Array<Real>>} sh The SH instance to modify
/// @param {Array<Array<Real>>} other The SH to interpolate towards
/// @param {Real} alpha The interpolation factor
/// @returns {Array<Array<Real>>} The modified SH instance
function sh3_lerp(sh, other, alpha) {
    gml_pragma("forceinline");
    for (var i = 0; i < 9; i++) {
        vec3_lerp(sh[i], other[i], alpha);
    }
    return sh;
}

/// @func sh3_equals(sh, other)
/// @desc Checks if two SH instances are equal.
/// @param {Array<Array<Real>>} sh First SH
/// @param {Array<Array<Real>>} other Second SH
/// @returns {Bool}
function sh3_equals(sh, other) {
    gml_pragma("forceinline");
    for (var i = 0; i < 9; i++) {
        if (!vec3_equals(sh[i], other[i])) return false;
    }
    return true;
}

/// @func sh3_from_array(sh, array, offset = 0)
/// @desc Sets the SH coefficients from the given array of numbers (3 components per coeff).
/// @param {Array<Array<Real>>} sh The SH instance to modify
/// @param {Array<Real>} array The source array of numbers
/// @param {Real} [offset=0] Starting offset
/// @returns {Array<Array<Real>>} The modified SH instance
function sh3_from_array(sh, array, offset = 0) {
    gml_pragma("forceinline");
    for (var i = 0; i < 9; i++) {
        var idx = offset + i * 3;
        vec3_set(sh[i], array[idx], array[idx + 1], array[idx + 2]);
    }
    return sh;
}

/// @func sh3_to_array(sh, array = undefined, offset = 0)
/// @desc Copies the SH coefficients into the given array of numbers.
/// @param {Array<Array<Real>>} sh The SH instance
/// @param {Array<Real>} [array] Target array
/// @param {Real} [offset=0] Starting offset
/// @returns {Array<Real>} The result array
function sh3_to_array(sh, array = undefined, offset = 0) {
    gml_pragma("forceinline");
    array ??= array_create(27);
    for (var i = 0; i < 9; i++) {
        var idx = offset + i * 3;
        var v = sh[i];
        array[idx] = v[0];
        array[idx + 1] = v[1];
        array[idx + 2] = v[2];
    }
    return array;
}

/// @func sh3_get_at(sh, normal, target)
/// @desc Returns the radiance in the direction of the given normal.
/// @param {Array<Array<Real>>} sh The SH instance
/// @param {Array<Real>} normal The normal vector (assumed unit)
/// @param {Array<Real>} target The target Vector3
/// @returns {Array<Real>} The target vector
function sh3_get_at(sh, normal, target) {
    gml_pragma("forceinline");
    var _x = normal[0], _y = normal[1], _z = normal[2];
    
    // Basis functions
    var b0 = 0.282095;
    var b1 = 0.488603 * _y;
    var b2 = 0.488603 * _z;
    var b3 = 0.488603 * _x;
    var b4 = 1.092548 * _x * _y;
    var b5 = 1.092548 * _y * _z;
    var b6 = 0.315392 * (3 * _z * _z - 1);
    var b7 = 1.092548 * _x * _z;
    var b8 = 0.546274 * (_x * _x - _y * _y);
    
    vec3_set_scalar(target, 0);
    vec3_add_scaled_vector(target, sh[0], b0);
    vec3_add_scaled_vector(target, sh[1], b1);
    vec3_add_scaled_vector(target, sh[2], b2);
    vec3_add_scaled_vector(target, sh[3], b3);
    vec3_add_scaled_vector(target, sh[4], b4);
    vec3_add_scaled_vector(target, sh[5], b5);
    vec3_add_scaled_vector(target, sh[6], b6);
    vec3_add_scaled_vector(target, sh[7], b7);
    vec3_add_scaled_vector(target, sh[8], b8);
    
    return target;
}

/// @func sh3_get_irradiance_at(sh, normal, target)
/// @desc Returns the irradiance in the direction of the given normal.
/// @param {Array<Array<Real>>} sh The SH instance
/// @param {Array<Real>} normal The normal vector (assumed unit)
/// @param {Array<Real>} target The target Vector3
/// @returns {Array<Real>} The target vector
function sh3_get_irradiance_at(sh, normal, target) {
    gml_pragma("forceinline");
    var _x = normal[0], _y = normal[1], _z = normal[2];
    
    var c1 = 0.429043, c2 = 0.511664, c3 = 0.743125, c4 = 0.886227, c5 = 0.247708;
    
    vec3_copy(target, sh[0]);
    vec3_multiply_scalar(target, c4);
    
    vec3_add_scaled_vector(target, sh[1], 2 * c2 * _y);
    vec3_add_scaled_vector(target, sh[2], 2 * c2 * _z);
    vec3_add_scaled_vector(target, sh[3], 2 * c2 * _x);
    
    vec3_add_scaled_vector(target, sh[4], 2 * c1 * _x * _y);
    vec3_add_scaled_vector(target, sh[5], 2 * c1 * _y * _z);
    vec3_add_scaled_vector(target, sh[6], c3 * _z * _z - c5);
    vec3_add_scaled_vector(target, sh[7], 2 * c1 * _x * _z);
    vec3_add_scaled_vector(target, sh[8], c1 * (_x * _x - _y * _y));
    
    return target;
}

/// @func sh3_get_basis_at(normal, shBasis)
/// @desc Computes the SH basis for the given normal vector.
/// @param {Array<Real>} normal The normal vector
/// @param {Array<Real>} shBasis The target array (at least 9 elements)
function sh3_get_basis_at(normal, shBasis) {
    gml_pragma("forceinline");
    var _x = normal[0], _y = normal[1], _z = normal[2];
    shBasis[0] = 0.282095;
    shBasis[1] = 0.488603 * _y;
    shBasis[2] = 0.488603 * _z;
    shBasis[3] = 0.488603 * _x;
    shBasis[4] = 1.092548 * _x * _y;
    shBasis[5] = 1.092548 * _y * _z;
    shBasis[6] = 0.315392 * (3 * _z * _z - 1);
    shBasis[7] = 1.092548 * _x * _z;
    shBasis[8] = 0.546274 * (_x * _x - _y * _y);
}
