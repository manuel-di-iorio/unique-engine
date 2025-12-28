/// @desc 3x3 matrix functions using arrays [m0, m1, m2, m3, m4, m5, m6, m7, m8]
/// All matrices are stored in COLUMN-MAJOR order
/// All functions modify the first matrix in-place when applicable for zero allocations.
/// Rotation angles are in DEGREES.

// Global temp matrix for temporary operations
global.UE_MAT3_TEMP0 = [1, 0, 0, 0, 1, 0, 0, 0, 1];

/// @func mat3_create()
/// @desc Creates a new identity 3x3 matrix.
/// @returns {Array<Real>} New identity matrix
function mat3_create() {
    gml_pragma("forceinline");
    return [1, 0, 0, 0, 1, 0, 0, 0, 1];
}

// ============================================================================
// SETTERS
// ============================================================================

/// @func mat3_set(m, n11, n12, n13, n21, n22, n23, n31, n32, n33)
/// @desc Sets the matrix elements. Arguments are in ROW-MAJOR order for readability.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} n11 Row 1, Col 1
/// @param {Real} n12 Row 1, Col 2
/// @param {Real} n13 Row 1, Col 3
/// @param {Real} n21 Row 2, Col 1
/// @param {Real} n22 Row 2, Col 2
/// @param {Real} n23 Row 2, Col 3
/// @param {Real} n31 Row 3, Col 1
/// @param {Real} n32 Row 3, Col 2
/// @param {Real} n33 Row 3, Col 3
/// @returns {Array<Real>} The modified matrix
function mat3_set(m, n11, n12, n13, n21, n22, n23, n31, n32, n33) {
    gml_pragma("forceinline");
    // Store in column-major order
    m[0] = n11; m[1] = n21; m[2] = n31;
    m[3] = n12; m[4] = n22; m[5] = n32;
    m[6] = n13; m[7] = n23; m[8] = n33;
    return m;
}

/// @func mat3_identity(m)
/// @desc Sets this matrix to the 3x3 identity matrix.
/// @param {Array<Real>} m The matrix to modify
/// @returns {Array<Real>} The modified matrix
function mat3_identity(m) {
    gml_pragma("forceinline");
    m[0] = 1; m[1] = 0; m[2] = 0;
    m[3] = 0; m[4] = 1; m[5] = 0;
    m[6] = 0; m[7] = 0; m[8] = 1;
    return m;
}

// ============================================================================
// CLONE / COPY
// ============================================================================

/// @func mat3_clone(m)
/// @desc Returns a matrix with copied values from this instance.
/// @param {Array<Real>} m The matrix to clone
/// @returns {Array<Real>} A clone of the matrix
function mat3_clone(m) {
    gml_pragma("forceinline");
    return [m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7], m[8]];
}

/// @func mat3_copy(m, src)
/// @desc Copies the values of the given matrix to this instance.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} src The matrix to copy
/// @returns {Array<Real>} The modified matrix
function mat3_copy(m, src) {
    gml_pragma("forceinline");
    m[0] = src[0]; m[1] = src[1]; m[2] = src[2];
    m[3] = src[3]; m[4] = src[4]; m[5] = src[5];
    m[6] = src[6]; m[7] = src[7]; m[8] = src[8];
    return m;
}

// ============================================================================
// DETERMINANT / INVERSION
// ============================================================================

/// @func mat3_determinant(m)
/// @desc Computes and returns the determinant of this matrix.
/// @param {Array<Real>} m The matrix
/// @returns {Real} The determinant
function mat3_determinant(m) {
    gml_pragma("forceinline");
    var a = m[0], d = m[3], g = m[6];
    var b = m[1], e = m[4], h = m[7];
    var c = m[2], f = m[5], i = m[8];
    return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
}

/// @func mat3_invert(m)
/// @desc Inverts this matrix. If determinant is zero, produces a zero matrix.
/// @param {Array<Real>} m The matrix to invert
/// @returns {Array<Real>} The modified matrix
function mat3_invert(m) {
    gml_pragma("forceinline");
    var a = m[0], d = m[3], g = m[6];
    var b = m[1], e = m[4], h = m[7];
    var c = m[2], f = m[5], i = m[8];

    var det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);

    if (det == 0) {
        m[0] = 0; m[1] = 0; m[2] = 0;
        m[3] = 0; m[4] = 0; m[5] = 0;
        m[6] = 0; m[7] = 0; m[8] = 0;
        return m;
    }

    var invDet = 1 / det;

    m[0] = (e * i - f * h) * invDet;
    m[1] = -(b * i - c * h) * invDet;
    m[2] = (b * f - c * e) * invDet;
    m[3] = -(d * i - f * g) * invDet;
    m[4] = (a * i - c * g) * invDet;
    m[5] = -(a * f - c * d) * invDet;
    m[6] = (d * h - e * g) * invDet;
    m[7] = -(a * h - b * g) * invDet;
    m[8] = (a * e - b * d) * invDet;
    return m;
}

// ============================================================================
// TRANSPOSE
// ============================================================================

/// @func mat3_transpose(m)
/// @desc Transposes this matrix in place.
/// @param {Array<Real>} m The matrix to transpose
/// @returns {Array<Real>} The modified matrix
function mat3_transpose(m) {
    gml_pragma("forceinline");
    var tmp;
    tmp = m[1]; m[1] = m[3]; m[3] = tmp;
    tmp = m[2]; m[2] = m[6]; m[6] = tmp;
    tmp = m[5]; m[5] = m[7]; m[7] = tmp;
    return m;
}

/// @func mat3_transpose_into_array(m, arr)
/// @desc Transposes this matrix into the supplied array, and returns itself unchanged.
/// @param {Array<Real>} m The matrix
/// @param {Array<Real>} arr An array to store the transposed matrix elements
/// @returns {Array<Real>} The array used to store the transposed matrix elements
function mat3_transpose_into_array(m, arr) {
    gml_pragma("forceinline");
    arr[0] = m[0]; arr[1] = m[3]; arr[2] = m[6];
    arr[3] = m[1]; arr[4] = m[4]; arr[5] = m[7];
    arr[6] = m[2]; arr[7] = m[5]; arr[8] = m[8];
    return arr;
}

// ============================================================================
// EQUALITY
// ============================================================================

/// @func mat3_equals(m, m2)
/// @desc Returns true if this matrix is equal with the given one.
/// @param {Array<Real>} m First matrix
/// @param {Array<Real>} m2 The matrix to test for equality
/// @returns {Bool} Whether this matrix is equal with the given one
function mat3_equals(m, m2) {
    gml_pragma("forceinline");
    return m[0] == m2[0] && m[1] == m2[1] && m[2] == m2[2] &&
        m[3] == m2[3] && m[4] == m2[4] && m[5] == m2[5] &&
        m[6] == m2[6] && m[7] == m2[7] && m[8] == m2[8];
}

// ============================================================================
// MULTIPLICATION
// ============================================================================

/// @func mat3_multiply(m, m2)
/// @desc Post-multiplies this matrix by the given 3x3 matrix (m = m * m2).
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} m2 The matrix to multiply with
/// @returns {Array<Real>} The modified matrix
function mat3_multiply(m, m2) {
    gml_pragma("forceinline");
    var a0 = m[0], a1 = m[1], a2 = m[2];
    var a3 = m[3], a4 = m[4], a5 = m[5];
    var a6 = m[6], a7 = m[7], a8 = m[8];

    var b0 = m2[0], b1 = m2[1], b2 = m2[2];
    var b3 = m2[3], b4 = m2[4], b5 = m2[5];
    var b6 = m2[6], b7 = m2[7], b8 = m2[8];

    m[0] = a0 * b0 + a3 * b1 + a6 * b2;
    m[1] = a1 * b0 + a4 * b1 + a7 * b2;
    m[2] = a2 * b0 + a5 * b1 + a8 * b2;

    m[3] = a0 * b3 + a3 * b4 + a6 * b5;
    m[4] = a1 * b3 + a4 * b4 + a7 * b5;
    m[5] = a2 * b3 + a5 * b4 + a8 * b5;

    m[6] = a0 * b6 + a3 * b7 + a6 * b8;
    m[7] = a1 * b6 + a4 * b7 + a7 * b8;
    m[8] = a2 * b6 + a5 * b7 + a8 * b8;
    return m;
}

/// @func mat3_premultiply(m, m2)
/// @desc Pre-multiplies this matrix by the given 3x3 matrix (m = m2 * m).
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} m2 The matrix to multiply with
/// @returns {Array<Real>} The modified matrix
function mat3_premultiply(m, m2) {
    gml_pragma("forceinline");
    var a0 = m2[0], a1 = m2[1], a2 = m2[2];
    var a3 = m2[3], a4 = m2[4], a5 = m2[5];
    var a6 = m2[6], a7 = m2[7], a8 = m2[8];

    var b0 = m[0], b1 = m[1], b2 = m[2];
    var b3 = m[3], b4 = m[4], b5 = m[5];
    var b6 = m[6], b7 = m[7], b8 = m[8];

    m[0] = a0 * b0 + a3 * b1 + a6 * b2;
    m[1] = a1 * b0 + a4 * b1 + a7 * b2;
    m[2] = a2 * b0 + a5 * b1 + a8 * b2;

    m[3] = a0 * b3 + a3 * b4 + a6 * b5;
    m[4] = a1 * b3 + a4 * b4 + a7 * b5;
    m[5] = a2 * b3 + a5 * b4 + a8 * b5;

    m[6] = a0 * b6 + a3 * b7 + a6 * b8;
    m[7] = a1 * b6 + a4 * b7 + a7 * b8;
    m[8] = a2 * b6 + a5 * b7 + a8 * b8;
    return m;
}

/// @func mat3_multiply_matrices(m, a, b)
/// @desc Multiplies the given 3x3 matrices and stores the result in this matrix.
/// @param {Array<Real>} m The matrix to store result
/// @param {Array<Real>} a The first matrix
/// @param {Array<Real>} b The second matrix
function mat3_multiply_matrices(m, a, b) {
    gml_pragma("forceinline");
    var a0 = a[0], a1 = a[1], a2 = a[2];
    var a3 = a[3], a4 = a[4], a5 = a[5];
    var a6 = a[6], a7 = a[7], a8 = a[8];

    var b0 = b[0], b1 = b[1], b2 = b[2];
    var b3 = b[3], b4 = b[4], b5 = b[5];
    var b6 = b[6], b7 = b[7], b8 = b[8];

    m[0] = a0 * b0 + a3 * b1 + a6 * b2;
    m[1] = a1 * b0 + a4 * b1 + a7 * b2;
    m[2] = a2 * b0 + a5 * b1 + a8 * b2;

    m[3] = a0 * b3 + a3 * b4 + a6 * b5;
    m[4] = a1 * b3 + a4 * b4 + a7 * b5;
    m[5] = a2 * b3 + a5 * b4 + a8 * b5;

    m[6] = a0 * b6 + a3 * b7 + a6 * b8;
    m[7] = a1 * b6 + a4 * b7 + a7 * b8;
    m[8] = a2 * b6 + a5 * b7 + a8 * b8;
}

/// @func mat3_multiply_scalar(m, s)
/// @desc Multiplies each element of this matrix by the given scalar.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} s The scalar value
/// @returns {Array<Real>} The modified matrix
function mat3_multiply_scalar(m, s) {
    gml_pragma("forceinline");
    m[0] *= s; m[1] *= s; m[2] *= s;
    m[3] *= s; m[4] *= s; m[5] *= s;
    m[6] *= s; m[7] *= s; m[8] *= s;
    return m;
}

// ============================================================================
// 2D TRANSFORM MAKERS (in DEGREES)
// ============================================================================

/// @func mat3_make_rotation(m, angle)
/// @desc Sets this matrix as a 2D rotational transformation.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} angle The rotation in degrees
function mat3_make_rotation(m, angle) {
    gml_pragma("forceinline");
    var c = dcos(angle);
    var s = dsin(angle);
    m[0] = c; m[1] = s; m[2] = 0;
    m[3] = -s; m[4] = c; m[5] = 0;
    m[6] = 0; m[7] = 0; m[8] = 1;
}

/// @func mat3_make_scale(m, x, y)
/// @desc Sets this matrix as a 2D scale transform.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} x The amount to scale in the X axis
/// @param {Real} y The amount to scale in the Y axis
function mat3_make_scale(m, x, y) {
    gml_pragma("forceinline");
    m[0] = x; m[1] = 0; m[2] = 0;
    m[3] = 0; m[4] = y; m[5] = 0;
    m[6] = 0; m[7] = 0; m[8] = 1;
}

/// @func mat3_make_translation(m, x, y)
/// @desc Sets this matrix as a 2D translation transform.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} x The amount to translate in the X axis
/// @param {Real} y The amount to translate in the Y axis
function mat3_make_translation(m, x, y) {
    gml_pragma("forceinline");
    m[0] = 1; m[1] = 0; m[2] = 0;
    m[3] = 0; m[4] = 1; m[5] = 0;
    m[6] = x; m[7] = y; m[8] = 1;
}

// ============================================================================
// 2D TRANSFORM OPERATIONS (in DEGREES)
// ============================================================================

/// @func mat3_rotate(m, angle)
/// @desc Rotates this matrix by the given angle.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} angle The rotation in degrees
function mat3_rotate(m, angle) {
    gml_pragma("forceinline");
    var c = dcos(angle);
    var s = dsin(angle);

    var a0 = m[0], a1 = m[1], a2 = m[2];
    var a3 = m[3], a4 = m[4], a5 = m[5];

    m[0] = a0 * c + a3 * s;
    m[1] = a1 * c + a4 * s;
    m[2] = a2 * c + a5 * s;

    m[3] = a0 * -s + a3 * c;
    m[4] = a1 * -s + a4 * c;
    m[5] = a2 * -s + a5 * c;
}

/// @func mat3_scale(m, sx, sy)
/// @desc Scales this matrix with the given scalar values.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} sx The amount to scale in the X axis
/// @param {Real} sy The amount to scale in the Y axis
function mat3_scale(m, sx, sy) {
    gml_pragma("forceinline");
    m[0] *= sx; m[1] *= sx; m[2] *= sx;
    m[3] *= sy; m[4] *= sy; m[5] *= sy;
}

/// @func mat3_translate(m, tx, ty)
/// @desc Translates this matrix by the given scalar values.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} tx The amount to translate in the X axis
/// @param {Real} ty The amount to translate in the Y axis
function mat3_translate(m, tx, ty) {
    gml_pragma("forceinline");
    m[6] += m[0] * tx + m[3] * ty;
    m[7] += m[1] * tx + m[4] * ty;
    m[8] += m[2] * tx + m[5] * ty;
}

// ============================================================================
// EXTRACT / CONVERT
// ============================================================================

/// @func mat3_extract_basis(m, xAxis, yAxis, zAxis)
/// @desc Extracts the basis of this matrix into the three axis vectors provided.
/// @param {Array<Real>} m The matrix
/// @param {Array<Real>} xAxis The basis's x axis (vec3)
/// @param {Array<Real>} yAxis The basis's y axis (vec3)
/// @param {Array<Real>} zAxis The basis's z axis (vec3)
function mat3_extract_basis(m, xAxis, yAxis, zAxis) {
    gml_pragma("forceinline");
    xAxis[0] = m[0]; xAxis[1] = m[1]; xAxis[2] = m[2];
    yAxis[0] = m[3]; yAxis[1] = m[4]; yAxis[2] = m[5];
    zAxis[0] = m[6]; zAxis[1] = m[7]; zAxis[2] = m[8];
}

/// @func mat3_set_from_matrix4(m, m4)
/// @desc Sets this matrix to the upper 3x3 portion of the given 4x4 matrix.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} m4 The 4x4 matrix
/// @returns {Array<Real>} The modified matrix
function mat3_set_from_matrix4(m, m4) {
    gml_pragma("forceinline");
    m[0] = m4[0]; m[1] = m4[1]; m[2] = m4[2];
    m[3] = m4[4]; m[4] = m4[5]; m[5] = m4[6];
    m[6] = m4[8]; m[7] = m4[9]; m[8] = m4[10];
    return m;
}

/// @func mat3_set_from_basis(m, xAxis, yAxis, zAxis)
/// @desc Sets this matrix from the given basis vectors.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} xAxis The x-axis vector
/// @param {Array<Real>} yAxis The y-axis vector
/// @param {Array<Real>} zAxis The z-axis vector
/// @returns {Array<Real>} The modified matrix
function mat3_set_from_basis(m, xAxis, yAxis, zAxis) {
    gml_pragma("forceinline");
    m[0] = xAxis[0]; m[1] = xAxis[1]; m[2] = xAxis[2];
    m[3] = yAxis[0]; m[4] = yAxis[1]; m[5] = yAxis[2];
    m[6] = zAxis[0]; m[7] = zAxis[1]; m[8] = zAxis[2];
    return m;
}

// ============================================================================
// QUATERNION CONVERSION
// ============================================================================

/// @func mat3_set_from_quaternion(m, q)
/// @desc Sets this matrix to the rotation matrix corresponding to the given quaternion.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} q The quaternion [x, y, z, w]
/// @returns {Array<Real>} The modified matrix
function mat3_set_from_quaternion(m, q) {
    gml_pragma("forceinline");
    var _x = q[0], _y = q[1], z = q[2], w = q[3];
    var x2 = _x + _x, y2 = _x + _y, z2 = z + z;
    var xx = _x * x2, xy = _x * y2, xz = _x * z2;
    var yy = _y * y2, yz = _y * z2, zz = z * z2;
    var wx = w * x2, wy = w * y2, wz = w * z2;

    m[0] = 1 - (yy + zz);
    m[3] = xy - wz;
    m[6] = xz + wy;

    m[1] = xy + wz;
    m[4] = 1 - (xx + zz);
    m[7] = yz - wx;

    m[2] = xz - wy;
    m[5] = yz + wx;
    m[8] = 1 - (xx + yy);
    return m;
}

// ============================================================================
// NORMAL MATRIX
// ============================================================================

/// @func mat3_get_normal_matrix(m, m4)
/// @desc Sets this matrix as the normal matrix (transpose of inverse) of the upper-left 3x3 portion of the given 4x4 matrix.
/// @param {Array<Real>} m The matrix to store the result
/// @param {Array<Real>} m4 The 4x4 matrix to compute from
/// @returns {Array<Real>} The modified matrix
function mat3_get_normal_matrix(m, m4) {
    gml_pragma("forceinline");
    // Extract upper-left 3x3 and then invert/transpose
    m[0] = m4[0]; m[1] = m4[1]; m[2] = m4[2];
    m[3] = m4[4]; m[4] = m4[5]; m[5] = m4[6];
    m[6] = m4[8]; m[7] = m4[9]; m[8] = m4[10];

    mat3_invert(m);
    mat3_transpose(m);
    return m;
}

// ============================================================================
// UV TRANSFORM
// ============================================================================

/// @func mat3_set_uv_transform(m, tx, ty, sx, sy, rotation, cx, cy)
/// @desc Sets the UV transform matrix from offset, repeat, rotation, and center.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} tx Offset x
/// @param {Real} ty Offset y
/// @param {Real} sx Repeat x
/// @param {Real} sy Repeat y
/// @param {Real} rotation Rotation in degrees
/// @param {Real} cx Center x of rotation
/// @param {Real} cy Center y of rotation
function mat3_set_uv_transform(m, tx, ty, sx, sy, rotation, cx, cy) {
    gml_pragma("forceinline");
    var c = dcos(rotation);
    var s = dsin(rotation);

    // Build UV transform matrix
    var m0 = sx * c;
    var m1 = sx * s;
    var m3 = -sy * s;
    var m4 = sy * c;

    m[0] = m0;
    m[1] = m1;
    m[2] = 0;
    m[3] = m3;
    m[4] = m4;
    m[5] = 0;
    m[6] = tx + cx - cx * m0 - cy * m3;
    m[7] = ty + cy - cx * m1 - cy * m4;
    m[8] = 1;
}

// ============================================================================
// ARRAY CONVERSION
// ============================================================================

/// @func mat3_from_array(m, array, offset)
/// @desc Sets the elements of the matrix from the given array.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} array The matrix elements in column-major order
/// @param {Real} [offset=0] Index of the first element in the array
function mat3_from_array(m, array, offset = 0) {
    gml_pragma("forceinline");
    m[0] = array[offset]; m[1] = array[offset + 1]; m[2] = array[offset + 2];
    m[3] = array[offset + 3]; m[4] = array[offset + 4]; m[5] = array[offset + 5];
    m[6] = array[offset + 6]; m[7] = array[offset + 7]; m[8] = array[offset + 8];
}

/// @func mat3_to_array(m, array, offset)
/// @desc Writes the elements of this matrix to the given array.
/// @param {Array<Real>} m The matrix
/// @param {Array<Real>} [array] The target array (creates new if undefined)
/// @param {Real} [offset=0] Index of the first element in the array
/// @returns {Array<Real>} The matrix elements in column-major order
function mat3_to_array(m, array = undefined, offset = 0) {
    gml_pragma("forceinline");
    array ??= array_create(9);
    array[offset] = m[0]; array[offset + 1] = m[1]; array[offset + 2] = m[2];
    array[offset + 3] = m[3]; array[offset + 4] = m[4]; array[offset + 5] = m[5];
    array[offset + 6] = m[6]; array[offset + 7] = m[7]; array[offset + 8] = m[8];
    return array;
}
