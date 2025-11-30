function UeVector3(_x = 0, _y = 0, _z = 0) constructor {
    self.x = _x;
    self.y = _y;
    self.z = _z;

    /// Sets the components of this vector.
    static set = function(_x, _y, _z) {
        gml_pragma("forceinline");
        self.x = _x;
        self.y = _y;
        self.z = _z;
        return self;
    }
    
    /// Returns a deep clone of this vector.
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// Copies the values from another vector into this one.
    static copy = function(vec) {
        gml_pragma("forceinline");
        self.x = vec.x;
        self.y = vec.y;
        self.z = vec.z;
        return self;
    }

    /// Adds another vector to this one.
    static add = function(vec) {
        gml_pragma("forceinline");
        self.x += vec.x;
        self.y += vec.y;
        self.z += vec.z;
        return self;
    }

    /// Subtracts another vector from this one.
    static sub = function(vec) {
        gml_pragma("forceinline");
        self.x -= vec.x;
        self.y -= vec.y;
        self.z -= vec.z;
        return self;
    }

    /// Multiplies each component by the corresponding component of another vector.
    static multiply = function(vec) {
        gml_pragma("forceinline");
        self.x *= vec.x;
        self.y *= vec.y;
        self.z *= vec.z;
        return self;
    }

    /// Scales this vector uniformly by a scalar.
    static scale = function(s) {
        gml_pragma("forceinline");
        self.x *= s;
        self.y *= s;
        self.z *= s;
        return self;
    }

    /// Returns the dot product with another vector.
    static dot = function(vec) {
        gml_pragma("forceinline");
        return self.x * vec.x + self.y * vec.y + self.z * vec.z;
    }

    /// Returns the cross product with another vector.
    static cross = function(vec) {
        gml_pragma("forceinline");
        var cx = self.y * vec.z - self.z * vec.y;
        var cy = self.z * vec.x - self.x * vec.z;
        var cz = self.x * vec.y - self.y * vec.x;
        return new UeVector3(cx, cy, cz);
    }
    
    // Sets this vector to cross product of a and b.
    static crossVectors = function(a, b) {
        self.x = a.y * b.z - a.z * b.y;
        self.y = a.z * b.x - a.x * b.z;
        self.z = a.x * b.y - a.y * b.x;
        return self;
    }

    /// Returns the Euclidean length (magnitude) of this vector.
    static length = function() {
        gml_pragma("forceinline");
        return sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    /// Normalizes the vector to unit length.
    static normalize = function() {
        gml_pragma("forceinline");
        var len = length();
        if (len > 0) {
            var inv = 1 / len;
            self.x *= inv;
            self.y *= inv;
            self.z *= inv;
        }
        return self;
    }

    /// Returns true if all components match the given vector.
    static equals = function(vec) {
        gml_pragma("forceinline");
        return self.x == vec.x && self.y == vec.y && self.z == vec.z;
    }

    /// Linearly interpolates towards another vector by a factor t (0..1).
    static lerp = function(vec, t) {
        gml_pragma("forceinline");
        self.x += (vec.x - self.x) * t;
        self.y += (vec.y - self.y) * t;
        self.z += (vec.z - self.z) * t;
        return self;
    }

    /// Returns the angle to another vector in degrees.
    static angleTo = function(vec) {
        gml_pragma("forceinline");
        var _dot = dot(vec);
        var _len1 = length();
        var _len2 = vec.length();
        var _denom = _len1 * _len2;
        if (_denom == 0) return 0;

        var cos_theta = clamp(_dot / _denom, -1, 1);
        return darccos(cos_theta);
    }

    /// Returns the Euclidean distance to another vector.
    static distanceTo = function(vec) {
        gml_pragma("forceinline");
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        var dz = self.z - vec.z;
        return sqrt(dx * dx + dy * dy + dz * dz);
    }

    /// Returns squared distance to another vector (faster than distance).
    static distanceToSquared = function(vec) {
        gml_pragma("forceinline");
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        var dz = self.z - vec.z;
        return dx * dx + dy * dy + dz * dz;
    }

    /// Adds a scalar to each component.
    static addScalar = function(s) {
        gml_pragma("forceinline");
        self.x += s;
        self.y += s;
        self.z += s;
        return self;
    }

    /// Adds a scaled version of another vector.
    static addScaledVector = function(vec, scale) {
        gml_pragma("forceinline");
        self.x += vec.x * scale;
        self.y += vec.y * scale;
        self.z += vec.z * scale;
        return self;
    }

    /// Sets this vector as the sum of two other vectors.
    static addVectors = function(a, b) {
        gml_pragma("forceinline");
        self.x = a.x + b.x;
        self.y = a.y + b.y;
        self.z = a.z + b.z;
        return self;
    }

    /// Clamps each component between corresponding min and max vector components.
    static clamp = function(minVec, maxVec) {
        gml_pragma("forceinline");
        self.x = clamp(self.x, minVec.x, maxVec.x);
        self.y = clamp(self.y, minVec.y, maxVec.y);
        self.z = clamp(self.z, minVec.z, maxVec.z);
        return self;
    }

    /// Clamps each component between two scalar values.
    static clampScalar = function(minVal, maxVal) {
        gml_pragma("forceinline");
        self.x = clamp(self.x, minVal, maxVal);
        self.y = clamp(self.y, minVal, maxVal);
        self.z = clamp(self.z, minVal, maxVal);
        return self;
    }

    /// Clamps the vector’s length between two values.
    static clampLength = function(minLen, maxLen) {
        gml_pragma("forceinline");
        var len = length();
        return setLength(clamp(len, minLen, maxLen));
    }

    /// Divides this vector by another vector component-wise.
    static divide = function(vec) {
        gml_pragma("forceinline");
        self.x /= vec.x;
        self.y /= vec.y;
        self.z /= vec.z;
        return self;
    }

    /// Divides this vector by a scalar.
    static divideScalar = function(scalar) {
        gml_pragma("forceinline");
        return self.multiplyScalar(1 / scalar);
    }

    /// Applies floor() to each component.
    static floor = function() {
        gml_pragma("forceinline");
        self.x = floor(self.x);
        self.y = floor(self.y);
        self.z = floor(self.z);
        return self;
    }

    /// Applies ceil() to each component.
    static ceil = function() {
        gml_pragma("forceinline");
        self.x = ceil(self.x);
        self.y = ceil(self.y);
        self.z = ceil(self.z);
        return self;
    }

    /// Rounds each component to the nearest integer.
    static roundVec = function() {
        gml_pragma("forceinline");
        self.x = round(self.x);
        self.y = round(self.y);
        self.z = round(self.z);
        return self;
    }

    /// Rounds each component toward zero.
    static roundToZero = function() {
        gml_pragma("forceinline");
        self.x = (self.x < 0) ? ceil(self.x) : floor(self.x);
        self.y = (self.y < 0) ? ceil(self.y) : floor(self.y);
        self.z = (self.z < 0) ? ceil(self.z) : floor(self.z);
        return self;
    }

    /// Returns the squared length of this vector.
    static lengthSq = function() {
        gml_pragma("forceinline");
        return self.x * self.x + self.y * self.y + self.z * self.z;
    }

    /// Returns the Manhattan length (sum of absolute components).
    static manhattanLength = function() {
        gml_pragma("forceinline");
        return abs(self.x) + abs(self.y) + abs(self.z);
    }

    /// Returns the Manhattan distance to another vector.
    static manhattanDistanceTo = function(vec) {
        gml_pragma("forceinline");
        return abs(self.x - vec.x) + abs(self.y - vec.y) + abs(self.z - vec.z);
    }

    /// Multiplies this vector by a scalar.
    static multiplyScalar = function(s) {
        gml_pragma("forceinline");
        self.x *= s;
        self.y *= s;
        self.z *= s;
        return self;
    }

    /// Sets this vector as the component-wise multiplication of two other vectors.
    static multiplyVectors = function(a, b) {
        gml_pragma("forceinline");
        self.x = a.x * b.x;
        self.y = a.y * b.y;
        self.z = a.z * b.z;
        return self;
    }

    /// Negates each component.
    static negate = function() {
        gml_pragma("forceinline");
        self.x = -self.x;
        self.y = -self.y;
        self.z = -self.z;
        return self;
    }

    /// Sets all components to the given scalar.
    static setScalar = function(scalar) {
        gml_pragma("forceinline");
        self.x = scalar;
        self.y = scalar;
        self.z = scalar;
        return self;
    }

    /// Sets only the X component.
    static setX = function(x) {
        gml_pragma("forceinline");
        self.x = x;
        return self;
    }

    /// Sets only the Y component.
    static setY = function(y) {
        gml_pragma("forceinline");
        self.y = y;
        return self;
    }

    /// Sets only the Z component.
    static setZ = function(z) {
        gml_pragma("forceinline");
        self.z = z;
        return self;
    }

    /// Subtracts a scalar from all components.
    static subScalar = function(s) {
        gml_pragma("forceinline");
        self.x -= s;
        self.y -= s;
        self.z -= s;
        return self;
    }

    /// Sets this vector as the difference of two vectors.
    static subVectors = function(a, b) {
        gml_pragma("forceinline");
        self.x = a.x - b.x;
        self.y = a.y - b.y;
        self.z = a.z - b.z;
        return self;
    }

    /// Transforms this vector by a 3x3 matrix.
    static applyMatrix3 = function(m) {
        gml_pragma("forceinline");
        var xx = self.x, yy = self.y, zz = self.z;
        var e = m.data;
        self.x = e[0]*xx + e[3]*yy + e[6]*zz;
        self.y = e[1]*xx + e[4]*yy + e[7]*zz;
        self.z = e[2]*xx + e[5]*yy + e[8]*zz;
        return self;
    }

    /// Projects this vector into NDC space using camera matrices.
    /// @param {UeCamera} camera
    static project = function(camera) {
        gml_pragma("forceinline");
        applyMatrix4(camera.matrixWorldInverse)
        applyMatrix4(camera.projectionMatrix);
        return self;
    }

    /// Unprojects this vector from NDC space back to world space.
    /// @param {UeCamera} camera
    static unproject = function(camera) {
        gml_pragma("forceinline");
        applyMatrix4(camera.projectionMatrixInverse);
        applyMatrix4(camera.matrixWorld);
        return self;
    }

    /// Transforms the direction only (ignores translation), then normalizes.
    static transformDirection = function(m) {
        gml_pragma("forceinline");
        var xx = self.x, yy = self.y, zz = self.z;
        var e = m.data;
        self.x = e[0]*xx + e[4]*yy + e[8]*zz;
        self.y = e[1]*xx + e[5]*yy + e[9]*zz;
        self.z = e[2]*xx + e[6]*yy + e[10]*zz;
        return self.normalize();
    }

    /// Transforms this vector by a 4x4 matrix (full 3D point transform).
    static applyMatrix4 = function(m) {
        gml_pragma("forceinline");
        var xx = self.x, yy = self.y, zz = self.z;
        var e = m.data;
        var w = e[3]*xx + e[7]*yy + e[11]*zz + e[15];
        w = w != 0 ? 1 / w : 1;
        self.x = (e[0]*xx + e[4]*yy + e[8]*zz + e[12]) * w;
        self.y = (e[1]*xx + e[5]*yy + e[9]*zz + e[13]) * w;
        self.z = (e[2]*xx + e[6]*yy + e[10]*zz + e[14]) * w;
        return self;
    }

    /// Applies a normal matrix (3x3) and normalizes the result.
    static applyNormalMatrix = function(m) {
        gml_pragma("forceinline");
        applyMatrix3(m);
        return self.normalize();
    }

    /// Projects this vector onto a plane defined by a normal.
    static projectOnPlane = function(normal) {
        gml_pragma("forceinline");
        var v = normal.clone().multiplyScalar(self.dot(normal));
        return self.sub(v);
    }

    /// Projects this vector onto a direction vector.
    static projectOnVector = function(v) {
        gml_pragma("forceinline");
        var scalar = self.dot(v) / v.dot(v);
        return self.copy(v).multiplyScalar(scalar);
    }

    /// Reflects this vector over a given normal.
    static reflect = function(normal) {
        gml_pragma("forceinline");
        return self.sub(normal.clone().multiplyScalar(2 * self.dot(normal)));
    }

    /// Sets the vector length to a given value.
    static setLength = function(l) {
        gml_pragma("forceinline");
        var old = length();
        return old != 0 ? self.multiplyScalar(l / old) : self.multiplyScalar(0);
    }

    /// Sets components from a simple array.
    static fromArray = function(arr, offset = 0) {
        gml_pragma("forceinline");
        self.x = arr[offset];
        self.y = arr[offset + 1];
        self.z = arr[offset + 2];
        return self;
    }

    /// Gets a specific component by index (0 = x, 1 = y, 2 = z).
    static getComponent = function(index) {
        gml_pragma("forceinline");
        if (index == 0) return self.x;
        if (index == 1) return self.y;
        if (index == 2) return self.z;
    }

    /// Copies components into an array (or creates one).
    static toArray = function(arr = undefined, offset = 0) {
        gml_pragma("forceinline");
        arr ??= [];
        arr[offset]     = self.x;
        arr[offset + 1] = self.y;
        arr[offset + 2] = self.z;
        return arr;
    }

    /// Sets random values in the [0, 1) range.
    static random = function() {
        gml_pragma("forceinline");
        self.x = random_range(0, 1);
        self.y = random_range(0, 1);
        self.z = random_range(0, 1);
        return self;
    }

    /// Sets this vector to a random direction on the unit sphere.
    static randomDirection = function() {
        gml_pragma("forceinline");
        var theta = random_range(0, 2 * pi);
        var phi = arccos(random_range(-1, 1));
        var sinPhi = sin(phi);
        self.x = sinPhi * cos(theta);
        self.y = sinPhi * sin(theta);
        self.z = cos(phi);
        return self;
    }
    
    /// Sets components from the column at index in a 4x4 matrix.
    static setFromMatrixColumn = function(matrix, index) {
        gml_pragma("forceinline");
        var e = matrix.data;
        self.x = e[index * 4 + 0];
        self.y = e[index * 4 + 1];
        self.z = e[index * 4 + 2];
        return self;
    }
    
    /// Sets components from the column at index in a 3x3 matrix.
    static setFromMatrix3Column = function(matrix, index) {
        gml_pragma("forceinline");
        var e = matrix.data;
        self.x = e[index * 3 + 0];
        self.y = e[index * 3 + 1];
        self.z = e[index * 3 + 2];
        return self;
    }
    
    static setFromMatrixPosition = function(mat) {
        gml_pragma("forceinline");
        var e = mat.data;
    
        // Elements 12, 13, 14 contain the translation component (column 4)
        self.x = e[12];
        self.y = e[13];
        self.z = e[14];
    
        return self;
    }
    
    static setFromMatrixScale = function(mat) {
        gml_pragma("forceinline");
        var te = mat.data;

        // Extract basis vectors (columns of the upper-left 3x3)
        self.x = global.UE_DUMMY_VECTOR3.set(te[0], te[1], te[2]).length();
        self.y = global.UE_DUMMY_VECTOR3.set(te[4], te[5], te[6]).length();
        self.z = global.UE_DUMMY_VECTOR3.set(te[8], te[9], te[10]).length();

        return self;
    }
    
    /// Sets a single component by index (0 = x, 1 = y, 2 = z).
    static setComponent = function(index, value) {
        gml_pragma("forceinline");
        if (index == 0) self.x = value;
        else if (index == 1) self.y = value;
        else if (index == 2) self.z = value;
        return self;
    }
    
    /// Replaces each component with the min between self and vec.
    static minVec = function(vec) {
        gml_pragma("forceinline");
        self.x = min(self.x, vec.x);
        self.y = min(self.y, vec.y);
        self.z = min(self.z, vec.z);
        return self;
    }
        
    /// Replaces each component with the max between self and vec.
    static maxVec = function(vec) {
        gml_pragma("forceinline");
        self.x = max(self.x, vec.x);
        self.y = max(self.y, vec.y);
        self.z = max(self.z, vec.z);
        return self;
    }
    
    /// Sets components using spherical coordinates.
    static setFromSphericalCoords = function(radius, phi, theta) {
        gml_pragma("forceinline");
        self.x = radius * sin(phi) * cos(theta);
        self.y = radius * cos(phi);
        self.z = radius * sin(phi) * sin(theta);
        return self;
    }
    
    /// Sets components using cylindrical coordinates.
    static setFromCylindricalCoords = function(radius, theta, y) {
        gml_pragma("forceinline");
        self.x = radius * cos(theta);
        self.z = radius * sin(theta);
        self.y = y;
        return self;
    }
    
    static applyQuaternion = function(q) {
        gml_pragma("forceinline");
        var xx = self.x, yy = self.y, zz = self.z;
        var qx = q.x, qy = q.y, qz = q.z, qw = q.w;
    
        var ix =  qw * xx + qy * zz - qz * yy;
        var iy =  qw * yy + qz * xx - qx * zz;
        var iz =  qw * zz + qx * yy - qy * xx;
        var iw = -qx * xx - qy * yy - qz * zz;
    
        self.x = ix * qw + iw * -qx + iy * -qz - iz * -qy;
        self.y = iy * qw + iw * -qy + iz * -qx - ix * -qz;
        self.z = iz * qw + iw * -qz + ix * -qy - iy * -qx;
    
        return self;
    }
    
    // Rotate around the specified axis by the angle (degrees)
    static applyAxisAngle = function(axis, angle) {
        gml_pragma("forceinline");
        var xx = self.x, yy = self.y, zz = self.z;
        var ax = axis.x, ay = axis.y, az = axis.z;
    
        var cosA = dcos(angle);
        var sinA = dsin(angle);
        var t = 1 - cosA;
    
        // Rodrigues' rotation formula
        self.x = (t * ax * ax + cosA) * xx + (t * ax * ay - sinA * az) * yy + (t * ax * az + sinA * ay) * zz;
        self.y = (t * ax * ay + sinA * az) * xx + (t * ay * ay + cosA) * yy + (t * ay * az - sinA * ax) * zz;
        self.z = (t * ax * az - sinA * ay) * xx + (t * ay * az + sinA * ax) * yy + (t * az * az + cosA) * zz;
    
        return self;
    }
    
    static applyEuler = function(x, y, z) {
        
    }
}

