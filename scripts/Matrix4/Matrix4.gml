/// @desc 4x4 matrix functions using arrays [16 elements]
/// All matrices are stored in COLUMN-MAJOR order
/// All functions modify the first matrix in-place when applicable for zero allocations.
/// Rotation angles are in DEGREES.

// Global temp matrix for temporary operations
global.UE_MAT4_IDENTITY = matrix_build_identity();
global.UE_MAT4_TEMP0 = matrix_build_identity();

/// @func mat4_create()
/// @desc Creates a new identity 4x4 matrix.
/// @returns {Array<Real>} New identity matrix
function mat4_create() {
  gml_pragma("forceinline");
  return matrix_build_identity();
}

// ============================================================================
// SETTERS
// ============================================================================

/// @func mat4_set(m, n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44)
/// @desc Sets the matrix elements. Arguments are in ROW-MAJOR order for readability.
/// @param {Array<Real>} m The matrix to modify
/// @returns {Array<Real>} The modified matrix
function mat4_set(m, n11, n12, n13, n14, n21, n22, n23, n24, n31, n32, n33, n34, n41, n42, n43, n44) {
  gml_pragma("forceinline");
  // Store in column-major order
  m[0] = n11; m[1] = n21; m[2] = n31; m[3] = n41;
  m[4] = n12; m[5] = n22; m[6] = n32; m[7] = n42;
  m[8] = n13; m[9] = n23; m[10] = n33; m[11] = n43;
  m[12] = n14; m[13] = n24; m[14] = n34; m[15] = n44;
  return m;
}

/// @func mat4_identity(m)
/// @desc Sets this matrix to the 4x4 identity matrix.
/// @param {Array<Real>} m The matrix to modify
/// @returns {Array<Real>} The modified matrix
function mat4_identity(m) {
  gml_pragma("forceinline");
  m[0] = 1; m[1] = 0; m[2] = 0; m[3] = 0;
  m[4] = 0; m[5] = 1; m[6] = 0; m[7] = 0;
  m[8] = 0; m[9] = 0; m[10] = 1; m[11] = 0;
  m[12] = 0; m[13] = 0; m[14] = 0; m[15] = 1;  
  return m;
}

// ============================================================================
// CLONE / COPY
// ============================================================================

/// @func mat4_clone(m)
/// @desc Returns a matrix with copied values from this instance.
/// @param {Array<Real>} m The matrix to clone
/// @returns {Array<Real>} A clone of the matrix
function mat4_clone(m) {
  gml_pragma("forceinline");
  return [m[0], m[1], m[2], m[3], m[4], m[5], m[6], m[7],
  m[8], m[9], m[10], m[11], m[12], m[13], m[14], m[15]];
}

/// @func mat4_copy(m, src)
/// @desc Copies the values of the given matrix to this instance.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} src The matrix to copy
/// @returns {Array<Real>} The modified matrix
function mat4_copy(m, src) {
  gml_pragma("forceinline");
  m[0] = src[0]; m[1] = src[1]; m[2] = src[2]; m[3] = src[3];
  m[4] = src[4]; m[5] = src[5]; m[6] = src[6]; m[7] = src[7];
  m[8] = src[8]; m[9] = src[9]; m[10] = src[10]; m[11] = src[11];
  m[12] = src[12]; m[13] = src[13]; m[14] = src[14]; m[15] = src[15];
  return m;
}

/// @func mat4_copy_position(m, src)
/// @desc Copies the translation component of the given matrix into this matrix.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} src The matrix to copy translation from
/// @returns {Array<Real>} The modified matrix
function mat4_copy_position(m, src) {
  gml_pragma("forceinline");
  m[12] = src[12];
  m[13] = src[13];
  m[14] = src[14];
  return m;
}

// ============================================================================
// DETERMINANT / INVERSION
// ============================================================================

/// @func mat4_determinant(m)
/// @desc Computes and returns the determinant of this matrix.
/// @param {Array<Real>} m The matrix
/// @returns {Real} The determinant
function mat4_determinant(m) {
  gml_pragma("forceinline");
  var a00 = m[0], a01 = m[4], a02 = m[8], a03 = m[12];
  var a10 = m[1], a11 = m[5], a12 = m[9], a13 = m[13];
  var a20 = m[2], a21 = m[6], a22 = m[10], a23 = m[14];
  var a30 = m[3], a31 = m[7], a32 = m[11], a33 = m[15];

  var b00 = a00 * a11 - a01 * a10;
  var b01 = a00 * a12 - a02 * a10;
  var b02 = a00 * a13 - a03 * a10;
  var b03 = a01 * a12 - a02 * a11;
  var b04 = a01 * a13 - a03 * a11;
  var b05 = a02 * a13 - a03 * a12;
  var b06 = a20 * a31 - a21 * a30;
  var b07 = a20 * a32 - a22 * a30;
  var b08 = a20 * a33 - a23 * a30;
  var b09 = a21 * a32 - a22 * a31;
  var b10 = a21 * a33 - a23 * a31;
  var b11 = a22 * a33 - a23 * a32;

  return b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
}

/// @func mat4_invert(m)
/// @desc Inverts this matrix. If determinant is zero, produces a zero matrix.
/// @param {Array<Real>} m The matrix to invert
/// @returns {Array<Real>} The modified matrix
function mat4_invert(m) {
  gml_pragma("forceinline");
  matrix_inverse(m, m);
  return m;
}

// ============================================================================
// TRANSPOSE
// ============================================================================

/// @func mat4_transpose(m)
/// @desc Transposes this matrix in place.
/// @param {Array<Real>} m The matrix to transpose
/// @returns {Array<Real>} The modified matrix
function mat4_transpose(m) {
  gml_pragma("forceinline");
  var tmp;
  tmp = m[1]; m[1] = m[4]; m[4] = tmp;
  tmp = m[2]; m[2] = m[8]; m[8] = tmp;
  tmp = m[3]; m[3] = m[12]; m[12] = tmp;
  tmp = m[6]; m[6] = m[9]; m[9] = tmp;
  tmp = m[7]; m[7] = m[13]; m[13] = tmp;
  tmp = m[11]; m[11] = m[14]; m[14] = tmp;
  return m;
}

// ============================================================================
// EQUALITY
// ============================================================================

/// @func mat4_equals(m, m2)
/// @desc Returns true if this matrix is equal with the given one.
/// @param {Array<Real>} m First matrix
/// @param {Array<Real>} other The matrix to test for equality
/// @returns {Bool} Whether this matrix is equal with the given one
function mat4_equals(m, m2) {
  gml_pragma("forceinline");
  for (var i = 0; i < 16; i++) {
    if (m[i] != m2[i]) return false;
  }
  return true;
}

// ============================================================================
// MULTIPLICATION
// ============================================================================

/// @func mat4_multiply(m, m2)
/// @desc Post-multiplies this matrix by the given 4x4 matrix (m = m * m2).
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} m2 The matrix to multiply with
/// @returns {Array<Real>} The modified matrix
function mat4_multiply(m, m2) {
  gml_pragma("forceinline");
  matrix_multiply(m2, m, m);
  return m;
}

/// @func mat4_premultiply(m, m2)
/// @desc Pre-multiplies this matrix by the given 4x4 matrix (m = m2 * m).
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} m2 The matrix to multiply with
/// @returns {Array<Real>} The modified matrix
function mat4_premultiply(m, m2) {
  gml_pragma("forceinline");
  matrix_multiply(m, m2, m);
  return m;
}

/// @func mat4_multiply_matrices(m, a, b)
/// @desc Multiplies the given 4x4 matrices and stores the result in this matrix.
/// @param {Array<Real>} m The matrix to store result
/// @param {Array<Real>} a The first matrix
/// @param {Array<Real>} b The second matrix
/// @returns {Array<Real>} The modified matrix
function mat4_multiply_matrices(m, a, b) {
  gml_pragma("forceinline");
  matrix_multiply(b, a, m);
  return m;
}

/// @func mat4_multiply_scalar(m, s)
/// @desc Multiplies every component of the matrix by the given scalar.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} s The scalar
/// @returns {Array<Real>} The modified matrix
function mat4_multiply_scalar(m, s) {
  gml_pragma("forceinline");
  for (var i = 0; i < 16; i++) m[i] *= s;
  return m;
}

// ============================================================================
// TRANSFORM MAKERS (in DEGREES)
// ============================================================================

/// @func mat4_make_translation(m, x, y, z)
/// @desc Sets this matrix as a translation transform.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} x Translation X
/// @param {Real} y Translation Y
/// @param {Real} z Translation Z
/// @returns {Array<Real>} The modified matrix
function mat4_make_translation(m, x, y, z) {
  gml_pragma("forceinline");
  matrix_build(x, y, z, 0, 0, 0, 1, 1, 1, m);
  return m;
}

/// @func mat4_make_scale(m, x, y, z)
/// @desc Sets this matrix as a scale transformation.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} x Scale X
/// @param {Real} y Scale Y
/// @param {Real} z Scale Z
/// @returns {Array<Real>} The modified matrix
function mat4_make_scale(m, x, y, z) {
  gml_pragma("forceinline");
  matrix_build(0, 0, 0, 0, 0, 0, x, y, z, m);
  return m;
}

/// @func mat4_make_rotation_x(m, angle)
/// @desc Sets this matrix as a rotational transformation around the X axis.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} angle The rotation in degrees
/// @returns {Array<Real>} The modified matrix
function mat4_make_rotation_x(m, angle) {
  gml_pragma("forceinline");
  matrix_build(0, 0, 0, angle, 0, 0, 1, 1, 1, m);
  return m;
}

/// @func mat4_make_rotation_y(m, angle)
/// @desc Sets this matrix as a rotational transformation around the Y axis.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} angle The rotation in degrees
/// @returns {Array<Real>} The modified matrix
function mat4_make_rotation_y(m, angle) {
  gml_pragma("forceinline");
  matrix_build(0, 0, 0, 0, angle, 0, 1, 1, 1, m);
  return m;
}

/// @func mat4_make_rotation_z(m, angle)
/// @desc Sets this matrix as a rotational transformation around the Z axis.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} angle The rotation in degrees
/// @returns {Array<Real>} The modified matrix
function mat4_make_rotation_z(m, angle) {
  gml_pragma("forceinline");
  matrix_build(0, 0, 0, 0, 0, angle, 1, 1, 1, m);
  return m;
}

/// @func mat4_make_rotation_axis(m, axis, angle)
/// @desc Sets this matrix as a rotational transformation around the given axis.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} axis The normalized rotation axis (vec3)
/// @param {Real} angle The rotation in degrees
/// @returns {Array<Real>} The modified matrix
function mat4_make_rotation_axis(m, axis, angle) {
  gml_pragma("forceinline");
  var c = dcos(angle);
  var s = dsin(angle);
  var t = 1 - c;
  var _x = axis[0], _y = axis[1], _z = axis[2];

  m[0] = t * _x * _x + c; m[1] = t * _x * _y + s * _z; m[2] = t * _x * _z - s * _y; m[3] = 0;
  m[4] = t * _x * _y - s * _z; m[5] = t * _y * _y + c; m[6] = t * _y * _z + s * _x; m[7] = 0;
  m[8] = t * _x * _z + s * _y; m[9] = t * _y * _z - s * _x; m[10] = t * _z * _z + c; m[11] = 0;
  m[12] = 0; m[13] = 0; m[14] = 0; m[15] = 1;
  return m;
}

/// @func mat4_make_rotation_from_euler(m, rx, ry, rz)
/// @desc Sets the rotation component from Euler angles (XYZ order by default).
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} rx Rotation around X in degrees
/// @param {Real} ry Rotation around Y in degrees
/// @param {Real} rz Rotation around Z in degrees
/// @returns {Array<Real>} The modified matrix
function mat4_make_rotation_from_euler(m, rx, ry, rz) {
  gml_pragma("forceinline");
  matrix_build(0, 0, 0, rx, ry, rz, 1, 1, 1, m);
  return m;
}

/// @func mat4_make_rotation_from_quaternion(m, q)
/// @desc Sets the rotation component from a quaternion.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} q The quaternion [x, y, z, w]
/// @returns {Array<Real>} The modified matrix
function mat4_make_rotation_from_quaternion(m, q) {
  gml_pragma("forceinline");
  var _x = q[0], _y = q[1], _z = q[2], _w = q[3];
  var x2 = _x + _x, y2 = _y + _y, z2 = _z + _z;
  var xx = _x * x2, xy = _x * y2, xz = _x * z2;
  var yy = _y * y2, yz = _y * z2, zz = _z * z2;
  var wx = _w * x2, wy = _w * y2, wz = _w * z2;

  m[0] = 1 - (yy + zz); m[1] = xy + wz; m[2] = xz - wy; m[3] = 0;
  m[4] = xy - wz; m[5] = 1 - (xx + zz); m[6] = yz + wx; m[7] = 0;
  m[8] = xz + wy; m[9] = yz - wx; m[10] = 1 - (xx + yy); m[11] = 0;
  m[12] = 0; m[13] = 0; m[14] = 0; m[15] = 1;
  return m;
}

/// @func mat4_make_shear(m, xy, xz, yx, yz, zx, zy)
/// @desc Sets this matrix as a shear transformation.
/// @param {Array<Real>} m The matrix to modify
/// @returns {Array<Real>} The modified matrix
function mat4_make_shear(m, xy, xz, yx, yz, zx, zy) {
  gml_pragma("forceinline");
  m[0] = 1; m[1] = yx; m[2] = zx; m[3] = 0;
  m[4] = xy; m[5] = 1; m[6] = zy; m[7] = 0;
  m[8] = xz; m[9] = yz; m[10] = 1; m[11] = 0;
  m[12] = 0; m[13] = 0; m[14] = 0; m[15] = 1;
  return m;
}

// ============================================================================
// PROJECTION MATRICES
// ============================================================================

/// @func mat4_make_perspective(m, fov, aspect, near, far)
/// @desc Creates a perspective projection matrix.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} fov Field of view in degrees
/// @param {Real} aspect Aspect ratio
/// @param {Real} near Near plane distance
/// @param {Real} far Far plane distance
/// @returns {Array<Real>} The modified matrix
function mat4_make_perspective(m, fov, aspect, near, far) {
  gml_pragma("forceinline");
  matrix_build_projection_perspective_fov(fov, aspect, near, far, m);
  return m;
}

/// @func mat4_make_orthographic(m, left, right, top, bottom, near, far)
/// @desc Creates an orthographic projection matrix.
/// @param {Array<Real>} m The matrix to modify
/// @returns {Array<Real>} The modified matrix
function mat4_make_orthographic(m, left, right, top, bottom, near, far) {
  gml_pragma("forceinline");
  matrix_build_projection_ortho(right - left, top - bottom, near, far, m);
  return m;
}

// ============================================================================
// LOOK AT
// ============================================================================

/// @func mat4_look_at(m, eye, target, up)
/// @desc Sets the rotation component looking from eye towards target.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} eye The eye position (vec3)
/// @param {Array<Real>} target The target position (vec3)
/// @param {Array<Real>} up The up vector (vec3)
/// @returns {Array<Real>} The modified matrix
function mat4_look_at(m, eye, target, up) {
  gml_pragma("forceinline");
  matrix_build_lookat(eye[0], eye[1], eye[2], target[0], target[1], target[2], up[0], up[1], up[2], m);
  return m;
}

// ============================================================================
// BASIS / EXTRACT
// ============================================================================

/// @func mat4_make_basis(m, xAxis, yAxis, zAxis)
/// @desc Sets the given basis vectors to this matrix.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} xAxis The basis's x axis (vec3)
/// @param {Array<Real>} yAxis The basis's y axis (vec3)
/// @param {Array<Real>} zAxis The basis's z axis (vec3)
/// @returns {Array<Real>} The modified matrix
function mat4_make_basis(m, xAxis, yAxis, zAxis) {
  gml_pragma("forceinline");
  m[0] = xAxis[0]; m[1] = xAxis[1]; m[2] = xAxis[2]; m[3] = 0;
  m[4] = yAxis[0]; m[5] = yAxis[1]; m[6] = yAxis[2]; m[7] = 0;
  m[8] = zAxis[0]; m[9] = zAxis[1]; m[10] = zAxis[2]; m[11] = 0;
  m[12] = 0; m[13] = 0; m[14] = 0; m[15] = 1;
  return m;
}

/// @func mat4_extract_basis(m, xAxis, yAxis, zAxis)
/// @desc Extracts the basis of this matrix into the three axis vectors provided.
/// @param {Array<Real>} m The matrix
/// @param {Array<Real>} xAxis The basis's x axis (vec3)
/// @param {Array<Real>} yAxis The basis's y axis (vec3)
/// @param {Array<Real>} zAxis The basis's z axis (vec3)
function mat4_extract_basis(m, xAxis, yAxis, zAxis) {
  gml_pragma("forceinline");
  xAxis[0] = m[0]; xAxis[1] = m[1]; xAxis[2] = m[2];
  yAxis[0] = m[4]; yAxis[1] = m[5]; yAxis[2] = m[6];
  zAxis[0] = m[8]; zAxis[1] = m[9]; zAxis[2] = m[10];
}

/// @func mat4_extract_rotation(m, src)
/// @desc Extracts the rotation component of the given matrix.
/// @param {Array<Real>} m The matrix to store result
/// @param {Array<Real>} src The source matrix
/// @returns {Array<Real>} The modified matrix
function mat4_extract_rotation(m, src) {
  gml_pragma("forceinline");
  var sx = sqrt(src[0] * src[0] + src[1] * src[1] + src[2] * src[2]);
  var sy = sqrt(src[4] * src[4] + src[5] * src[5] + src[6] * src[6]);
  var sz = sqrt(src[8] * src[8] + src[9] * src[9] + src[10] * src[10]);

  var invSx = sx > 0 ? 1 / sx : 0;
  var invSy = sy > 0 ? 1 / sy : 0;
  var invSz = sz > 0 ? 1 / sz : 0;

  m[0] = src[0] * invSx; m[1] = src[1] * invSx; m[2] = src[2] * invSx; m[3] = 0;
  m[4] = src[4] * invSy; m[5] = src[5] * invSy; m[6] = src[6] * invSy; m[7] = 0;
  m[8] = src[8] * invSz; m[9] = src[9] * invSz; m[10] = src[10] * invSz; m[11] = 0;
  m[12] = 0; m[13] = 0; m[14] = 0; m[15] = 1;
  return m;
}

// ============================================================================
// COMPOSE / DECOMPOSE
// ============================================================================

/// @func mat4_compose(m, position, quaternion, scale)
/// @desc Sets this matrix to the transformation composed of position, rotation, and scale.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} position The position (vec3)
/// @param {Array<Real>} quaternion The rotation [x, y, z, w]
/// @param {Array<Real>} scale The scale (vec3)
/// @returns {Array<Real>} The modified matrix
function mat4_compose(m, position, quaternion, scale) {
  gml_pragma("forceinline");
  var _x = quaternion[0], _y = quaternion[1], _z = quaternion[2], _w = quaternion[3];
  var _x2 = _x + _x, _y2 = _y + _y, _z2 = _z + _z;
  var _xx = _x * _x2, _xy = _x * _y2, _xz = _x * _z2;
  var _yy = _y * _y2, _yz = _y * _z2, _zz = _z * _z2;
  var _wx = _w * _x2, _wy = _w * _y2, _wz = _w * _z2;

  var _sx = scale[0], _sy = scale[1], _sz = scale[2];

  m[0] = (1 - (_yy + _zz)) * _sx;
  m[1] = (_xy + _wz) * _sx;
  m[2] = (_xz - _wy) * _sx;
  m[3] = 0;

  m[4] = (_xy - _wz) * _sy;
  m[5] = (1 - (_xx + _zz)) * _sy;
  m[6] = (_yz + _wx) * _sy;
  m[7] = 0;

  m[8] = (_xz + _wy) * _sz;
  m[9] = (_yz - _wx) * _sz;
  m[10] = (1 - (_xx + _yy)) * _sz;
  m[11] = 0;

  m[12] = position[0];
  m[13] = position[1];
  m[14] = position[2];
  m[15] = 1;
  return m;
}

/// @func mat4_decompose(m, position, quaternion, scale)
/// @desc Decomposes this matrix into its position, rotation and scale components.
/// @param {Array<Real>} m The matrix
/// @param {Array<Real>} position Output position (vec3)
/// @param {Array<Real>} quaternion Output rotation [x, y, z, w]
/// @param {Array<Real>} scale Output scale (vec3)
function mat4_decompose(m, position, quaternion, scale) {
  gml_pragma("forceinline");
  // Extract position
  position[0] = m[12];
  position[1] = m[13];
  position[2] = m[14];

  // Extract scale
  var sx = sqrt(m[0] * m[0] + m[1] * m[1] + m[2] * m[2]);
  var sy = sqrt(m[4] * m[4] + m[5] * m[5] + m[6] * m[6]);
  var sz = sqrt(m[8] * m[8] + m[9] * m[9] + m[10] * m[10]);

  // Detect negative scale
  if (mat4_determinant(m) < 0) sx = -sx;

  scale[0] = sx;
  scale[1] = sy;
  scale[2] = sz;

  // Extract rotation (normalized basis)
  var invSx = sx > 0 ? 1 / sx : 0;
  var invSy = sy > 0 ? 1 / sy : 0;
  var invSz = sz > 0 ? 1 / sz : 0;

  var m00 = m[0] * invSx, m10 = m[1] * invSx, m20 = m[2] * invSx;
  var m01 = m[4] * invSy, m11 = m[5] * invSy, m21 = m[6] * invSy;
  var m02 = m[8] * invSz, m12 = m[9] * invSz, m22 = m[10] * invSz;

  // Quaternion from rotation matrix
  var trace = m00 + m11 + m22;

  if (trace > 0) {
    var s = 0.5 / sqrt(trace + 1);
    quaternion[3] = 0.25 / s;
    quaternion[0] = (m21 - m12) * s;
    quaternion[1] = (m02 - m20) * s;
    quaternion[2] = (m10 - m01) * s;
  } else if (m00 > m11 && m00 > m22) {
    var s = 2 * sqrt(1 + m00 - m11 - m22);
    quaternion[3] = (m21 - m12) / s;
    quaternion[0] = 0.25 * s;
    quaternion[1] = (m01 + m10) / s;
    quaternion[2] = (m02 + m20) / s;
  } else if (m11 > m22) {
    var s = 2 * sqrt(1 + m11 - m00 - m22);
    quaternion[3] = (m02 - m20) / s;
    quaternion[0] = (m01 + m10) / s;
    quaternion[1] = 0.25 * s;
    quaternion[2] = (m12 + m21) / s;
  } else {
    var s = 2 * sqrt(1 + m22 - m00 - m11);
    quaternion[3] = (m10 - m01) / s;
    quaternion[0] = (m02 + m20) / s;
    quaternion[1] = (m12 + m21) / s;
    quaternion[2] = 0.25 * s;
  }
}

// ============================================================================
// SCALE / POSITION
// ============================================================================

/// @func mat4_scale(m, v)
/// @desc Multiplies the columns of this matrix by the given vector.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} v The scale vector (vec3)
/// @returns {Array<Real>} The modified matrix
function mat4_scale(m, v) {
  gml_pragma("forceinline");
  var sx = v[0], sy = v[1], sz = v[2];
  m[0] *= sx; m[1] *= sx; m[2] *= sx; m[3] *= sx;
  m[4] *= sy; m[5] *= sy; m[6] *= sy; m[7] *= sy;
  m[8] *= sz; m[9] *= sz; m[10] *= sz; m[11] *= sz;
  return m;
}

/// @func mat4_set_position(m, x, y, z)
/// @desc Sets the position component for this matrix.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} x Position X
/// @param {Real} y Position Y
/// @param {Real} z Position Z
/// @returns {Array<Real>} The modified matrix
function mat4_set_position(m, x, y, z) {
  gml_pragma("forceinline");
  m[12] = x;
  m[13] = y;
  m[14] = z;
  return m;
}

/// @func mat4_get_max_scale_on_axis(m)
/// @desc Gets the maximum scale value of the three axes.
/// @param {Array<Real>} m The matrix
/// @returns {Real} The maximum scale
function mat4_get_max_scale_on_axis(m) {
  gml_pragma("forceinline");
  var sx = m[0] * m[0] + m[1] * m[1] + m[2] * m[2];
  var sy = m[4] * m[4] + m[5] * m[5] + m[6] * m[6];
  var sz = m[8] * m[8] + m[9] * m[9] + m[10] * m[10];
  return sqrt(max(sx, sy, sz));
}

// ============================================================================
// SET FROM MATRIX3
// ============================================================================

/// @func mat4_set_from_matrix3(m, m3)
/// @desc Set the upper 3x3 elements of this matrix to the values of given 3x3 matrix.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} m3 The 3x3 matrix
/// @returns {Array<Real>} The modified matrix
function mat4_set_from_matrix3(m, m3) {
  gml_pragma("forceinline");
  m[0] = m3[0]; m[1] = m3[1]; m[2] = m3[2];
  m[4] = m3[3]; m[5] = m3[4]; m[6] = m3[5];
  m[8] = m3[6]; m[9] = m3[7]; m[10] = m3[8];
  return m;
}

// ============================================================================
// ARRAY CONVERSION
// ============================================================================

/// @func mat4_from_array(m, array, offset)
/// @desc Sets the elements of the matrix from the given array.
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} array The matrix elements in column-major order
/// @param {Real} [offset=0] Index of the first element in the array
/// @returns {Array<Real>} The modified matrix
function mat4_from_array(m, array, offset = 0) {
  gml_pragma("forceinline");
  for (var i = 0; i < 16; i++) m[i] = array[offset + i];
  return m;
}

/// @func mat4_to_array(m, array, offset)
/// @desc Writes the elements of this matrix to the given array.
/// @param {Array<Real>} m The matrix
/// @param {Array<Real>} [array] The target array (creates new if undefined)
/// @param {Real} [offset=0] Index of the first element in the array
/// @returns {Array<Real>} The matrix elements in column-major order
function mat4_to_array(m, array = undefined, offset = 0) {
  gml_pragma("forceinline");
  array ??= array_create(16);
  for (var i = 0; i < 16; i++) array[offset + i] = m[i];
  return array;
}
