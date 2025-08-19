function UeMatrix4(_data = undefined) constructor {
    // Internal data in column-major order
    data = _data ?? matrix_build_identity();

    /// Creates a deep copy of this matrix
    function clone() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }
    
    /// Multiplies this matrix by another (result = self * m)
    function multiply(m) {
        gml_pragma("forceinline");
        data = matrix_multiply(m.data, self.data);
        return self;
    }

    /// Multiplies two matrices: result = a * b
    function multiplyMatrices(a, b) {
        gml_pragma("forceinline");
        data = matrix_multiply(b.data, a.data);
        return self;
    }

    /// Pre-multiplies this matrix: result = m * self
    function premultiply(m) {
        gml_pragma("forceinline");
        data = matrix_multiply(self.data, m.data);
        return self;
    }

    /// Multiplies every component by a scalar
    function multiplyScalar(s) {
        gml_pragma("forceinline");
        for (var i = 0; i < 16; i++) data[i] *= s;
        return self;
    }

    /// Builds a matrix from position, quaternion rotation, and scale
    function compose(pos, rot, scl) {
        gml_pragma("forceinline");
        rot.normalize();

        var x0 = rot.x, y0 = rot.y, z0 = rot.z, w0 = rot.w;
        var x2 = x0 + x0, y2 = y0 + y0, z2 = z0 + z0;

        var xx = x0 * x2, xy = x0 * y2, xz = x0 * z2;
        var yy = y0 * y2, yz = y0 * z2, zz = z0 * z2;
        var wx = w0 * x2, wy = w0 * y2, wz = w0 * z2;

        var m00 = 1 - (yy + zz), m01 = xy + wz,     m02 = xz - wy;
        var m10 = xy - wz,       m11 = 1 - (xx + zz), m12 = yz + wx;
        var m20 = xz + wy,       m21 = yz - wx,     m22 = 1 - (xx + yy);

        m00 *= scl.x; m10 *= scl.x; m20 *= scl.x;
        m01 *= scl.y; m11 *= scl.y; m21 *= scl.y;
        m02 *= scl.z; m12 *= scl.z; m22 *= scl.z;

        data = [
            m00, m01, m02, 0,
            m10, m11, m12, 0,
            m20, m21, m22, 0,
            pos.x, pos.y, pos.z, 1
        ];

        return self;
    }

    /// Decomposes matrix into position, quaternion, and scale
    function decompose(position, quaternion, scale) {
        gml_pragma("forceinline");
        var te = data;
        position.set(te[12], te[13], te[14]);

        var sx = new UeVector3(te[0], te[1], te[2]).length();
        var sy = new UeVector3(te[4], te[5], te[6]).length();
        var sz = new UeVector3(te[8], te[9], te[10]).length();

        scale.set(sx, sy, sz);

        var m = self.clone();
        var invScale = new UeVector3(1/sx, 1/sy, 1/sz);
        m.scale(invScale);

        quaternion.setFromRotationMatrix(m);
        return self;
    }

    /// Copies all values from another matrix
    function copy(m) {
        gml_pragma("forceinline");
        array_copy(data, 0, m.data, 0, 16);
        return self;
    }

    /// Copies only the translation component from another matrix
    function copyPosition(m) {
        gml_pragma("forceinline");
        data[12] = m.data[12];
        data[13] = m.data[13];
        data[14] = m.data[14];
        return self;
    }

    /// Returns the determinant of the matrix
    function determinant() {
        gml_pragma("forceinline");
        var a00 = data[ 0], a01 = data[ 4], a02 = data[ 8],  a03 = data[12];
        var a10 = data[ 1], a11 = data[ 5], a12 = data[ 9],  a13 = data[13];
        var a20 = data[ 2], a21 = data[ 6], a22 = data[10],  a23 = data[14];
        var a30 = data[ 3], a31 = data[ 7], a32 = data[11],  a33 = data[15];

        var det00 = a00 * (a11 * (a22 * a33 - a23 * a32) - a12 * (a21 * a33 - a23 * a31) + a13 * (a21 * a32 - a22 * a31));
        var det01 = a01 * (a10 * (a22 * a33 - a23 * a32) - a12 * (a20 * a33 - a23 * a30) + a13 * (a20 * a32 - a22 * a30));
        var det02 = a02 * (a10 * (a21 * a33 - a23 * a31) - a11 * (a20 * a33 - a23 * a30) + a13 * (a20 * a31 - a21 * a30));
        var det03 = a03 * (a10 * (a21 * a32 - a22 * a31) - a11 * (a20 * a32 - a22 * a30) + a12 * (a20 * a31 - a21 * a30));

        return det00 - det01 + det02 - det03;
    }

    /// Inverts the matrix
    function invert() {
        gml_pragma("forceinline");
        self.data = matrix_inverse(self.data);
        return self;
    }

    /// Checks if this matrix equals another
    function equals(m) {
        gml_pragma("forceinline");
        for (var i = 0; i < 16; i++)
            if (data[i] != m.data[i]) return false;
        return true;
    }

    /// Extracts the three basis axes (X, Y, Z) from matrix
    function extractBasis(xAxis, yAxis, zAxis) {
        gml_pragma("forceinline");
        xAxis.set(data[0], data[1], data[2]);
        yAxis.set(data[4], data[5], data[6]);
        zAxis.set(data[8], data[9], data[10]);
        return self;
    }

    /// Removes scaling and isolates rotation from a matrix
    function extractRotation(m) {
        gml_pragma("forceinline");
        self.copy(m);
        var scale = new UeVector3();
        self.decompose(new UeVector3(), new UeQuaternion(), scale);
        return self;
    }

    /// Resets the matrix to ty
    function identity() {
        gml_pragma("forceinline");
        data = matrix_build_identity();
        return self;
    }

    /// Builds a lookAt matrix from eye, target and up vectors
    function lookAt(eye, target, up) {
        gml_pragma("forceinline");
        data = matrix_build_lookat(eye.x, eye.y, eye.z, target.x, target.y, target.z, up.x, up.y, up.z);
        return self;
    }

    /// Builds a rotation matrix from axis and angle
    function makeRotationAxis(axis, theta) {
        gml_pragma("forceinline");
        var q = new UeQuaternion().setFromAxisAngle(axis, theta);
        return self.makeRotationFromQuaternion(q);
    }

    /// Builds a rotation matrix from quaternion
    function makeRotationFromQuaternion(q) {
        gml_pragma("forceinline");
        self.compose(new UeVector3(), q, new UeVector3(1,1,1));
        return self;
    }

    /// Builds a scaling matrix
    function makeScale(x, y, z) {
        gml_pragma("forceinline");
        data = [
            x, 0, 0, 0,
            0, y, 0, 0,
            0, 0, z, 0,
            0, 0, 0, 1
        ];
        return self;
    }

    /// Builds a translation matrix
    function makeTranslation(x, y, z) {
        gml_pragma("forceinline");
        data = [
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            x, y, z, 1
        ];
        return self;
    }

    /// Builds a perspective projection matrix
    function makePerspective(left, right, top, bottom, near, far) {
        gml_pragma("forceinline");
        var width  = right - left;
        var height = top - bottom;
        var aspect = width / height;
        var fov_y_deg = radtodeg(2 * arctan(height * 0.5 / near));
        data = matrix_build_projection_perspective(fov_y_deg, aspect, near, far);
        return self;
    }

    /// Builds an orthographic projection matrix
    function makeOrthographic(left, right, top, bottom, near, far) {
        gml_pragma("forceinline");
        var width  = right - left;
        var height = top - bottom;
        data = matrix_build_projection_ortho(width, height, near, far);
        return self;
    }

    /// Sets values from a column-major array
    function fromArray(arr, offset = 0) {
        gml_pragma("forceinline");
        array_copy(data, 0, arr, offset, 16-offset);
        return self;
    }

    /// Writes values into a column-major array
    function toArray(arr = [], offset = 0) {
        gml_pragma("forceinline");
        array_copy(arr, offset, data, 0, 16-offset);
        return arr;
    }

    /// Transposes the matrix
    function transpose() {
        gml_pragma("forceinline");
        data = [
            data[0], data[4], data[8],  data[12],
            data[1], data[5], data[9],  data[13],
            data[2], data[6], data[10], data[14],
            data[3], data[7], data[11], data[15]
        ];
        return self;
    }

    /// Returns the maximum scale along any axis
    function getMaxScaleOnAxis() {
        gml_pragma("forceinline");
        var sx = new UeVector3(data[0], data[1], data[2]).length();
        var sy = new UeVector3(data[4], data[5], data[6]).length();
        var sz = new UeVector3(data[8], data[9], data[10]).length();
        return max(sx, sy, sz);
    }

    /// Applies matrix transform to a Vector3 (as a position, w = 1)
    function applyToVector3(vec) {
        gml_pragma("forceinline");
        var e = data;
        var xx = vec.x, yy = vec.y, zz = vec.z;
        var tx = e[0]*xx + e[4]*yy + e[8]*zz + e[12];
        var ty = e[1]*xx + e[5]*yy + e[9]*zz + e[13];
        var tz = e[2]*xx + e[6]*yy + e[10]*zz + e[14];
        var tw = e[3]*xx + e[7]*yy + e[11]*zz + e[15];
        if (tw != 1 && tw != 0) {
            tx /= tw; ty /= tw; tz /= tw;
        }
        return new UeVector3(tx, ty, tz);
    }

    /// Scales this matrix by a vector (column-wise)
    function scale(v) {
        gml_pragma("forceinline");
        data[0] *= v.x; data[1] *= v.x; data[2] *= v.x; data[3] *= v.x;
        data[4] *= v.y; data[5] *= v.y; data[6] *= v.y; data[7] *= v.y;
        data[8] *= v.z; data[9] *= v.z; data[10] *= v.z; data[11] *= v.z;
        return self;
    }
    
    /// Scales this matrix by the XYZ components (column-wise)
    function scaleXYZ(x, y, z) {
        gml_pragma("forceinline");
        data[0] *= x; data[1] *= x; data[2] *= x; data[3] *= x;
        data[4] *= y; data[5] *= y; data[6] *= y; data[7] *= y;
        data[8] *= z; data[9] *= z; data[10] *= z; data[11] *= z;
        return self;
    }

    /// Sets matrix values using row-major arguments (converted to column-major)
    function set(n11, n12, n13, n14,
                 n21, n22, n23, n24,
                 n31, n32, n33, n34,
                 n41, n42, n43, n44) {
        gml_pragma("forceinline");
        data[0]  = n11; data[4]  = n12; data[8]  = n13; data[12] = n14;
        data[1]  = n21; data[5]  = n22; data[9]  = n23; data[13] = n24;
        data[2]  = n31; data[6]  = n32; data[10] = n33; data[14] = n34;
        data[3]  = n41; data[7]  = n42; data[11] = n43; data[15] = n44;
        return self;
    }

    /// Sets only the translation component of the matrix
    function setPosition(v) {
        gml_pragma("forceinline");
        data[12] = v.x;
        data[13] = v.y;
        data[14] = v.z;
        return self;
    }

    /// Sets translation from X, Y, Z values
    function setPositionXYZ(x, y, z) {
        gml_pragma("forceinline");
        data[12] = x;
        data[13] = y;
        data[14] = z;
        return self;
    }

    /// Builds a matrix from 3 orthogonal basis vectors
    function makeBasis(xAxis, yAxis, zAxis) {
        gml_pragma("forceinline");
        data = [
            xAxis.x, yAxis.x, zAxis.x, 0,
            xAxis.y, yAxis.y, zAxis.y, 0,
            xAxis.z, yAxis.z, zAxis.z, 0,
            0,       0,       0,       1
        ];
        return self;
    }

    /// Builds a rotation matrix from Euler angles in degrees (XYZ order)
    function makeRotationFromEuler(x_deg, y_deg, z_deg) {
        gml_pragma("forceinline");
        var c1 = dcos(x_deg);
        var c2 = dcos(y_deg);
        var c3 = dcos(z_deg);
        var s1 = dsin(x_deg);
        var s2 = dsin(y_deg);
        var s3 = dsin(z_deg);

        var m00 = c2 * c3;
        var m01 = -c2 * s3;
        var m02 = s2;

        var m10 = c1 * s3 + s1 * s2 * c3;
        var m11 = c1 * c3 - s1 * s2 * s3;
        var m12 = -s1 * c2;

        var m20 = s1 * s3 - c1 * s2 * c3;
        var m21 = s1 * c3 + c1 * s2 * s3;
        var m22 = c1 * c2;

        data = [
            m00, m01, m02, 0,
            m10, m11, m12, 0,
            m20, m21, m22, 0,
            0,   0,   0,   1
        ];

        return self;
    }

    /// Builds a rotation matrix around X axis
    function makeRotationX(theta) {
        gml_pragma("forceinline");
        var c = dcos(theta);
        var s = dsin(theta);
        data = [
            1, 0, 0, 0,
            0, c, s, 0,
            0,-s, c, 0,
            0, 0, 0, 1
        ];
        return self;
    }

    /// Builds a rotation matrix around Y axis
    function makeRotationY(theta) {
        gml_pragma("forceinline");
        var c = dcos(theta);
        var s = dsin(theta);
        data = [
            c, 0,-s, 0,
            0, 1, 0, 0,
            s, 0, c, 0,
            0, 0, 0, 1
        ];
        return self;
    }

    /// Builds a rotation matrix around Z axis
    function makeRotationZ(theta) {
        gml_pragma("forceinline");
        var c = dcos(theta);
        var s = dsin(theta);
        data = [
            c, s, 0, 0,
           -s, c, 0, 0,
            0, 0, 1, 0,
            0, 0, 0, 1
        ];
        return self;
    }

    /// Builds a shear (skew) matrix
    function makeShear(xy, xz, yx, yz, zx, zy) {
        gml_pragma("forceinline");
        data = [
            1,  yx, zx, 0,
            xy, 1,  zy, 0,
            xz, yz, 1,  0,
            0,  0,  0,  1
        ];
        return self;
    }
}
