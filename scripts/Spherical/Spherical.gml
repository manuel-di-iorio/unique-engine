/// @desc Spherical coordinates [radius, phi, theta]
/// Angles are in RADIANS.
/// phi is the polar angle from the y (up) axis.
/// theta is the equator/azimuthal angle around the y (up) axis.

enum SPHERICAL {
    radius, phi, theta
}

/// @func spherical_create(radius, phi, theta)
/// @desc Creates a new spherical coordinate array.
/// @param {Real} [radius=1.0] The radius
/// @param {Real} [phi=0.0] The polar angle in radians
/// @param {Real} [theta=0.0] The azimuthal angle in radians
/// @returns {Array<Real>} New spherical array
function spherical_create(radius = 1.0, phi = 0.0, theta = 0.0) {
    gml_pragma("forceinline");
    return [radius, phi, theta];
}

/// @func spherical_set(s, radius, phi, theta)
/// @desc Sets the spherical components.
/// @param {Array<Real>} s The spherical array to modify
/// @param {Real} radius The radius
/// @param {Real} phi The polar angle
/// @param {Real} theta The azimuthal angle
/// @returns {Array<Real>} The modified spherical array
function spherical_set(s, radius, phi, theta) {
    gml_pragma("forceinline");
    s[0] = radius;
    s[1] = phi;
    s[2] = theta;
    return s;
}

/// @func spherical_copy(s, other)
/// @desc Copies the values of the given spherical to this instance.
/// @param {Array<Real>} s The spherical array to modify
/// @param {Array<Real>} other The spherical to copy
/// @returns {Array<Real>} The modified spherical array
function spherical_copy(s, other) {
    gml_pragma("forceinline");
    s[0] = other[0];
    s[1] = other[1];
    s[2] = other[2];
    return s;
}

/// @func spherical_clone(s)
/// @desc Returns a new spherical with copied values from this instance.
/// @param {Array<Real>} s The spherical array to clone
/// @returns {Array<Real>} A clone of the spherical
function spherical_clone(s) {
    gml_pragma("forceinline");
    return [s[0], s[1], s[2]];
}

/// @func spherical_make_safe(s)
/// @desc Restricts the polar angle phi to be between 0.000001 and pi - 0.000001.
/// @param {Array<Real>} s The spherical array to modify
/// @returns {Array<Real>} The modified spherical array
function spherical_make_safe(s) {
    gml_pragma("forceinline");
    var eps = 0.0001;
    s[1] = clamp(s[1], eps, pi - eps);
    return s;
}

/// @func spherical_set_from_cartesian_coords(s, x, y, z)
/// @desc Sets the spherical components from the given Cartesian coordinates.
/// @param {Array<Real>} s The spherical array to modify
/// @param {Real} x The x value
/// @param {Real} y The y value
/// @param {Real} z The z value
/// @returns {Array<Real>} The modified spherical array
function spherical_set_from_cartesian_coords(s, x, y, z) {
    gml_pragma("forceinline");
    var radius = sqrt(x * x + y * y + z * z);
    s[0] = radius;
    if (radius == 0) {
        s[1] = 0;
        s[2] = 0;
    } else {
        s[1] = arccos(clamp(y / radius, -1, 1));
        s[2] = arctan2(x, z);
    }
    return s;
}

/// @func spherical_set_from_vector3(s, v)
/// @desc Sets the spherical components from the given vector which is assumed to hold Cartesian coordinates.
/// @param {Array<Real>} s The spherical array to modify
/// @param {Array<Real>} v The vector [x, y, z]
/// @returns {Array<Real>} The modified spherical array
function spherical_set_from_vector3(s, v) {
    gml_pragma("forceinline");
    return spherical_set_from_cartesian_coords(s, v[0], v[1], v[2]);
}
