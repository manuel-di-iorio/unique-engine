/// @desc Euler functions using arrays [x, y, z]
/// Angles are in DEGREES. Rotation order: "YXZ".

enum EULER {
  x, y, z
}

function euler_create(x = 0, y = 0, z = 0) {
    gml_pragma("forceinline");
    return [x, y, z];
}

/// @func euler_set(e, x, y, z)
/// @desc Sets the euler angles (in degrees).
/// @param {Array<Real>} e The euler array to modify
/// @param {Real} x The x angle
/// @param {Real} y The y angle
/// @param {Real} z The z angle
/// @returns {Array<Real>} The modified euler array
function euler_set(e, x, y, z) {
    gml_pragma("forceinline");
    e[0] = x;
    e[1] = y;
    e[2] = z;
    return e;
}

/// @func euler_copy(e, src)
/// @desc Copies euler angles from one array to another.
/// @param {Array<Real>} e The target array (will be modified)
/// @param {Array<Real>} src The source array
/// @returns {Array<Real>} The modified euler array
function euler_copy(e, src) {
    gml_pragma("forceinline");
    e[0] = src[0];
    e[1] = src[1];
    e[2] = src[2];
    return e;
}

/// @func euler_clone(e)
/// @desc Creates a new euler array with the same angles.
/// @param {Array<Real>} e The euler array to clone
/// @returns {Array<Real>} A new euler array
function euler_clone(e) {
    gml_pragma("forceinline");
    return [e[0], e[1], e[2]];
}

/// @func euler_from_array(e, array, offset = 0)
/// @desc Sets euler angles from a flat array.
/// @param {Array<Real>} e The euler array to modify
/// @param {Array<Real>} array The source flat array
/// @param {Real} [offset=0] Starting offset
/// @returns {Array<Real>} The modified euler array
function euler_from_array(e, array, offset = 0) {
    gml_pragma("forceinline");
    e[0] = array[offset];
    e[1] = array[offset + 1];
    e[2] = array[offset + 2];
    return e;
}

/// @func euler_to_array(e, array = undefined, offset = 0)
/// @desc Copies euler angles to a flat array.
/// @param {Array<Real>} e The euler array
/// @param {Array<Real>} [array] Optional target array
/// @param {Real} [offset=0] Starting offset
/// @returns {Array<Real>} The target array
function euler_to_array(e, array = undefined, offset = 0) {
    gml_pragma("forceinline");
    array ??= array_create(3);
    array[offset] = e[0];
    array[offset + 1] = e[1];
    array[offset + 2] = e[2];
    return array;
}

/// @func euler_set_from_vector3(e, v)
/// @desc Sets euler angles from a Vector3.
/// @param {Array<Real>} e The euler array to modify
/// @param {Array<Real>} v The Vector3 [x, y, z]
/// @returns {Array<Real>} The modified euler array
function euler_set_from_vector3(e, v) {
    gml_pragma("forceinline");
    e[0] = v[0];
    e[1] = v[1];
    e[2] = v[2];
    return e;
}

/// @func euler_set_from_rotation_matrix(e, m)
/// @desc Sets euler angles from a rotation matrix (YXZ CW).
function euler_set_from_rotation_matrix(e, m) {
    gml_pragma("forceinline");
    
    // Extraction for YXZ Clockwise matrix
    var m11 = m[0], m12 = m[4], m13 = m[8];
    var m21 = m[1], m22 = m[5], m23 = m[9];
    var m31 = m[2], m32 = m[6], m33 = m[10];
    
    // In CW YXZ:
    // m23 = sin(x)
    e[0] = darcsin(clamp(m23, -1, 1));
    
    if (abs(m23) < 0.9999999) {
        // m13 = -sin(y)cos(x), m33 = cos(y)cos(x)
        e[1] = darctan2(-m13, m33);
        // m21 = -sin(z)cos(x), m22 = cos(z)cos(x)
        e[2] = darctan2(-m21, m22);
    } else {
        // gimbal lock
        e[1] = darctan2(m31, m11);
        e[2] = 0;
    }
    
    return e;
}

/// @func euler_set_from_quaternion(e, q)
/// @desc Sets euler angles from a quaternion (YXZ CW).
function euler_set_from_quaternion(e, q) {
    gml_pragma("forceinline");

    var _x = q[0], _y = q[1], _z = q[2], w = q[3];

    var x2 = _x + _x, y2 = _y + _y, z2 = _z + _z;
    var xx = _x * x2, xy = _x * y2, xz = _x * z2;
    var yy = _y * y2, yz = _y * z2, zz = _z * z2;
    var wx = w * _x + w * _x, wy = w * _y + w * _y, wz = w * _z + w * _z;

    // Rotation matrix (YXZ, CW, RH)
    var m11 = 1 - (yy + zz);
    var m12 = xy - wz;
    var m13 = xz + wy;

    var m21 = xy + wz;
    var m22 = 1 - (xx + zz);
    var m23 = yz - wx;

    var m31 = xz - wy;
    var m32 = yz + wx;
    var m33 = 1 - (xx + yy);

    // X (pitch)
    e[0] = darcsin(clamp(-m23, -1, 1));

    if (abs(m23) < 0.9999999) {
        // Y (yaw)
        e[1] = darctan2(m13, m33);
        // Z (roll)
        e[2] = darctan2(m21, m22);
    } else {
        // gimbal lock
        e[1] = darctan2(-m31, m11);
        e[2] = 0;
    }

    return e;
}


function euler_equals(e1, e2) {
    gml_pragma("forceinline");
    return (e1[0] == e2[0] && e1[1] == e2[1] && e1[2] == e2[2]);
}
