/// @desc Dual Quaternion functions using arrays [rx, ry, rz, rw, dx, dy, dz, dw]
/// The first 4 elements are the real part (rotation), the last 4 are the dual part.
/// All functions modify the first dual quaternion in-place when applicable.

enum DUALQUAT {
    rx, ry, rz, rw,
    dx, dy, dz, dw
}

/// @func dualquat_create(rx, ry, rz, rw, dx, dy, dz, dw)
/// @desc Creates a new dual quaternion. Defaults to identity.
function dualquat_create(_rx = 0, _ry = 0, _rz = 0, _rw = 1, _dx = 0, _dy = 0, _dz = 0, _dw = 0) {
    gml_pragma("forceinline");
    return [_rx, _ry, _rz, _rw, _dx, _dy, _dz, _dw];
}

/// @func dualquat_identity(dq)
/// @desc Resets the dual quaternion to identity.
function dualquat_identity(dq) {
    gml_pragma("forceinline");
    dq[0] = 0; dq[1] = 0; dq[2] = 0; dq[3] = 1;
    dq[4] = 0; dq[5] = 0; dq[6] = 0; dq[7] = 0;
    return dq;
}

/// @func dualquat_set(dq, rx, ry, rz, rw, dx, dy, dz, dw)
/// @desc Sets all components of the dual quaternion.
function dualquat_set(dq, _rx, _ry, _rz, _rw, _dx, _dy, _dz, _dw) {
    gml_pragma("forceinline");
    dq[0] = _rx; dq[1] = _ry; dq[2] = _rz; dq[3] = _rw;
    dq[4] = _dx; dq[5] = _dy; dq[6] = _dz; dq[7] = _dw;
    return dq;
}

/// @func dualquat_copy(dq, src)
/// @desc Copies values from source to target.
function dualquat_copy(dq, src) {
    gml_pragma("forceinline");
    dq[0] = src[0]; dq[1] = src[1]; dq[2] = src[2]; dq[3] = src[3];
    dq[4] = src[4]; dq[5] = src[5]; dq[6] = src[6]; dq[7] = src[7];
    return dq;
}

/// @func dualquat_clone(dq)
/// @desc Creates a copy of the dual quaternion.
function dualquat_clone(dq) {
    gml_pragma("forceinline");
    return [dq[0], dq[1], dq[2], dq[3], dq[4], dq[5], dq[6], dq[7]];
}

/// @func dualquat_from_translation_rotation(dq, translation, rotation)
/// @desc Sets dual quaternion from a translation (Vector3) and rotation (Quaternion).
function dualquat_from_translation_rotation(dq, translation, rotation) {
    gml_pragma("forceinline");
    var rx = rotation[0], ry = rotation[1], rz = rotation[2], rw = rotation[3];
    var tx = translation[0], ty = translation[1], tz = translation[2];
    
    dq[0] = rx;
    dq[1] = ry;
    dq[2] = rz;
    dq[3] = rw;
    
    dq[4] =  0.5 * ( tx * rw + ty * rz - tz * ry);
    dq[5] =  0.5 * (-tx * rz + ty * rw + tz * rx);
    dq[6] =  0.5 * ( tx * ry - ty * rx + tz * rw);
    dq[7] = -0.5 * ( tx * rx + ty * ry + tz * rz);
    
    return dq;
}

/// @func dualquat_to_translation_rotation(dq, translation, rotation)
/// @desc Extracts translation (Vector3) and rotation (Quaternion) from dual quaternion.
function dualquat_to_translation_rotation(dq, translation, rotation) {
    gml_pragma("forceinline");
    var rx = dq[0], ry = dq[1], rz = dq[2], rw = dq[3];
    var dx = dq[4], dy = dq[5], dz = dq[6], dw = dq[7];
    
    rotation[0] = rx;
    rotation[1] = ry;
    rotation[2] = rz;
    rotation[3] = rw;
    
    translation[0] = 2.0 * (-dw * rx + dx * rw - dy * rz + dz * ry);
    translation[1] = 2.0 * (-dw * ry + dx * rz + dy * rw - dz * rx);
    translation[2] = 2.0 * (-dw * rz - dx * ry + dy * rx + dz * rw);
    
    return dq;
}

/// @func dualquat_multiply(dq, dq2)
/// @desc Multiplies dq by dq2 (dq = dq * dq2).
function dualquat_multiply(dq, dq2) {
    gml_pragma("forceinline");
    var ax = dq[0], ay = dq[1], az = dq[2], aw = dq[3];
    var adx = dq[4], ady = dq[5], adz = dq[6], adw = dq[7];
    var bx = dq2[0], by = dq2[1], bz = dq2[2], bw = dq2[3];
    var bdx = dq2[4], bdy = dq2[5], bdz = dq2[6], bdw = dq2[7];

    // Real part
    dq[0] = ax * bw + aw * bx + ay * bz - az * by;
    dq[1] = ay * bw + aw * by + az * bx - ax * bz;
    dq[2] = az * bw + aw * bz + ax * by - ay * bx;
    dq[3] = aw * bw - ax * bx - ay * by - az * bz;

    // Dual part
    dq[4] = ax * bdw + aw * bdx + ay * bdz - az * bdy + adx * bw + adw * bx + ady * bz - adz * by;
    dq[5] = ay * bdw + aw * bdy + az * bdx - ax * bdz + ady * bw + adw * by + adz * bx - adx * bz;
    dq[6] = az * bdw + aw * bdz + ax * bdy - ay * bdx + adz * bw + adw * bz + adx * by - ady * bx;
    dq[7] = aw * bdw - ax * bdx - ay * bdy - az * bdz + adw * bw - adx * bx - ady * by - adz * bz;

    return dq;
}

/// @func dualquat_normalize(dq)
/// @desc Normalizes the dual quaternion.
function dualquat_normalize(dq) {
    gml_pragma("forceinline");
    var rx = dq[0], ry = dq[1], rz = dq[2], rw = dq[3];
    var magSq = rx*rx + ry*ry + rz*rz + rw*rw;
    
    if (magSq > 0) {
        var invMag = 1.0 / sqrt(magSq);
        dq[0] *= invMag;
        dq[1] *= invMag;
        dq[2] *= invMag;
        dq[3] *= invMag;
        
        var dot = dq[0] * dq[4] + dq[1] * dq[5] + dq[2] * dq[6] + dq[3] * dq[7];
        dq[4] = (dq[4] - dq[0] * dot) * invMag;
        dq[5] = (dq[5] - dq[1] * dot) * invMag;
        dq[6] = (dq[6] - dq[2] * dot) * invMag;
        dq[7] = (dq[7] - dq[3] * dot) * invMag;
    }
    return dq;
}

/// @func dualquat_conjugate(dq)
/// @desc Conjugates the dual quaternion.
function dualquat_conjugate(dq) {
    gml_pragma("forceinline");
    dq[0] = -dq[0];
    dq[1] = -dq[1];
    dq[2] = -dq[2];
    dq[4] = -dq[4];
    dq[5] = -dq[5];
    dq[6] = -dq[6];
    return dq;
}

/// @func dualquat_invert(dq)
/// @desc Inverts the dual quaternion.
function dualquat_invert(dq) {
    gml_pragma("forceinline");
    // For unit dual quaternions, inverse is same as conjugate
    return dualquat_conjugate(dq);
}

/// @func dualquat_dot(dq1, dq2)
/// @desc Returns the dot product of the real parts.
function dualquat_dot(dq1, dq2) {
    gml_pragma("forceinline");
    return dq1[0] * dq2[0] + dq1[1] * dq2[1] + dq1[2] * dq2[2] + dq1[3] * dq2[3];
}

/// @func dualquat_transform_vec3(dq, v, target)
/// @desc Transforms a Vector3 by the dual quaternion.
function dualquat_transform_vec3(dq, v, target) {
    gml_pragma("forceinline");
    var rx = dq[0], ry = dq[1], rz = dq[2], rw = dq[3];
    var dx = dq[4], dy = dq[5], dz = dq[6], dw = dq[7];
    var vx = v[0], vy = v[1], vz = v[2];

    // Translation extracted from DQ
    var tx = 2.0 * (-dw * rx + dx * rw - dy * rz + dz * ry);
    var ty = 2.0 * (-dw * ry + dx * rz + dy * rw - dz * rx);
    var tz = 2.0 * (-dw * rz - dx * ry + dy * rx + dz * rw);

    // Rotation
    var ix =  rw * vx + ry * vz - rz * vy;
    var iy =  rw * vy + rz * vx - rx * vz;
    var iz =  rw * vz + rx * vy - ry * vx;
    var iw = -rx * vx - ry * vy - rz * vz;

    target[0] = ix * rw + iw * -rx + iy * -rz - iz * -ry + tx;
    target[1] = iy * rw + iw * -ry + iz * -rx - ix * -rz + ty;
    target[2] = iz * rw + iw * -rz + ix * -ry - iy * -rx + tz;

    return target;
}

/// @func dualquat_equals(dq1, dq2)
/// @desc Checks if two dual quaternions are equal.
function dualquat_equals(dq1, dq2) {
    gml_pragma("forceinline");
    return dq1[0] == dq2[0] && dq1[1] == dq2[1] && dq1[2] == dq2[2] && dq1[3] == dq2[3] &&
           dq1[4] == dq2[4] && dq1[5] == dq2[5] && dq1[6] == dq2[6] && dq1[7] == dq2[7];
}

/// @func dualquat_premultiply(dq, dq2)
/// @desc Premultiplies dq by dq2 (dq = dq2 * dq).
function dualquat_premultiply(dq, dq2) {
    gml_pragma("forceinline");
    var bx = dq[0], by = dq[1], bz = dq[2], bw = dq[3];
    var bdx = dq[4], bdy = dq[5], bdz = dq[6], bdw = dq[7];
    var ax = dq2[0], ay = dq2[1], az = dq2[2], aw = dq2[3];
    var adx = dq2[4], ady = dq2[5], adz = dq2[6], adw = dq2[7];

    // Real part
    dq[0] = ax * bw + aw * bx + ay * bz - az * by;
    dq[1] = ay * bw + aw * by + az * bx - ax * bz;
    dq[2] = az * bw + aw * bz + ax * by - ay * bx;
    dq[3] = aw * bw - ax * bx - ay * by - az * bz;

    // Dual part
    dq[4] = ax * bdw + aw * bdx + ay * bdz - az * bdy + adx * bw + adw * bx + ady * bz - adz * by;
    dq[5] = ay * bdw + aw * bdy + az * bdx - ax * bdz + ady * bw + adw * by + adz * bx - adx * bz;
    dq[6] = az * bdw + aw * bdz + ax * bdy - ay * bdx + adz * bw + adw * bz + adx * by - ady * bx;
    dq[7] = aw * bdw - ax * bdx - ay * bdy - az * bdz + adw * bw - adx * bx - ady * by - adz * bz;

    return dq;
}

/// @func dualquat_multiply_dualquaternions(dest, a, b)
/// @desc Sets dest = a * b.
function dualquat_multiply_dualquaternions(dest, a, b) {
    gml_pragma("forceinline");
    var ax = a[0], ay = a[1], az = a[2], aw = a[3];
    var adx = a[4], ady = a[5], adz = a[6], adw = a[7];
    var bx = b[0], by = b[1], bz = b[2], bw = b[3];
    var bdx = b[4], bdy = b[5], bdz = b[6], bdw = b[7];

    dest[0] = ax * bw + aw * bx + ay * bz - az * by;
    dest[1] = ay * bw + aw * by + az * bx - ax * bz;
    dest[2] = az * bw + aw * bz + ax * by - ay * bx;
    dest[3] = aw * bw - ax * bx - ay * by - az * bz;

    dest[4] = ax * bdw + aw * bdx + ay * bdz - az * bdy + adx * bw + adw * bx + ady * bz - adz * by;
    dest[5] = ay * bdw + aw * bdy + az * bdx - ax * bdz + ady * bw + adw * by + adz * bx - adx * bz;
    dest[6] = az * bdw + aw * bdz + ax * bdy - ay * bdx + adz * bw + adw * bz + adx * by - ady * bx;
    dest[7] = aw * bdw - ax * bdx - ay * bdy - az * bdz + adw * bw - adx * bx - ady * by - adz * bz;

    return dest;
}

/// @func dualquat_from_array(dq, array, offset = 0)
/// @desc Reads dual quaternion from array.
function dualquat_from_array(dq, array, offset = 0) {
    gml_pragma("forceinline");
    dq[0] = array[offset];
    dq[1] = array[offset + 1];
    dq[2] = array[offset + 2];
    dq[3] = array[offset + 3];
    dq[4] = array[offset + 4];
    dq[5] = array[offset + 5];
    dq[6] = array[offset + 6];
    dq[7] = array[offset + 7];
    return dq;
}

/// @func dualquat_to_array(dq, array = undefined, offset = 0)
/// @desc Writes dual quaternion to array.
function dualquat_to_array(dq, array = undefined, offset = 0) {
    gml_pragma("forceinline");
    array ??= array_create(8);
    array[offset]     = dq[0];
    array[offset + 1] = dq[1];
    array[offset + 2] = dq[2];
    array[offset + 3] = dq[3];
    array[offset + 4] = dq[4];
    array[offset + 5] = dq[5];
    array[offset + 6] = dq[6];
    array[offset + 7] = dq[7];
    return array;
}

/// @func dualquat_dlerp(dq, dq2, t)
/// @desc Dual Linear Interpolation (faster than ScLERP).
function dualquat_dlerp(dq, dq2, t) {
    gml_pragma("forceinline");
    var dot = dualquat_dot(dq, dq2);
    var t1 = 1.0 - t;
    
    if (dot < 0) {
        t = -t;
    }
    
    dq[0] = dq[0] * t1 + dq2[0] * t;
    dq[1] = dq[1] * t1 + dq2[1] * t;
    dq[2] = dq[2] * t1 + dq2[2] * t;
    dq[3] = dq[3] * t1 + dq2[3] * t;
    dq[4] = dq[4] * t1 + dq2[4] * t;
    dq[5] = dq[5] * t1 + dq2[5] * t;
    dq[6] = dq[6] * t1 + dq2[6] * t;
    dq[7] = dq[7] * t1 + dq2[7] * t;
    
    return dualquat_normalize(dq);
}

/// @func dualquat_to_matrix4(dq, m)
/// @desc Converts dual quaternion to 4x4 matrix.
function dualquat_to_matrix4(dq, m) {
    gml_pragma("forceinline");
    var rx = dq[0], ry = dq[1], rz = dq[2], rw = dq[3];
    var dx = dq[4], dy = dq[5], dz = dq[6], dw = dq[7];

    var x2 = rx + rx, y2 = ry + ry, z2 = rz + rz;
    var xx = rx * x2, xy = rx * y2, xz = rx * z2;
    var yy = ry * y2, yz = ry * z2, zz = rz * z2;
    var wx = rw * x2, wy = rw * y2, wz = rw * z2;

    m[0] = 1 - (yy + zz);
    m[1] = xy + wz;
    m[2] = xz - wy;
    m[3] = 0;

    m[4] = xy - wz;
    m[5] = 1 - (xx + zz);
    m[6] = yz + wx;
    m[7] = 0;

    m[8] = xz + wy;
    m[9] = yz - wx;
    m[10] = 1 - (xx + yy);
    m[11] = 0;

    m[12] = 2.0 * (-dw * rx + dx * rw - dy * rz + dz * ry);
    m[13] = 2.0 * (-dw * ry + dx * rz + dy * rw - dz * rx);
    m[14] = 2.0 * (-dw * rz - dx * ry + dy * rx + dz * rw);
    m[15] = 1;

    return m;
}

/// @func dualquat_get_translation(dq, target)
/// @desc Convenience to get translation part.
function dualquat_get_translation(dq, target) {
    gml_pragma("forceinline");
    var rx = dq[0], ry = dq[1], rz = dq[2], rw = dq[3];
    var dx = dq[4], dy = dq[5], dz = dq[6], dw = dq[7];
    target[0] = 2.0 * (-dw * rx + dx * rw - dy * rz + dz * ry);
    target[1] = 2.0 * (-dw * ry + dx * rz + dy * rw - dz * rx);
    target[2] = 2.0 * (-dw * rz - dx * ry + dy * rx + dz * rw);
    return target;
}

/// @func dualquat_get_rotation(dq, target)
/// @desc Convenience to get rotation part.
function dualquat_get_rotation(dq, target) {
    gml_pragma("forceinline");
    target[0] = dq[0];
    target[1] = dq[1];
    target[2] = dq[2];
    target[3] = dq[3];
    return target;
}
