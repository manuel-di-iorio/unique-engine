function UeMatrix3(_data = undefined) constructor {
    // The matrix elements stored in column-major order (9 elements)
    data = _data ?? [
        1, 0, 0,
        0, 1, 0,
        0, 0, 1
    ];

    /// Creates a new clone of this matrix.
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// Copies the values from another UeMatrix3 into this matrix.
    static copy = function(m) {
        gml_pragma("forceinline");
        for (var i = 0; i < 9; i++) data[i] = m.data[i];
        return self;
    }

    /// Computes and returns the determinant of the matrix.
    static determinant = function() {
        gml_pragma("forceinline");
        var a = data[0], d = data[3], g = data[6];
        var b = data[1], e = data[4], h = data[7];
        var c = data[2], f = data[5], i = data[8];

        return a*(e*i - f*h) - b*(d*i - f*g) + c*(d*h - e*g);
    }

    /// Checks if this matrix is equal to another (element-wise).
    static equals = function(m) {
        gml_pragma("forceinline");
        for (var i = 0; i < 9; i++)
            if (data[i] != m.data[i]) return false;
        return true;
    }

    /// Extracts the basis vectors (columns) of the matrix into xAxis, yAxis, zAxis vectors.
    static extractBasis = function(xAxis, yAxis, zAxis) {
        gml_pragma("forceinline");
        // Extract columns because data is column-major
        xAxis.set(data[0], data[1], data[2]);
        yAxis.set(data[3], data[4], data[5]);
        zAxis.set(data[6], data[7], data[8]);
        return self;
    }

    /// Sets the matrix elements from an array starting at the given offset.
    static fromArray = function(arr, offset = 0) {
        gml_pragma("forceinline");
        for (var i = 0; i < 9; i++) data[i] = arr[offset + i];
        return self;
    }

    /// Inverts the matrix. If determinant is zero, sets matrix to zero matrix.
    static invert = function() {
        gml_pragma("forceinline");
        var det = self.determinant();
        if (det == 0) {
            // Non-invertible matrix, zero it out
            for (var i = 0; i < 9; i++) data[i] = 0;
            return self;
        }

        var invDet = 1 / det;

        var a = data[0], d = data[3], g = data[6];
        var b = data[1], e = data[4], h = data[7];
        var c = data[2], f = data[5], i = data[8];

        // Calculate inverse using 3x3 matrix formula
        data[0] =  (e*i - f*h) * invDet;
        data[1] = -(b*i - c*h) * invDet;
        data[2] =  (b*f - c*e) * invDet;

        data[3] = -(d*i - f*g) * invDet;
        data[4] =  (a*i - c*g) * invDet;
        data[5] = -(a*f - c*d) * invDet;

        data[6] =  (d*h - e*g) * invDet;
        data[7] = -(a*h - b*g) * invDet;
        data[8] =  (a*e - b*d) * invDet;

        return self;
    }

    /// Sets this matrix to the normal matrix derived from a 4x4 matrix (used in shading).
    static getNormalMatrix = function(m4) {
        gml_pragma("forceinline");
        // Extract 3x3 part, invert and transpose
        self.setFromMatrix4(m4);
        self.invert();
        self.transpose();
        return self;
    }

    /// Resets the matrix to the identity matrix.
    static identity = function() {
        gml_pragma("forceinline");
        data = [
            1,0,0,
            0,1,0,
            0,0,1
        ];
        return self;
    }

    /// Sets the matrix to a 2D rotation matrix for the given angle in radians.
    static makeRotation = function(theta_rad) {
        gml_pragma("forceinline");
        var c = cos(theta_rad);
        var s = sin(theta_rad);
        data = [
            c, s, 0,
           -s, c, 0,
            0, 0, 1
        ];
        return self;
    }

    /// Sets the matrix to a 2D scale matrix with x and y scaling factors.
    static makeScale = function(x, y) {
        gml_pragma("forceinline");
        data = [
            x, 0, 0,
            0, y, 0,
            0, 0, 1
        ];
        return self;
    }

    /// Sets the matrix to a 2D translation matrix by (x, y).
    static makeTranslation = function(x, y) {
        gml_pragma("forceinline");
        data = [
            1, 0, 0,
            0, 1, 0,
            x, y, 1
        ];
        return self;
    }

    /// Multiplies this matrix by another UeMatrix3 from the right.
    static multiply = function(m) {
        gml_pragma("forceinline");
        var a = data;
        var b = m.data;
        var r = [];

        for (var row = 0; row < 3; row++) {
            for (var col = 0; col < 3; col++) {
                var val = 0;
                for (var k = 0; k < 3; k++) {
                    val += a[k*3 + row] * b[col*3 + k];
                }
                r[col*3 + row] = val;
            }
        }
        data = r;
        return self;
    }

    /// Sets this matrix as the product of matrices a and b.
    static multiplyMatrices = function(a, b) {
        gml_pragma("forceinline");
        matrix_multiply(b.data, a.data, data);
        return self;
    }

    /// Multiplies every element of the matrix by scalar s.
    static multiplyScalar = function(s) {
        gml_pragma("forceinline");
        for (var i = 0; i < 9; i++) data[i] *= s;
        return self;
    }

    /// Applies a 2D rotation by theta radians by multiplying on the right.
    static rotate = function(theta_rad) {
        gml_pragma("forceinline");
        var rot = new UeMatrix3().makeRotation(theta_rad);
        return self.multiply(rot);
    }

    /// Applies scaling factors sx, sy to the matrix (affects the first two columns).
    static scale = function(sx, sy) {
        gml_pragma("forceinline");
        data[0] *= sx; data[3] *= sx; data[6] *= sx;
        data[1] *= sy; data[4] *= sy; data[7] *= sy;
        // last row (2D affine transform) remains unchanged
        return self;
    }

    /// Sets matrix elements explicitly.
    static set = function(n11, n12, n13, n21, n22, n23, n31, n32, n33) {
        gml_pragma("forceinline");
        data = [
            n11, n12, n13,
            n21, n22, n23,
            n31, n32, n33
        ];
        return self;
    }

    /// Premultiplies this matrix by another matrix m (i.e. m * this).
    static premultiply = function(m) {
        gml_pragma("forceinline");
        var result = m.clone().multiply(self);
        self.copy(result);
        return self;
    }

    /// Sets this matrix from the upper-left 3x3 part of a UeMatrix4.
    static setFromMatrix4 = function(m4) {
        gml_pragma("forceinline");
        var me = m4.data;
        data = [
            me[0], me[1], me[2],
            me[4], me[5], me[6],
            me[8], me[9], me[10]
        ];
        return self;
    }

    /// Sets a UV transform matrix for texture transformations.
    static setUvTransform = function(tx, ty, sx, sy, rotation, cx, cy) {
        gml_pragma("forceinline");
        var c = cos(rotation);
        var s = sin(rotation);

        data = [
            sx * c, sx * s, 0,
           -sy * s, sy * c, 0,
            tx + cx - cx * data[0] - cy * data[3],
            ty + cy - cx * data[1] - cy * data[4],
            1
        ];
        return self;
    }

    /// Copies the matrix elements into an array, optionally starting at offset.
    static toArray = function(arr = undefined, offset = 0) {
        gml_pragma("forceinline");
        arr ??= [];
        for (var i = 0; i < 9; i++) arr[offset + i] = data[i];
        return arr;
    }

    /// Translates the matrix by adding (tx, ty) to the last row (affine transform).
    static translate = function(tx, ty) {
        gml_pragma("forceinline");
        data[6] += tx;
        data[7] += ty;
        return self;
    }

    /// Transposes the matrix (rows become columns).
    static transpose = function() {
        gml_pragma("forceinline");
        var d = data;
        data = [
            d[0], d[3], d[6],
            d[1], d[4], d[7],
            d[2], d[5], d[8]
        ];
        return self;
    }

    /// Writes the transposed matrix into the given array.
    static transposeIntoArray = function(arr) {
        gml_pragma("forceinline");
        arr[0] = data[0];
        arr[1] = data[3];
        arr[2] = data[6];

        arr[3] = data[1];
        arr[4] = data[4];
        arr[5] = data[7];

        arr[6] = data[2];
        arr[7] = data[5];
        arr[8] = data[8];
        return self;
    }
}
