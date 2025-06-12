function UeQuaternion(_x = 0, _y = 0, _z = 0) constructor {
    
    function set(x, y, z, w) {
        self.x = x;
        self.y = y;
        self.z = z;
        self.w = w;
    }
    
    /// Clone the quaternion
    function clone() {
        return variable_clone(self);
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
        var s = dsin(half);
        self.x = axis.x * s;
        self.y = axis.y * s;
        self.z = axis.z * s;
        self.w = dcos(half);
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
    function rotate(axis, angle) {
        var q = new UeQuaternion().setFromAxisAngle(axis, angle);
        multiply(q);
        return self;
    }

    // Rotate around X axis
    function rotateX(angle) {
        rotate(new UeVector3(1, 0, 0), angle);
        return self;
    };

    // Rotate around Y axis
    function rotateY(angle) {
        rotate(new UeVector3(0, 1, 0), angle);
        return self;
    };

    // Rotate around Z axis
    function rotateZ(angle) {
        rotate(new UeVector3(0, 0, 1), angle);
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
    
    function setFromRotationMatrix(m) {
        var te = m.data;

        var m11 = te[0], m12 = te[4], m13 = te[8];
        var m21 = te[1], m22 = te[5], m23 = te[9];
        var m31 = te[2], m32 = te[6], m33 = te[10];
    
        var trace = m11 + m22 + m33;
        var s;
    
        if (trace > 0) {
            s = 0.5 / sqrt(trace + 1.0);
            self.w = 0.25 / s;
            self.x = (m32 - m23) * s;
            self.y = (m13 - m31) * s;
            self.z = (m21 - m12) * s;
        } else if (m11 > m22 && m11 > m33) {
            s = 2.0 * sqrt(1.0 + m11 - m22 - m33);
            self.w = (m32 - m23) / s;
            self.x = 0.25 * s;
            self.y = (m12 + m21) / s;
            self.z = (m13 + m31) / s;
        } else if (m22 > m33) {
            s = 2.0 * sqrt(1.0 + m22 - m11 - m33);
            self.w = (m13 - m31) / s;
            self.x = (m12 + m21) / s;
            self.y = 0.25 * s;
            self.z = (m23 + m32) / s;
        } else {
            s = 2.0 * sqrt(1.0 + m33 - m11 - m22);
            self.w = (m21 - m12) / s;
            self.x = (m13 + m31) / s;
            self.y = (m23 + m32) / s;
            self.z = 0.25 * s;
        }
    
        return self;
    }
    
    function setFromUnitVectors(vFrom, vTo) {
        var EPS = 0.000001;
        var r = vFrom.dot(vTo) + 1;
    
        if (r < EPS) {
            r = 0;
            var axis;
            if (abs(vFrom.x) > abs(vFrom.z)) {
                axis = new Vec3(-vFrom.y, vFrom.x, 0);
            } else {
                axis = new Vec3(0, -vFrom.z, vFrom.y);
            }
            axis.normalize();
    
            self.x = axis.x;
            self.y = axis.y;
            self.z = axis.z;
            self.w = r;
        } else {
            var cross = vFrom.cross(vTo);
    
            self.x = cross.x;
            self.y = cross.y;
            self.z = cross.z;
            self.w = r;
        }
    
        // Normalize the quat
        var len = sqrt(self.x*self.x + self.y*self.y + self.z*self.z + self.w*self.w);
        if (len > 0) {
            var invLen = 1 / len;
            self.x *= invLen;
            self.y *= invLen;
            self.z *= invLen;
            self.w *= invLen;
        }
    
        return self;
    }

    
    setFromEuler(_x, _y, _z);
}