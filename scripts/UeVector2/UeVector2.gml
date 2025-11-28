function UeVector2(_x = 0, _y = 0) constructor {
    /// @desc Creates a 2D vector with components x and y
    self.x = _x;
    self.y = _y;

    /// @func set(_x, _y)
    /// @desc Sets both vector components to the given values.
    /// @param _x New X value
    /// @param _y New Y value
    static set = function(_x, _y) {
        gml_pragma("forceinline");
        self.x = _x;
        self.y = _y;
        return self;
    }

    /// @func clone()
    /// @desc Returns a new vector instance with the same components.
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// @func copy(vec)
    /// @desc Copies another vector's components into this one.
    /// @param vec The vector to copy
    static copy = function(vec) {
        gml_pragma("forceinline");
        self.x = vec.x;
        self.y = vec.y;
        return self;
    }

    /// @func add(vec)
    /// @desc Adds another vector to this one (component-wise).
    /// @param vec The vector to add
    static add = function(vec) {
        gml_pragma("forceinline");
        self.x += vec.x;
        self.y += vec.y;
        return self;
    }

    /// @func sub(vec)
    /// @desc Subtracts another vector from this one (component-wise).
    /// @param vec The vector to subtract
    static sub = function(vec) {
        gml_pragma("forceinline");
        self.x -= vec.x;
        self.y -= vec.y;
        return self;
    }

    /// @func multiply(vec)
    /// @desc Multiplies this vector by another vector (component-wise).
    /// @param vec The vector whose components are used as multipliers
    static multiply = function(vec) {
        gml_pragma("forceinline");
        self.x *= vec.x;
        self.y *= vec.y;
        return self;
    }

    /// @func scale(s)
    /// @desc Multiplies both components by a scalar value.
    /// @param s The scalar multiplier
    static scale = function(s) {
        gml_pragma("forceinline");
        self.x *= s;
        self.y *= s;
        return self;
    }

    /// @func dot(vec)
    /// @desc Computes the dot product with another vector.
    /// @param vec The other vector
    /// @return Scalar dot product
    static dot = function(vec) {
        gml_pragma("forceinline");
        return self.x * vec.x + self.y * vec.y;
    }

    /// @func length()
    /// @desc Returns the length (magnitude) of the vector.
    /// @return The vector magnitude
    static length = function() {
        return sqrt(self.x * self.x + self.y * self.y);
    }

    /// @func normalize()
    /// @desc Normalizes the vector (sets its length to 1).
    /// @return The vector itself
    static normalize = function() {
        gml_pragma("forceinline");
        var len = length();
        if (len > 0) {
            var inv = 1 / len;
            self.x *= inv;
            self.y *= inv;
        }
        return self;
    }

    /// @func equals(vec)
    /// @desc Checks if both components are exactly equal to another vector.
    /// @param vec The vector to compare
    /// @return Boolean
    static equals = function(vec) {
        gml_pragma("forceinline");
        return self.x == vec.x && self.y == vec.y;
    }

    /// @func lerp(vec, t)
    /// @desc Linearly interpolates towards another vector by factor t.
    /// @param vec Target vector
    /// @param t Interpolation value [0..1]
    /// @return The vector itself
    static lerp = function(vec, t) {
        gml_pragma("forceinline");
        self.x += (vec.x - self.x) * t;
        self.y += (vec.y - self.y) * t;
        return self;
    }

    /// @func angleTo(vec)
    /// @desc Computes the angle (in degrees) between this vector and another.
    /// @param vec The other vector
    /// @return Angle in degrees
    static angleTo = function(vec) {
        gml_pragma("forceinline");
        var _dot = self.dot(vec);
        var _len1 = self.length();
        var _len2 = vec.length();
        var _denom = _len1 * _len2;
        if (_denom == 0) return 0;

        var cos_theta = clamp(_dot / _denom, -1, 1);
        return darccos(cos_theta);
    }

    /// @func distanceTo(vec)
    /// @desc Returns the Euclidean distance to another vector.
    /// @param vec The other vector
    /// @return Distance value
    static distanceTo = function(vec) {
        gml_pragma("forceinline");
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        return sqrt(dx * dx + dy * dy);
    }

    /// @func perp()
    /// @desc Returns a perpendicular vector (rotated 90 degrees left).
    /// @return A new UeVector2 instance
    static perp = function() {
        gml_pragma("forceinline");
        return new UeVector2(-self.y, self.x);
    }

    /// @func rotate(angle)
    /// @desc Rotates the vector by a given angle (in degrees).
    /// @param angle Rotation angle in degrees
    /// @return The vector itself
    static rotate = function(angle) {
        gml_pragma("forceinline");
        var cosA = dcos(angle);
        var sinA = dsin(angle);
        var nx = self.x * cosA - self.y * sinA;
        var ny = self.x * sinA + self.y * cosA;
        self.x = nx;
        self.y = ny;
        return self;
    }
}
