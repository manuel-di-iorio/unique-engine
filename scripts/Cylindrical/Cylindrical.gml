/// @desc 3D Cylindrical coordinates [radius, theta, y]
/// Angles are in RADIANS.
/// theta is a counterclockwise angle in the x-z plane measured from the positive z-axis.

enum CYLINDRICAL {
    radius, theta, y
}

/// @func cyl_create(radius, theta, y)
/// @desc Creates a new cylindrical coordinate array.
/// @param {Real} [radius=1.0] The radius
/// @param {Real} [theta=0.0] The theta angle in radians
/// @param {Real} [y=0.0] The height
/// @returns {Array<Real>} New cylindrical array
function cyl_create(radius = 1.0, theta = 0.0, _y = 0.0) {
    gml_pragma("forceinline");
    return [radius, theta, _y];
}

/// @func cyl_set(c, radius, theta, y)
/// @desc Sets the cylindrical components.
/// @param {Array<Real>} c The cylindrical array to modify
/// @param {Real} radius The radius
/// @param {Real} theta The theta angle
/// @param {Real} y The height value
/// @returns {Array<Real>} The modified cylindrical array
function cyl_set(c, radius, theta, _y) {
    gml_pragma("forceinline");
    c[0] = radius;
    c[1] = theta;
    c[2] = _y;
    return c;
}

/// @func cyl_copy(c, other)
/// @desc Copies the values of the given cylindrical to this instance.
/// @param {Array<Real>} c The cylindrical array to modify
/// @param {Array<Real>} other The cylindrical to copy
/// @returns {Array<Real>} The modified cylindrical array
function cyl_copy(c, other) {
    gml_pragma("forceinline");
    c[0] = other[0];
    c[1] = other[1];
    c[2] = other[2];
    return c;
}

/// @func cyl_clone(c)
/// @desc Returns a new cylindrical with copied values from this instance.
/// @param {Array<Real>} c The cylindrical array to clone
/// @returns {Array<Real>} A clone of the cylindrical
function cyl_clone(c) {
    gml_pragma("forceinline");
    return [c[0], c[1], c[2]];
}

/// @func cyl_set_from_cartesian_coords(c, x, y, z)
/// @desc Sets the cylindrical components from the given Cartesian coordinates.
/// @param {Array<Real>} c The cylindrical array to modify
/// @param {Real} x The x value
/// @param {Real} y The y value
/// @param {Real} z The z value
/// @returns {Array<Real>} The modified cylindrical array
function cyl_set_from_cartesian_coords(c, x, y, z) {
    gml_pragma("forceinline");
    c[0] = sqrt(x * x + z * z);
    c[1] = arctan2(x, z);
    c[2] = y;
    return c;
}

/// @func cyl_set_from_vector3(c, v)
/// @desc Sets the cylindrical components from the given vector which is assumed to hold Cartesian coordinates.
/// @param {Array<Real>} c The cylindrical array to modify
/// @param {Array<Real>} v The vector [x, y, z]
/// @returns {Array<Real>} The modified cylindrical array
function cyl_set_from_vector3(c, v) {
    gml_pragma("forceinline");
    return cyl_set_from_cartesian_coords(c, v[0], v[1], v[2]);
}
