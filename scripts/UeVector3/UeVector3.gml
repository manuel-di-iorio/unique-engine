function UeVector3(_x = 0, _y = 0, _z = 0) constructor {
    self.x = _x;
    self.y = _y;
    self.z = _z;

    /// Sets the components of this vector.
    function set(_x, _y, _z) {
        self.x = _x;
        self.y = _y;
        self.z = _z;
        return self;
    }
    
    /// Returns a deep clone of this vector.
    function clone() {
        return variable_clone(self);
    }

    /// Copies the values from another vector into this one.
    function copy(vec) {
        self.x = vec.x;
        self.y = vec.y;
        self.z = vec.z;
        return self;
    }

    /// Adds another vector to this one.
    function add(vec) {
        self.x += vec.x;
        self.y += vec.y;
        self.z += vec.z;
        return self;
    }

    /// Subtracts another vector from this one.
    function sub(vec) {
        self.x -= vec.x;
        self.y -= vec.y;
        self.z -= vec.z;
        return self;
    }

    /// Multiplies each component by the corresponding component of another vector.
    function multiply(vec) {
        self.x *= vec.x;
        self.y *= vec.y;
        self.z *= vec.z;
        return self;
    }

    /// Scales this vector uniformly by a scalar.
    function scale(s) {
        self.x *= s;
        self.y *= s;
        self.z *= s;
        return self;
    }

    /// Returns the dot product with another vector.
    function dot(vec) {
        return self.x * vec.x + self.y * vec.y + self.z * vec.z;
    }

    /// Returns the cross product with another vector.
    function cross(vec) {
        var cx = self.y * vec.z - self.z * vec.y;
        var cy = self.z * vec.x - self.x * vec.z;
        var cz = self.x * vec.y - self.y * vec.x;
        return new UeVector3(cx, cy, cz);
    }

    /// Returns the Euclidean length (magnitude) of this vector.
    function length() {
        return sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

    /// Normalizes the vector to unit length.
    function normalize() {
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
    function equals(vec) {
        return self.x == vec.x && self.y == vec.y && self.z == vec.z;
    }

    /// Linearly interpolates towards another vector by a factor t (0..1).
    function lerp(vec, t) {
        self.x += (vec.x - self.x) * t;
        self.y += (vec.y - self.y) * t;
        self.z += (vec.z - self.z) * t;
        return self;
    }

    /// Returns the angle to another vector in radians.
    function angleTo(vec) {
        var dot = dot(vec);
        var len1 = length();
        var len2 = vec.length();
        var denom = len1 * len2;
        if (denom == 0) return 0;

        var cos_theta = clamp(dot / denom, -1, 1);
        return darccos(cos_theta);
    }

    /// Returns the Euclidean distance to another vector.
    function distanceTo(vec) {
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        var dz = self.z - vec.z;
        return sqrt(dx * dx + dy * dy + dz * dz);
    }

    /// Returns squared distance to another vector (faster than distance).
    function distanceToSquared(vec) {
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        var dz = self.z - vec.z;
        return dx * dx + dy * dy + dz * dz;
    }

    /// Adds a scalar to each component.
    function addScalar(s) {
        self.x += s;
        self.y += s;
        self.z += s;
        return self;
    }

    /// Adds a scaled version of another vector.
    function addScaledVector(vec, scale) {
        self.x += vec.x * scale;
        self.y += vec.y * scale;
        self.z += vec.z * scale;
        return self;
    }

    /// Sets this vector as the sum of two other vectors.
    function addVectors(a, b) {
        self.x = a.x + b.x;
        self.y = a.y + b.y;
        self.z = a.z + b.z;
        return self;
    }

    /// Clamps each component between corresponding min and max vector components.
    function clamp(minVec, maxVec) {
        self.x = clamp(self.x, minVec.x, maxVec.x);
        self.y = clamp(self.y, minVec.y, maxVec.y);
        self.z = clamp(self.z, minVec.z, maxVec.z);
        return self;
    }

    /// Clamps each component between two scalar values.
    function clampScalar(minVal, maxVal) {
        self.x = clamp(self.x, minVal, maxVal);
        self.y = clamp(self.y, minVal, maxVal);
        self.z = clamp(self.z, minVal, maxVal);
        return self;
    }

    /// Clamps the vector’s length between two values.
    function clampLength(minLen, maxLen) {
        var len = length();
        return setLength(clamp(len, minLen, maxLen));
    }

    /// Divides this vector by another vector component-wise.
    function divide(vec) {
        self.x /= vec.x;
        self.y /= vec.y;
        self.z /= vec.z;
        return self;
    }

    /// Divides this vector by a scalar.
    function divideScalar(scalar) {
        return self.scale(1 / scalar);
    }

    /// Applies floor() to each component.
    function floor() {
        self.x = floor(self.x);
        self.y = floor(self.y);
        self.z = floor(self.z);
        return self;
    }

    /// Applies ceil() to each component.
    function ceil() {
        self.x = ceil(self.x);
        self.y = ceil(self.y);
        self.z = ceil(self.z);
        return self;
    }

    /// Rounds each component to the nearest integer.
    function round() {
        self.x = round(self.x);
        self.y = round(self.y);
        self.z = round(self.z);
        return self;
    }

    /// Rounds each component toward zero.
    function roundToZero() {
        self.x = (self.x < 0) ? ceil(self.x) : floor(self.x);
        self.y = (self.y < 0) ? ceil(self.y) : floor(self.y);
        self.z = (self.z < 0) ? ceil(self.z) : floor(self.z);
        return self;
    }

    /// Returns the squared length of this vector.
    function lengthSq() {
        return self.x * self.x + self.y * self.y + self.z * self.z;
    }

    /// Returns the Manhattan length (sum of absolute components).
    function manhattanLength() {
        return abs(self.x) + abs(self.y) + abs(self.z);
    }

    /// Returns the Manhattan distance to another vector.
    function manhattanDistanceTo(vec) {
        return abs(self.x - vec.x) + abs(self.y - vec.y) + abs(self.z - vec.z);
    }

    /// Multiplies this vector by a scalar.
    function multiplyScalar(s) {
        return scale(s);
    }

    /// Sets this vector as the component-wise multiplication of two other vectors.
    function multiplyVectors(a, b) {
        self.x = a.x * b.x;
        self.y = a.y * b.y;
        self.z = a.z * b.z;
        return self;
    }

    /// Negates each component.
    function negate() {
        self.x = -self.x;
        self.y = -self.y;
        self.z = -self.z;
        return self;
    }

    /// Sets all components to the given scalar.
    function setScalar(scalar) {
        self.x = self.y = self.z = scalar;
        return self;
    }

    /// Sets only the X component.
    function setX(x) {
        self.x = x;
        return self;
    }

    /// Sets only the Y component.
    function setY(y) {
        self.y = y;
        return self;
    }

    /// Sets only the Z component.
    function setZ(z) {
        self.z = z;
        return self;
    }

    /// Subtracts a scalar from all components.
    function subScalar(s) {
        self.x -= s;
        self.y -= s;
        self.z -= s;
        return self;
    }

    /// Sets this vector as the difference of two vectors.
    function subVectors(a, b) {
        self.x = a.x - b.x;
        self.y = a.y - b.y;
        self.z = a.z - b.z;
        return self;
    }

    /// Transforms this vector by a 3x3 matrix.
    function applyMatrix3(m) {
        var xx = self.x, yy = self.y, zz = self.z;
        var e = m.data;
        self.x = e[0]*xx + e[3]*yy + e[6]*zz;
        self.y = e[1]*xx + e[4]*yy + e[7]*zz;
        self.z = e[2]*xx + e[5]*yy + e[8]*zz;
        return self;
    }

    /// Projects this vector into NDC space using camera matrices.
    /// @param {UeCamera} camera
    function project(camera) {
        applyMatrix4(camera.matrixWorldInverse)
        applyMatrix4(camera.projectionMatrix);
        return self;
    }

    /// Unprojects this vector from NDC space back to world space.
    /// @param {UeCamera} camera
    function unproject(camera) {
        applyMatrix4(camera.projectionMatrixInverse);
        applyMatrix4(camera.matrixWorld);
        return self;
    }

    /// Transforms the direction only (ignores translation), then normalizes.
    function transformDirection(m) {
        var xx = self.x, yy = self.y, zz = self.z;
        var e = m.data;
        self.x = e[0]*xx + e[4]*yy + e[8]*zz;
        self.y = e[1]*xx + e[5]*yy + e[9]*zz;
        self.z = e[2]*xx + e[6]*yy + e[10]*zz;
        return self.normalize();
    }

    /// Transforms this vector by a 4x4 matrix (full 3D point transform).
    function applyMatrix4(m) {
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
    function applyNormalMatrix(m) {
        applyMatrix3(m);
        return self.normalize();
    }

    /// Projects this vector onto a plane defined by a normal.
    function projectOnPlane(normal) {
        var v = normal.clone().scale(self.dot(normal));
        return self.sub(v);
    }

    /// Projects this vector onto a direction vector.
    function projectOnVector(v) {
        var scalar = self.dot(v) / v.dot(v);
        return self.copy(v).scale(scalar);
    }

    /// Reflects this vector over a given normal.
    function reflect(normal) {
        return self.sub(normal.clone().scale(2 * self.dot(normal)));
    }

    /// Sets the vector length to a given value.
    function setLength(l) {
        var old = length();
        return old != 0 ? self.scale(l / old) : self.scale(0);
    }

    /// Sets components from a simple array.
    function fromArray(arr, offset = 0) {
        self.x = arr[offset];
        self.y = arr[offset + 1];
        self.z = arr[offset + 2];
        return self;
    }

    /// Gets a specific component by index (0 = x, 1 = y, 2 = z).
    function getComponent(index) {
        if (index == 0) return self.x;
        if (index == 1) return self.y;
        if (index == 2) return self.z;
    }

    /// Copies components into an array (or creates one).
    function toArray(arr = undefined, offset = 0) {
        arr ??= [];
        arr[offset]     = self.x;
        arr[offset + 1] = self.y;
        arr[offset + 2] = self.z;
        return arr;
    }

    /// Sets random values in the [0, 1) range.
    function random() {
        self.x = random_range(0, 1);
        self.y = random_range(0, 1);
        self.z = random_range(0, 1);
        return self;
    }

    /// Sets this vector to a random direction on the unit sphere.
    function randomDirection() {
        var theta = random_range(0, 2 * pi);
        var phi = arccos(random_range(-1, 1));
        var sinPhi = sin(phi);
        self.x = sinPhi * cos(theta);
        self.y = sinPhi * sin(theta);
        self.z = cos(phi);
        return self;
    }
    
    /// @MissingDoc
    /// Sets components from the column at index in a 4x4 matrix.
    function setFromMatrixColumn(matrix, index) {
        var e = matrix.data;
        self.x = e[index * 4 + 0];
        self.y = e[index * 4 + 1];
        self.z = e[index * 4 + 2];
        return self;
    }
    
    /// @MissingDoc
    /// Sets components from the column at index in a 3x3 matrix.
    function setFromMatrix3Column(matrix, index) {
        var e = matrix.data;
        self.x = e[index * 3 + 0];
        self.y = e[index * 3 + 1];
        self.z = e[index * 3 + 2];
        return self;
    }
    
    // @MissingDoc
    function setFromMatrixPosition(mat) {
        var e = mat.data;
    
        // Elements 12, 13, 14 contain the translation component (column 4)
        self.x = e[12];
        self.y = e[13];
        self.z = e[14];
    
        return self;
    }
    
    // @MissingDoc
    function setFromMatrixScale(mat) {
        var te = mat.data;

        // Extract basis vectors (columns of the upper-left 3x3)
        self.x = global.UE_DUMMY_VECTOR3.set(te[0], te[1], te[2]).length();
        self.y = global.UE_DUMMY_VECTOR3.set(te[4], te[5], te[6]).length();
        self.z = global.UE_DUMMY_VECTOR3.set(te[8], te[9], te[10]).length();

        return self;
    }
    
    /// @MissingDoc
    /// Sets a single component by index (0 = x, 1 = y, 2 = z).
    function setComponent(index, value) {
        if (index == 0) self.x = value;
        else if (index == 1) self.y = value;
        else if (index == 2) self.z = value;
        return self;
    }
    
    /// @MissingDoc
    /// Replaces each component with the min between self and vec.
    function min(vec) {
        self.x = min(self.x, vec.x);
        self.y = min(self.y, vec.y);
        self.z = min(self.z, vec.z);
        return self;
    }
        
        /// @MissingDoc
    /// Replaces each component with the max between self and vec.
    function max(vec) {
        self.x = max(self.x, vec.x);
        self.y = max(self.y, vec.y);
        self.z = max(self.z, vec.z);
        return self;
    }
    
    /// @MissingDoc
    /// Sets components using spherical coordinates.
    function setFromSphericalCoords(radius, phi, theta) {
        self.x = radius * sin(phi) * cos(theta);
        self.y = radius * cos(phi);
        self.z = radius * sin(phi) * sin(theta);
        return self;
    }
    
    /// @MissingDoc
    /// Sets components using cylindrical coordinates.
    function setFromCylindricalCoords(radius, theta, y) {
        self.x = radius * cos(theta);
        self.z = radius * sin(theta);
        self.y = y;
        return self;
    }
}
