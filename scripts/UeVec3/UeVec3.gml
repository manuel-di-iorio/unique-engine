function Vec3(_x = 0, _y = 0, _z = 0) constructor {
    self.x = _x;
    self.y = _y;
    self.z = _z;
    
    function set(_x, _y, _z) {
        self.x = _x;
        self.y = _y;
        self.z = _z;
    }
    
    function clone() {
        return variable_clone(self);
    }

    function copy(vec) {
        self.x = vec.x;
        self.y = vec.y;
        self.z = vec.z;
        return self;
    }

    function add(vec) {
        self.x += vec.x;
        self.y += vec.y;
        self.z += vec.z;
        return self;
    }

    function sub(vec) {
        self.x -= vec.x;
        self.y -= vec.y;
        self.z -= vec.z;
        return self;
    }

    function multiply(vec) {
        self.x *= vec.x;
        self.y *= vec.y;
        self.z *= vec.z;
        return self;
    }

    function scale(s) {
        self.x *= s;
        self.y *= s;
        self.z *= s;
        return self;
    }

    function dot(vec) {
        return self.x * vec.x + self.y * vec.y + self.z * vec.z;
    }

    function cross(vec) {
        var cx = self.y * vec.z - self.z * vec.y;
        var cy = self.z * vec.x - self.x * vec.z;
        var cz = self.x * vec.y - self.y * vec.x;
        return new Vec3(cx, cy, cz);
    }

    function length() {
        return sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
    }

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

    function equals(vec) {
        return self.x == vec.x && self.y == vec.y && self.z == vec.z;
    }

    function lerp(vec, t) {
        self.x += (vec.x - self.x) * t;
        self.y += (vec.y - self.y) * t;
        self.z += (vec.z - self.z) * t;
        return self;
    }
    
    function angleTo(vec) {
        var dot = dot(vec);
        var len1 = length();
        var len2 = vec.length();
        var denom = len1 * len2;
        if (denom == 0) return 0;
    
        var cos_theta = clamp(dot / denom, -1, 1);
        return arccos(cos_theta);
    }
    
    function distanceTo(vec) {
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        var dz = self.z - vec.z;
        return sqrt(dx * dx + dy * dy + dz * dz);
    }
    
    /// Like distanceTo() but squared. Faster since it avoids the sqrt, useful for render sorting
    function distanceSquaredTo(vec) {
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        var dz = self.z - vec.z;
        return dx * dx + dy * dy + dz * dz;
    }
    
    
}