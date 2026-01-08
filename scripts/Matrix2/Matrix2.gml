/// @desc 2x2 matrix functions using arrays [m0, m1, m2, m3]
/// All matrices are stored in COLUMN-MAJOR order.
/// All functions modify the first matrix in-place when applicable.

/// @func mat2_create(n11, n12, n21, n22)
/// @desc Creates a new 2x2 matrix. Arguments are in ROW-MAJOR order.
/// @param {Real} [n11=1] 1-1 element
/// @param {Real} [n12=0] 1-2 element
/// @param {Real} [n21=0] 2-1 element
/// @param {Real} [n22=1] 2-2 element
/// @returns {Array<Real>} New 2x2 matrix
function mat2_create(n11 = 1, n12 = 0, n21 = 0, n22 = 1) {
    gml_pragma("forceinline");
    return [n11, n21, n12, n22];
}

/// @func mat2_set(m, n11, n12, n21, n22)
/// @desc Sets the elements of the matrix. Arguments are in ROW-MAJOR order.
/// @param {Array<Real>} m The matrix to modify
/// @param {Real} n11 1-1 element
/// @param {Real} n12 1-2 element
/// @param {Real} n21 2-1 element
/// @param {Real} n22 2-2 element
/// @returns {Array<Real>} The modified matrix
function mat2_set(m, n11, n12, n21, n22) {
    gml_pragma("forceinline");
    m[0] = n11;
    m[1] = n21;
    m[2] = n12;
    m[3] = n22;
    return m;
}

/// @func mat2_identity(m)
/// @desc Sets this matrix to the 2x2 identity matrix.
/// @param {Array<Real>} m The matrix to modify
/// @returns {Array<Real>} The modified matrix
function mat2_identity(m) {
    gml_pragma("forceinline");
    m[0] = 1; m[1] = 0;
    m[2] = 0; m[3] = 1;
    return m;
}

/// @func mat2_from_array(m, array, offset = 0)
/// @desc Sets the elements of the matrix from the given array (COLUMN-MAJOR).
/// @param {Array<Real>} m The matrix to modify
/// @param {Array<Real>} array The matrix elements in column-major order
/// @param {Real} [offset=0] Index of the first element
/// @returns {Array<Real>} The modified matrix
function mat2_from_array(m, array, offset = 0) {
    gml_pragma("forceinline");
    m[0] = array[offset];
    m[1] = array[offset + 1];
    m[2] = array[offset + 2];
    m[3] = array[offset + 3];
    return m;
}
