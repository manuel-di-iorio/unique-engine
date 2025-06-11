function Mat4(_data = undefined) constructor {
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

        // Normalize quaternion to prevent scaling artifacts in rotation
        rot.normalize();

        var x0 = rot.x, y0 = rot.y, z0 = rot.z, w0 = rot.w;
        var x2 = x0 + x0, y2 = y0 + y0, z2 = z0 + z0;

        // Precompute products for rotation matrix
        var xx = x0 * x2, xy = x0 * y2, xz = x0 * z2;
        var yy = y0 * y2, yz = y0 * z2, zz = z0 * z2;
        var wx = w0 * x2, wy = w0 * y2, wz = w0 * z2;

        var sx = scl.x, sy = scl.y, sz = scl.z;

        // Compose the final transformation matrix:
        // It combines rotation and scale into the upper 3x3,
        // and sets translation in the last row
        data = [
            (1 - (yy + zz)) * sx, (xy + wz) * sx,     (xz - wy) * sx,     0,
            (xy - wz) * sy,       (1 - (xx + zz)) * sy, (yz + wx) * sy,   0,
            (xz + wy) * sz,       (yz - wx) * sz,     (1 - (xx + yy)) * sz, 0,
            pos.x,                pos.y,              pos.z,              1
        ];

        return self;
    }
}
