/// @desc Quaternion functions using arrays [x, y, z, w]
/// All functions modify the first quaternion in-place when applicable.
/// Rotation angles are in DEGREES.

// Global temp quaternion
global.UE_QUAT_TEMP0 = [0, 0, 0, 1];

enum QUAT {
  x, y, z, w
}

/// @func quat_create(x, y, z, w)
/// @desc Creates a new quaternion. Defaults to identity [0, 0, 0, 1].
/// @param {Real} [x=0] X component
/// @param {Real} [y=0] Y component
/// @param {Real} [z=0] Z component
/// @param {Real} [w=1] W component
/// @returns {Array<Real>} New quaternion
function quat_create(x = 0, y = 0, z = 0, w = 1) {
    gml_pragma("forceinline");
    return [x, y, z, w];
}

// ============================================================================
// SETTERS
// ============================================================================

/// @func quat_set(q, x, y, z, w)
/// @desc Sets the components of the quaternion.
/// @param {Array<Real>} q The quaternion to modify
/// @param {Real} x X component
/// @param {Real} y Y component
/// @param {Real} z Z component
/// @param {Real} w W component
/// @returns {Array<Real>} The modified quaternion
function quat_set(q, x, y, z, w) {
    gml_pragma("forceinline");
    q[0] = x;
    q[1] = y;
    q[2] = z;
    q[3] = w;
    return q;
}

/// @func quat_identity(q)
/// @desc Resets the quaternion to identity [0, 0, 0, 1].
/// @param {Array<Real>} q The quaternion to modify
/// @returns {Array<Real>} The modified quaternion
function quat_identity(q) {
    gml_pragma("forceinline");
    q[0] = 0;
    q[1] = 0;
    q[2] = 0;
    q[3] = 1;
    return q;
}

// ============================================================================
// CLONE / COPY
// ============================================================================

/// @func quat_clone(q)
/// @desc Creates a copy of the quaternion.
/// @param {Array<Real>} q The quaternion to clone
/// @returns {Array<Real>} A new quaternion with the same values
function quat_clone(q) {
    gml_pragma("forceinline");
    return [q[0], q[1], q[2], q[3]];
}

/// @func quat_copy(q, src)
/// @desc Copies value from source quaternion to target.
/// @param {Array<Real>} q The target quaternion
/// @param {Array<Real>} src The source quaternion
/// @returns {Array<Real>} The modified quaternion
function quat_copy(q, src) {
    gml_pragma("forceinline");
    q[0] = src[0];
    q[1] = src[1];
    q[2] = src[2];
    q[3] = src[3];
    return q;
}

// ============================================================================
// FROM ...
// ============================================================================

/// @func quat_set_from_euler(q, x, y, z, order)
/// @desc Sets quaternion from Euler angles (in degrees). Rotation order is YXZ
/// @param {Array<Real>} q The quaternion to modify
/// @param {Real} x Rotation around X in degrees
/// @param {Real} y Rotation around Y in degrees
/// @param {Real} z Rotation around Z in degrees
/// @param {String} [order="XYZ"] Rotation order
/// @returns {Array<Real>} The modified quaternion
function quat_set_from_euler(q, x, y, z) {
    gml_pragma("forceinline");
    // http://www.mathworks.com/matlabcentral/fileexchange/
    // 	20696-function-to-convert-between-dcm-euler-angles-quaternions-and-euler-vectors/
    //	content/SpinCalc.m
    
    var c1 = dcos(x * 0.5);
    var c2 = dcos(y * 0.5);
    var c3 = dcos(z * 0.5);
    
    var s1 = dsin(x * 0.5);
    var s2 = dsin(y * 0.5);
    var s3 = dsin(z * 0.5);
    
    q[0] = s1 * c2 * c3 + c1 * s2 * s3;
    q[1] = c1 * s2 * c3 - s1 * c2 * s3;
    q[2] = c1 * c2 * s3 - s1 * s2 * c3;
    q[3] = c1 * c2 * c3 + s1 * s2 * s3;
    return q;
}

/// @func quat_set_from_axis_angle(q, axis, angle)
/// @desc Sets quaternion from axis and angle (in degrees).
/// @param {Array<Real>} q The quaternion to modify
/// @param {Array<Real>} axis The normalized axis vector
/// @param {Real} angle The angle in degrees
/// @returns {Array<Real>} The modified quaternion
function quat_set_from_axis_angle(q, axis, angle) {
    gml_pragma("forceinline");
    // http://www.euclideanspace.com/maths/geometry/rotations/conversions/angleToQuaternion/index.htm
    // Assumes axis is normalized
    
    var halfAngle = angle * 0.5;
    var s = dsin(halfAngle);
    
    q[0] = axis[0] * s;
    q[1] = axis[1] * s;
    q[2] = axis[2] * s;
    q[3] = dcos(halfAngle);
    return q;
}

/// @func quat_set_from_rotation_matrix(q, m)
/// @desc Sets this quaternion from rotation component of a 4x4 matrix.
/// @param {Array<Real>} q The quaternion to modify
/// @param {Array<Real>} m The rotation matrix
/// @returns {Array<Real>} The modified quaternion
function quat_set_from_rotation_matrix(q, m) {
    gml_pragma("forceinline");
    // http://www.euclideanspace.com/maths/geometry/rotations/conversions/matrixToQuaternion/index.htm
    
    // Assume matrix is pure rotation (or extract scale first, but for now take upper 3x3)
    var m11 = m[0], m12 = m[4], m13 = m[8];
    var m21 = m[1], m22 = m[5], m23 = m[9];
    var m31 = m[2], m32 = m[6], m33 = m[10];

    var trace = m11 + m22 + m33;

    if (trace > 0) {
        var s = 0.5 / sqrt(trace + 1.0);
        q[3] = 0.25 / s;
        q[0] = (m32 - m23) * s;
        q[1] = (m13 - m31) * s;
        q[2] = (m21 - m12) * s;
    } else if (m11 > m22 && m11 > m33) {
        var s = 2.0 * sqrt(1.0 + m11 - m22 - m33);
        q[3] = (m32 - m23) / s;
        q[0] = 0.25 * s;
        q[1] = (m12 + m21) / s;
        q[2] = (m13 + m31) / s;
    } else if (m22 > m33) {
        var s = 2.0 * sqrt(1.0 + m22 - m11 - m33);
        q[3] = (m13 - m31) / s;
        q[0] = (m12 + m21) / s;
        q[1] = 0.25 * s;
        q[2] = (m23 + m32) / s;
    } else {
        var s = 2.0 * sqrt(1.0 + m33 - m11 - m22);
        q[3] = (m21 - m12) / s;
        q[0] = (m13 + m31) / s;
        q[1] = (m23 + m32) / s;
        q[2] = 0.25 * s;
    }
    return q;
}

/// @func quat_set_from_unit_vectors(q, vFrom, vTo)
/// @desc Sets quaternion to rotation required to rotate direction vFrom to vTo.
/// @param {Array<Real>} q The quaternion to modify
/// @param {Array<Real>} vFrom Normalized start vector
/// @param {Array<Real>} vTo Normalized end vector
/// @returns {Array<Real>} The modified quaternion
function quat_set_from_unit_vectors(q, vFrom, vTo) {
    gml_pragma("forceinline");
    // Assumes vFrom and vTo are normalized using vec3 functions externally if needed
    
    var v1x = vFrom[0], v1y = vFrom[1], v1z = vFrom[2];
    var v2x = vTo[0],   v2y = vTo[1],   v2z = vTo[2];
    
    var r = v1x * v2x + v1y * v2y + v1z * v2z + 1;
    
    if (r < 0.000001) {
        // Vectors are opposite
        r = 0;
        if (abs(v1x) > abs(v1z)) {
            q[0] = -v1y; q[1] = v1x; q[2] = 0; q[3] = r;
        } else {
            q[0] = 0; q[1] = -v1z; q[2] = v1y; q[3] = r;
        }
    } else {
        // Cross product
        q[0] = v1y * v2z - v1z * v2y;
        q[1] = v1z * v2x - v1x * v2z;
        q[2] = v1x * v2y - v1y * v2x;
        q[3] = r;
    }
    
    quat_normalize(q);
    return q;
}

// ============================================================================
// OPERATIONS
// ============================================================================

/// @func quat_invert(q)
/// @desc Inverts the quaternion (conjugate if normalized).
/// @param {Array<Real>} q The quaternion to invert
/// @returns {Array<Real>} The modified quaternion
function quat_invert(q) {
    gml_pragma("forceinline");
    // For unit quaternion, inverse = conjugate
    // But generally inverse = conjugate / dot(q, q)
    // We will assume normal usage where inverse ~= conjugate
    return quat_conjugate(q);
}

/// @func quat_conjugate(q)
/// @desc Conjugates the quaternion (-x, -y, -z, w).
/// @param {Array<Real>} q The quaternion
/// @returns {Array<Real>} The modified quaternion
function quat_conjugate(q) {
    gml_pragma("forceinline");
    q[0] *= -1;
    q[1] *= -1;
    q[2] *= -1;
    return q;
}

/// @func quat_dot(q, q2)
/// @desc Calculates dot product of two quaternions.
/// @param {Array<Real>} q First quaternion
/// @param {Array<Real>} q2 Second quaternion
/// @returns {Real} Dot product
function quat_dot(q, q2) {
    gml_pragma("forceinline");
    return q[0] * q2[0] + q[1] * q2[1] + q[2] * q2[2] + q[3] * q2[3];
}

/// @func quat_length_sq(q)
/// @desc Returns squared length of quaternion.
/// @param {Array<Real>} q The quaternion
/// @returns {Real} Squared length
function quat_length_sq(q) {
    gml_pragma("forceinline");
    return q[0]*q[0] + q[1]*q[1] + q[2]*q[2] + q[3]*q[3];
}

/// @func quat_length(q)
/// @desc Returns length of quaternion.
/// @param {Array<Real>} q The quaternion
/// @returns {Real} Length
function quat_length(q) {
    gml_pragma("forceinline");
    return sqrt(q[0]*q[0] + q[1]*q[1] + q[2]*q[2] + q[3]*q[3]);
}

/// @func quat_normalize(q)
/// @desc Normalizes the quaternion.
/// @param {Array<Real>} q The quaternion to normalize
/// @returns {Array<Real>} The modified quaternion
function quat_normalize(q) {
    gml_pragma("forceinline");
    var l = q[0]*q[0] + q[1]*q[1] + q[2]*q[2] + q[3]*q[3];
    if (l == 0) {
        q[0] = 0; q[1] = 0; q[2] = 0; q[3] = 1;
    } else {
        l = 1 / sqrt(l);
        q[0] *= l;
        q[1] *= l;
        q[2] *= l;
        q[3] *= l;
    }
    return q;
}

/// @func quat_multiply(q, q2)
/// @desc Multiplies quaternion q by q2 (q = q * q2).
/// @param {Array<Real>} q The quaternion to modify
/// @param {Array<Real>} q2 The quaternion to multiply with
/// @returns {Array<Real>} The modified quaternion
function quat_multiply(q, q2) {
    gml_pragma("forceinline");
    var qax = q[0], quay = q[1], qaz = q[2], qaw = q[3];
    var qbx = q2[0], qby = q2[1], qbz = q2[2], qbw = q2[3];
    
    q[0] = qax * qbw + qaw * qbx + quay * qbz - qaz * qby;
    q[1] = quay * qbw + qaw * qby + qaz * qbx - qax * qbz;
    q[2] = qaz * qbw + qaw * qbz + qax * qby - quay * qbx;
    q[3] = qaw * qbw - qax * qbx - quay * qby - qaz * qbz;
    return q;
}

/// @func quat_premultiply(q, q2)
/// @desc Multiplies quaternion q by q2 (q = q2 * q).
/// @param {Array<Real>} q The quaternion to modify
/// @param {Array<Real>} q2 The quaternion to multiply with
/// @returns {Array<Real>} The modified quaternion
function quat_premultiply(q, q2) {
    gml_pragma("forceinline");
    var qax = q2[0], quay = q2[1], qaz = q2[2], qaw = q2[3];
    var qbx = q[0], qby = q[1], qbz = q[2], qbw = q[3];
    
    q[0] = qax * qbw + qaw * qbx + quay * qbz - qaz * qby;
    q[1] = quay * qbw + qaw * qby + qaz * qbx - qax * qbz;
    q[2] = qaz * qbw + qaw * qbz + qax * qby - quay * qbx;
    q[3] = qaw * qbw - qax * qbx - quay * qby - qaz * qbz;
    return q;
}

/// @func quat_slerp(q, qb, t)
/// @desc Spherically interpolates between this quaternion and qb by t.
/// @param {Array<Real>} q The start quaternion (will be modified)
/// @param {Array<Real>} qb The target quaternion
/// @param {Real} t Interpolation factor [0..1]
/// @returns {Array<Real>} The modified quaternion
function quat_slerp(q, qb, t) {
    gml_pragma("forceinline");
    if (t == 0) return q;
    if (t == 1) {
        return quat_copy(q, qb);
    }
    
    var _x = q[0], _y = q[1], _z = q[2], _w = q[3];
    var bx = qb[0], by = qb[1], bz = qb[2], bw = qb[3];
    
    var cosHalfTheta = _w * bw + _x * bx + _y * by + _z * bz;
    
    if (cosHalfTheta < 0) {
        q[0] = -bx; q[1] = -by; q[2] = -bz; q[3] = -bw;
        cosHalfTheta = -cosHalfTheta;
    } else {
        quat_copy(q, qb);
    }
    
    if (cosHalfTheta >= 1.0) {
        q[0] = _x; q[1] = _y; q[2] = _z; q[3] = _w;
        return q;
    }
    
    var sqrSinHalfTheta = 1.0 - cosHalfTheta * cosHalfTheta;
    
    // If sinHalfTheta is too small, use linear interpolation
    if (sqrSinHalfTheta <= 0.000001) {
        var s = 1 - t;
        q[0] = s * _x + t * q[0];
        q[1] = s * _y + t * q[1];
        q[2] = s * _z + t * q[2];
        q[3] = s * _w + t * q[3];
        return quat_normalize(q);
    }
    
    var sinHalfTheta = sqrt(sqrSinHalfTheta);
    var halfTheta = arccos(cosHalfTheta);
    var ratioA = sin((1 - t) * halfTheta) / sinHalfTheta;
    var ratioB = sin(t * halfTheta) / sinHalfTheta;
    
    q[0] = (_x * ratioA + q[0] * ratioB);
    q[1] = (_y * ratioA + q[1] * ratioB);
    q[2] = (_z * ratioA + q[2] * ratioB);
    q[3] = (_w * ratioA + q[3] * ratioB);
    return q;
}

// ============================================================================
// UTILITIES
// ============================================================================

/// @func quat_equals(q, q2)
/// @desc Checks if two quaternions are exactly equal.
/// @param {Array<Real>} q First quaternion
/// @param {Array<Real>} q2 Second quaternion
/// @returns {Bool}
function quat_equals(q, q2) {
    gml_pragma("forceinline");
    return (q[0] == q2[0] && q[1] == q2[1] && q[2] == q2[2] && q[3] == q2[3]);
}

/// @func quat_from_array(q, array, offset)
/// @desc Reads quaternion from array.
/// @param {Array<Real>} q The quaternion to modify
/// @param {Array<Real>} array Source array
/// @param {Real} [offset=0] Index offset
/// @returns {Array<Real>} The modified quaternion
function quat_from_array(q, array, offset = 0) {
    gml_pragma("forceinline");
    q[0] = array[offset];
    q[1] = array[offset + 1];
    q[2] = array[offset + 2];
    q[3] = array[offset + 3];
    return q;
}

/// @func quat_to_array(q, array, offset)
/// @desc Writes quaternion to array.
/// @param {Array<Real>} q The quaternion
/// @param {Array<Real>} [array] Target array
/// @param {Real} [offset=0] Index offset
/// @returns {Array<Real>} The target array
function quat_to_array(q, array = undefined, offset = 0) {
    gml_pragma("forceinline");
    array ??= array_create(4);
    array[offset] = q[0];
    array[offset + 1] = q[1];
    array[offset + 2] = q[2];
    array[offset + 3] = q[3];
    return array;
}

function quat_angle_to(q, q2) {
    gml_pragma("forceinline");
    var d = quat_dot(q, q2);
    if (d > 1) d = 1; else if (d < -1) d = -1;
    return 2 * arccos(abs(d));
}

function quat_multiply_quaternions(dest, a, b) {
    gml_pragma("forceinline");
    var ax = a[0], ay = a[1], az = a[2], aw = a[3];
    var bx = b[0], by = b[1], bz = b[2], bw = b[3];
    dest[0] = ax * bw + aw * bx + ay * bz - az * by;
    dest[1] = ay * bw + aw * by + az * bx - ax * bz;
    dest[2] = az * bw + aw * bz + ax * by - ay * bx;
    dest[3] = aw * bw - ax * bx - ay * by - az * bz;
    return dest;
}

function quat_random(q) {
    gml_pragma("forceinline");
    var u1 = random_range(0, 1);
    var u2 = random_range(0, 1);
    var u3 = random_range(0, 1);
    var s1 = sqrt(1 - u1);
    var s2 = sqrt(u1);
    var t1 = 360 * u2;
    var t2 = 360 * u3;
    q[0] = s1 * dsin(t1);
    q[1] = s1 * dcos(t1);
    q[2] = s2 * dsin(t2);
    q[3] = s2 * dcos(t2);
    return q;
}

function quat_rotate_towards(q, qb, step) {
    gml_pragma("forceinline");
    var angle = quat_angle_to(q, qb);
    if (angle <= 0) return q;
    var t = min(1, step / angle);
    quat_slerp(q, qb, t);
    return q;
}

function quat_slerp_quaternions(dest, qa, qb, t) {
    gml_pragma("forceinline");
    quat_copy(dest, qa);
    quat_slerp(dest, qb, t);
    return dest;
}

function quat_from_buffer_attribute(q, attr, index) {
    gml_pragma("forceinline");
    var offset = index * 4;
    quat_from_array(q, attr, offset);
    return q;
}

function multiplyQuaternionsFlat(dst, dstOffset, src0, srcOffset0, src1, srcOffset1) {
    gml_pragma("forceinline");
    var ax = src0[srcOffset0], ay = src0[srcOffset0 + 1], az = src0[srcOffset0 + 2], aw = src0[srcOffset0 + 3];
    var bx = src1[srcOffset1], by = src1[srcOffset1 + 1], bz = src1[srcOffset1 + 2], bw = src1[srcOffset1 + 3];
    dst[dstOffset]     = ax * bw + aw * bx + ay * bz - az * by;
    dst[dstOffset + 1] = ay * bw + aw * by + az * bx - ax * bz;
    dst[dstOffset + 2] = az * bw + aw * bz + ax * by - ay * bx;
    dst[dstOffset + 3] = aw * bw - ax * bx - ay * by - az * bz;
    return dst;
}

function slerpFlat(dst, dstOffset, src0, srcOffset0, src1, srcOffset1, t) {
    gml_pragma("forceinline");
    var x0 = src0[srcOffset0], y0 = src0[srcOffset0 + 1], z0 = src0[srcOffset0 + 2], w0 = src0[srcOffset0 + 3];
    var x1 = src1[srcOffset1], y1 = src1[srcOffset1 + 1], z1 = src1[srcOffset1 + 2], w1 = src1[srcOffset1 + 3];
    
    if (t <= 0) {
        dst[dstOffset] = x0; dst[dstOffset + 1] = y0; dst[dstOffset + 2] = z0; dst[dstOffset + 3] = w0;
        return dst;
    }
    if (t >= 1) {
        dst[dstOffset] = x1; dst[dstOffset + 1] = y1; dst[dstOffset + 2] = z1; dst[dstOffset + 3] = w1;
        return dst;
    }
    
    var cosHalfTheta = w0 * w1 + x0 * x1 + y0 * y1 + z0 * z1;
    if (cosHalfTheta < 0) {
        x1 = -x1; y1 = -y1; z1 = -z1; w1 = -w1;
        cosHalfTheta = -cosHalfTheta;
    }
    if (cosHalfTheta >= 1.0) {
        dst[dstOffset] = x0; dst[dstOffset + 1] = y0; dst[dstOffset + 2] = z0; dst[dstOffset + 3] = w0;
        return dst;
    }
    var sqrSinHalfTheta = 1.0 - cosHalfTheta * cosHalfTheta;
    if (sqrSinHalfTheta <= 0.000001) {
        var s = 1 - t;
        var rx = s * x0 + t * x1;
        var ry = s * y0 + t * y1;
        var rz = s * z0 + t * z1;
        var rw = s * w0 + t * w1;
        var l = rx*rx + ry*ry + rz*rz + rw*rw;
        if (l != 0) {
            l = 1 / sqrt(l);
            rx *= l; ry *= l; rz *= l; rw *= l;
        } else {
            rx = 0; ry = 0; rz = 0; rw = 1;
        }
        dst[dstOffset] = rx; dst[dstOffset + 1] = ry; dst[dstOffset + 2] = rz; dst[dstOffset + 3] = rw;
        return dst;
    }
    var sinHalfTheta = sqrt(sqrSinHalfTheta);
    var halfTheta = arccos(cosHalfTheta);
    var ratioA = sin((1 - t) * halfTheta) / sinHalfTheta;
    var ratioB = sin(t * halfTheta) / sinHalfTheta;
    dst[dstOffset]     = x0 * ratioA + x1 * ratioB;
    dst[dstOffset + 1] = y0 * ratioA + y1 * ratioB;
    dst[dstOffset + 2] = z0 * ratioA + z1 * ratioB;
    dst[dstOffset + 3] = w0 * ratioA + w1 * ratioB;
    return dst;
}
