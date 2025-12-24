/// @desc Euler functions using arrays [x, y, z]
/// Angles are in DEGREES. Rotation order: "YXZ".

function euler_create(x = 0, y = 0, z = 0) {
    gml_pragma("forceinline");
    return [x, y, z];
}

function euler_set(e, x, y, z) {
    gml_pragma("forceinline");
    e[0] = x;
    e[1] = y;
    e[2] = z;
}

function euler_copy(e, src) {
    gml_pragma("forceinline");
    e[0] = src[0];
    e[1] = src[1];
    e[2] = src[2];
}

function euler_clone(e) {
    gml_pragma("forceinline");
    return [e[0], e[1], e[2]];
}

function euler_from_array(e, array, offset = 0) {
    gml_pragma("forceinline");
    e[0] = array[offset];
    e[1] = array[offset + 1];
    e[2] = array[offset + 2];
    var idx = offset + 3;
}

function euler_to_array(e, array = undefined, offset = 0) {
    gml_pragma("forceinline");
    array ??= array_create(3);
    array[offset] = e[0];
    array[offset + 1] = e[1];
    array[offset + 2] = e[2];
    return array;
}

function euler_set_from_vector3(e, v) {
    gml_pragma("forceinline");
    e[0] = v[0];
    e[1] = v[1];
    e[2] = v[2];
}

/// @func euler_set_from_rotation_matrix(e, m)
/// @desc Sets euler angles from rotation matrix.
function euler_set_from_rotation_matrix(e, m) {
    gml_pragma("forceinline");
    
    // Clamp matrix elements to [-1, 1] to avoid NaNs from asin/acos?
    // GML's darcsin/darccos handle inputs naturally but clamping is safer for floats
    
    var m11 = m[0], m12 = m[4], m13 = m[8];
    var m21 = m[1], m22 = m[5], m23 = m[9];
    var m31 = m[2], m32 = m[6], m33 = m[10];
    
    var _x, _y, _z;
    _x = darcsin(-clamp(m23, -1, 1));
    if (abs(m23) < 0.9999999) {
        _y = darctan2(m13, m33);
        _z = darctan2(m21, m22);
    } else {
        _y = darctan2(-m31, m11);
        _z = 0;
    }
    
    e[0] = _x;
    e[1] = _y;
    e[2] = _z;
}

/// @func euler_set_from_quaternion(e, q)
/// @desc Sets euler angles from quaternion.
function euler_set_from_quaternion(e, q) {
    gml_pragma("forceinline");
    // Matrix conversion is often easier/robust
    // We can build a rotation matrix from quaternion then extract euler
    
    var _x = q[0], _y = q[1], _z = q[2], _w = q[3];
    var x2 = _x + _x, y2 = _y + _y, z2 = _z + _z;
    var xx = _x * x2, xy = _x * y2, xz = _x * z2;
    var yy = _y * y2, yz = _y * z2, zz = _z * z2;
    var wx = _w * x2, wy = _w * y2, wz = _w * z2;
    
    // Matrix elements
    var m11 = 1 - (yy + zz);
    var m12 = xy - wz;
    var m13 = xz + wy;
    
    var m21 = xy + wz;
    var m22 = 1 - (xx + zz);
    var m23 = yz - wx;
    
    var m31 = xz - wy;
    var m32 = yz + wx;
    var m33 = 1 - (xx + yy);

    // Reuse matrix extraction logic (duplicated for performance/independence or could wrap)
    
    var rx, ry, rz;
    rx = darcsin(-clamp(m23, -1, 1));
    if (abs(m23) < 0.9999999) {
        ry = darctan2(m13, m33);
        rz = darctan2(m21, m22);
    } else {
        ry = darctan2(-m31, m11);
        rz = 0;
    }
    
    e[0] = rx;
    e[1] = ry;
    e[2] = rz;
}

function euler_equals(e1, e2) {
    gml_pragma("forceinline");
    return (e1[0] == e2[0] && e1[1] == e2[1] && e1[2] == e2[2] && e1[3] == e2[3]);
}
