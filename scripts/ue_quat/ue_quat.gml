function Quat(_x = 0, _y = 0, _z = 0) constructor {
    
    /// Clone the quaternion
    function clone() {
        return new Quat(self.x, self.y, self.z);
    }

    /// Copy from another quaternion
    function copy(q) {
        self.x = q.x;
        self.y = q.y;
        self.z = q.z;
        self.w = q.w;
        return self;
    }

    /// Set quaternion from Euler angles (in degrees)
    function setFromEuler(rx, ry, rz) {
        var cx = dcos(rx * 0.5);
        var sx = dsin(rx * 0.5);
        var cy = dcos(ry * 0.5);
        var sy = dsin(ry * 0.5);
        var cz = dcos(rz * 0.5);
        var sz = dsin(rz * 0.5);

        self.x = sx * cy * cz - cx * sy * sz;
        self.y = cx * sy * cz + sx * cy * sz;
        self.z = cx * cy * sz - sx * sy * cz;
        self.w = cx * cy * cz + sx * sy * sz;
        return self;
    }

    /// Normalize quaternion
    function normalize() {
        var len = sqrt(self.x*self.x + self.y*self.y + self.z*self.z + self.w*self.w);
        if (len > 0) {
            var inv = 1 / len;
            self.x *= inv;
            self.y *= inv;
            self.z *= inv;
            self.w *= inv;
        }
        return self;
    }

    /// Multiply (combine) with another quaternion
    function multiply(q) {
        var _x = self.x, _y = self.y, _z = self.z, _w = self.w;

        self.x = _w * q.x + _x * q.w + _y * q.z - _z * q.y;
        self.y = _w * q.y - _x * q.z + _y * q.w + _z * q.x;
        self.z = _w * q.z + _x * q.y - _y * q.x + _z * q.w;
        self.w = _w * q.w - _x * q.x - _y * q.y - _z * q.z;

        return self;
    }

    /// Set rotation from axis and angle
    function setFromAxisAngle(axis, angle) {
        var half = angle * 0.5;
        var s = sin(half);
        self.x = axis.x * s;
        self.y = axis.y * s;
        self.z = axis.z * s;
        self.w = cos(half);
        return self;
    }

    /// Spherical linear interpolation
    function slerp(q, t) {
        var _x = self.x, _y = self.y, _z = self.z, _w = self.w;

        var cosHalfTheta = _x * q.x + _y * q.y + _z * q.z + _w * q.w;

        if (cosHalfTheta < 0) {
            q = quat(-q.x, -q.y, -q.z, -q.w);
            cosHalfTheta = -cosHalfTheta;
        }

        if (cosHalfTheta >= 1.0) {
            return self;
        }

        var sinHalfTheta = sqrt(1.0 - cosHalfTheta * cosHalfTheta);

        if (abs(sinHalfTheta) < 0.001) {
            x = _x * 0.5 + q.x * 0.5;
            y = _y * 0.5 + q.y * 0.5;
            z = _z * 0.5 + q.z * 0.5;
            w = _w * 0.5 + q.w * 0.5;
            return self;
        }

        var halfTheta = arccos(cosHalfTheta);
        var ratioA = sin((1 - t) * halfTheta) / sinHalfTheta;
        var ratioB = sin(t * halfTheta) / sinHalfTheta;

        self.x = _x * ratioA + q.x * ratioB;
        self.y = _y * ratioA + q.y * ratioB;
        self.z = _z * ratioA + q.z * ratioB;
        self.w = _w * ratioA + q.w * ratioB;

        return self;
    }
    
    /// @desc Rotate the quaternion axis by the specified degrees
    /// @param {any*} axis
    /// @param {real} angle in deegres
    /// @returns {struct}
    //function rotate(axis, angle) {
        //var halfAngle = degtorad(angle) * 0.5;
        //var s = sin(halfAngle);
        //var q = new Quat(axis.x * s, axis.y * s, axis.z * s, cos(halfAngle));
        //multiply(q);
        //return self;
    //};    
    function rotate(axis, angle) {
        var q = new Quat().setFromAxisAngle(axis, degtorad(angle));
        multiply(q);
        return self;
    }

    // Rotate around X axis
    function rotateX(angle) {
        rotate(new Vec3(1, 0, 0), angle);
        return self;
    };

    // Rotate around Y axis
    function rotateY(angle) {
        rotate(new Vec3(0, 1, 0), angle);
        return self;
    };

    // Rotate around Z axis
    function rotateZ(angle) {
        rotate(new Vec3(0, 0, 1), angle);
        return self;
    };
    
    function toMat3() {
        var xx = self.x * self.x;
        var yy = self.y * self.y;
        var zz = self.z * self.z;
        var xy = self.x * self.y;
        var xz = self.x * self.z;
        var yz = self.y * self.z;
        var wx = self.w * self.x;
        var wy = self.w * self.y;
        var wz = self.w * self.z;
    
        return new Mat3([
            1 - 2 * (yy + zz),  2 * (xy - wz),      2 * (xz + wy),
            2 * (xy + wz),      1 - 2 * (xx + zz),  2 * (yz - wx),
            2 * (xz - wy),      2 * (yz + wx),      1 - 2 * (xx + yy)
        ]);
    }
    
    setFromEuler(_x, _y, _z);
}