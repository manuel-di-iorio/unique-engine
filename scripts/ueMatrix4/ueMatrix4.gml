function UeMatrix4(_data = undefined) constructor {
    
    // Matrix data, stored as a 4x4 column-major flat array
    data = _data ?? matrix_build_identity();

    /// Multiplies this matrix by another (4x4), returns the result (does not modify self)
    function multiply(m) {
        return matrix_multiply(self.data, m);
    }

    /// Creates a copy of this matrix
    function clone() {
        return variable_clone(self);
    }

    /// Builds a transformation matrix from a Transform object (position, rotation, scale)
    function buildByTransform(transform) {
        var pos = transform.position;
        var rot = transform.rotation;
        var scl = transform.scale;
    
        // Normalize quaternion to prevent rotation-scaling artifacts
        rot.normalize();
    
        var x0 = rot.x, y0 = rot.y, z0 = rot.z, w0 = rot.w;
        var x2 = x0 + x0, y2 = y0 + y0, z2 = z0 + z0;
    
        // Precompute quaternion products
        var xx = x0 * x2, xy = x0 * y2, xz = x0 * z2;
        var yy = y0 * y2, yz = y0 * z2, zz = z0 * z2;
        var wx = w0 * x2, wy = w0 * y2, wz = w0 * z2;
    
        // Rotation matrix without scale (column-major)
        var m00 = 1 - (yy + zz), m01 = xy + wz,     m02 = xz - wy;
        var m10 = xy - wz,       m11 = 1 - (xx + zz), m12 = yz + wx;
        var m20 = xz + wy,       m21 = yz - wx,     m22 = 1 - (xx + yy);
    
        // Apply scale per column
        m00 *= scl.x; m10 *= scl.x; m20 *= scl.x;
        m01 *= scl.y; m11 *= scl.y; m21 *= scl.y;
        m02 *= scl.z; m12 *= scl.z; m22 *= scl.z;
    
        // Compose final matrix
        data = [
            m00, m01, m02, 0,
            m10, m11, m12, 0,
            m20, m21, m22, 0,
            pos.x, pos.y, pos.z, 1
        ];

        return self;
    }
}
