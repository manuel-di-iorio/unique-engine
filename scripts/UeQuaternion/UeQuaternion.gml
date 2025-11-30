function UeQuaternion(_x = 0, _y = 0, _z = 0) constructor {
    
    static set = function(x, y, z, w) {
        gml_pragma("forceinline");
        self.x = x;
        self.y = y;
        self.z = z;
        self.w = w;
        return self;
    }
    
    /// Clone the quaternion
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// Copy from another quaternion
    static copy = function(q) {
        gml_pragma("forceinline");
        self.x = q.x;
        self.y = q.y;
        self.z = q.z;
        self.w = q.w;
        return self;
    }

    /// Set quaternion from Euler angles (in degrees)
    static setFromEuler = function(rx, ry, rz) {
        gml_pragma("forceinline");
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
    static normalize = function() {
        gml_pragma("forceinline");
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
    static multiply = function(q) {
        gml_pragma("forceinline");
        var _x = self.x, _y = self.y, _z = self.z, _w = self.w;

        self.x = _w * q.x + _x * q.w + _y * q.z - _z * q.y;
        self.y = _w * q.y - _x * q.z + _y * q.w + _z * q.x;
        self.z = _w * q.z + _x * q.y - _y * q.x + _z * q.w;
        self.w = _w * q.w - _x * q.x - _y * q.y - _z * q.z;

        return self;
    }

    /// Set rotation from axis and angle
    static setFromAxisAngle = function(axis, angle) {
        gml_pragma("forceinline");
        var half = angle * 0.5;
        var s = dsin(half);
        self.x = axis.x * s;
        self.y = axis.y * s;
        self.z = axis.z * s;
        self.w = dcos(half);
        return self;
    }

    /// Spherical linear interpolation
    static slerp = function(q, t) {
        gml_pragma("forceinline");
        var _x = self.x, _y = self.y, _z = self.z, _w = self.w;

        var cosHalfTheta = _x * q.x + _y * q.y + _z * q.z + _w * q.w;

        if (cosHalfTheta < 0) {
            q = new UeQuaternion().set(-q.x, -q.y, -q.z, -q.w);
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
    static rotate = function(axis, angle) {
        gml_pragma("forceinline");
        var q = new UeQuaternion().setFromAxisAngle(axis, angle);
        multiply(q);
        return self;
    }

    // Rotate around X axis
    static rotateX = function(angle) {
        gml_pragma("forceinline");
        rotate(new UeVector3(1, 0, 0), angle);
        return self;
    };

    // Rotate around Y axis
    static rotateY = function(angle) {
        gml_pragma("forceinline");
        rotate(new UeVector3(0, 1, 0), angle);
        return self;
    };

    // Rotate around Z axis
    static rotateZ = function(angle) {
        gml_pragma("forceinline");
        rotate(new UeVector3(0, 0, 1), angle);
        return self;
    };
    
    static toMat3 = function() {
        gml_pragma("forceinline");
        var xx = self.x * self.x;
        var yy = self.y * self.y;
        var zz = self.z * self.z;
        var xy = self.x * self.y;
        var xz = self.x * self.z;
        var yz = self.y * self.z;
        var wx = self.w * self.x;
        var wy = self.w * self.y;
        var wz = self.w * self.z;
    
        return new UeMatrix3([
            1 - 2 * (yy + zz),  2 * (xy - wz),      2 * (xz + wy),
            2 * (xy + wz),      1 - 2 * (xx + zz),  2 * (yz - wx),
            2 * (xz - wy),      2 * (yz + wx),      1 - 2 * (xx + yy)
        ]);
    }
    
    static setFromRotationMatrix = function(m) {
        gml_pragma("forceinline");
        var te = m.data;

        var m11 = te[0], m12 = te[4], m13 = te[8];
        var m21 = te[1], m22 = te[5], m23 = te[9];
        var m31 = te[2], m32 = te[6], m33 = te[10];
        
        if (is_nan(m11) || is_nan(m22) || is_nan(m33)) {
            return self;
        }
    
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
    
    /// Set quaternion that rotates from vFrom to vTo (both must be unit vectors)
    static setFromUnitVectors = function(vFrom, vTo) {
        gml_pragma("forceinline");
        var r = vFrom.dot(vTo);
    
        // Vectors are the same → identity quaternion
        if (r >= 1.0 - UE_EPSILON) {
            return self.set(0, 0, 0, 1);
        }
    
        // Vectors are opposite → rotate 180° around any orthogonal axis
        if (r <= -1.0 + UE_EPSILON) {
            var axis = new UeVector3(0, 0, 1).cross(vFrom);
            if (axis.lengthSq() < UE_EPSILON) {
                axis = new UeVector3(0, 1, 0).cross(vFrom);
            }
            axis.normalize();
            return self.setFromAxisAngle(axis, 180);
        }
    
        // General case
        var cross = vFrom.cross(vTo);
        self.x = cross.x;
        self.y = cross.y;
        self.z = cross.z;
        self.w = 1 + r;
    
        return self.normalize();
    }
    
    static identity = function() {
        self.x = 0;
        self.y = 0;
        self.z = 0;
        self.w = 1;
        return self;
    }
        
    /// Rotates this quaternion toward q by a maximum of `step` radians
    static rotateTowards = function(q, step) {
        gml_pragma("forceinline");
    
        if (step <= 0) return self;
    
        // Clamp il dot product tra -1 e 1
        var cosHalfTheta = clamp(self.dot(q), -1, 1);
    
        // Se già molto vicini (quasi uguali)
        if (cosHalfTheta >= 1.0) return self;
    
        // Calcola l'angolo attuale
        var halfTheta = arccos(cosHalfTheta);
    
        // Se l'angolo è piccolo, o minore dello step, fai direttamente il slerp completo
        if (halfTheta < step) {
            return self.copy(q);
        }
    
        // Calcola il rapporto t di interpolazione da usare
        var t = step / halfTheta;
    
        return self.slerp(q, t);
    }
    
    /// Rotational conjugate of this quaternion
    static conjugate = function() {
        gml_pragma("forceinline");
        self.x = -self.x;
        self.y = -self.y;
        self.z = -self.z;
        // self.w remains unchanged
        return self;
    }
    
    /// Invert (conjugate) the quaternion
    static invert = function() {
        gml_pragma("forceinline");
        var norm = self.lengthSq();
        if (norm > 0) {
            var invNorm = 1 / norm;
            self.x *= -invNorm;
            self.y *= -invNorm;
            self.z *= -invNorm;
            self.w *= invNorm;
        }
        return self;
    }
    
    /// Returns the squared length of the quaternion (avoids sqrt for performance)
    static lengthSq = function() {
        gml_pragma("forceinline");
        return self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w;
    }

    
    /// Return the quaternion length (magnitude)
    static length = function() {
        gml_pragma("forceinline");
        return sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);
    }
    
    static dot = function(q) {
        gml_pragma("forceinline");
        return self.x * q.x + self.y * q.y + self.z * q.z + self.w * q.w;
    }
    
    // Returns the angle in degrees between this quaternion and q. Clamped for stability. Always returns a value in [0, 180°].
    static angleTo = function(q) {
        gml_pragma("forceinline");
        var d = clamp(self.dot(q), -1, 1);
        return radtodeg(2 * arccos(abs(d)));
    }

    
    static multiplyQuaternions = function(a, b) {
        gml_pragma("forceinline");
    
        var ax = a.x, ay = a.y, az = a.z, aw = a.w;
        var bx = b.x, by = b.y, bz = b.z, bw = b.w;
    
        self.x = ax * bw + aw * bx + ay * bz - az * by;
        self.y = ay * bw + aw * by + az * bx - ax * bz;
        self.z = az * bw + aw * bz + ax * by - ay * bx;
        self.w = aw * bw - ax * bx - ay * by - az * bz;
    
        return self;
    }
    
    static equals = function(q) {
        gml_pragma("forceinline");
        if (abs(self.x - q.x) <= UE_EPSILON && abs(self.y - q.y) <= UE_EPSILON && abs(self.z - q.z) <= UE_EPSILON && abs(self.w - q.w) <= UE_EPSILON) return true;
        if (abs(self.x + q.x) <= UE_EPSILON && abs(self.y + q.y) <= UE_EPSILON && abs(self.z + q.z) <= UE_EPSILON && abs(self.w + q.w) <= UE_EPSILON) return true;
        return false;
    }
    
    static toArray = function() {
        gml_pragma("forceinline");
        return [self.x, self.y, self.z, self.w];
    }
    
    setFromEuler(_x, _y, _z);
}
