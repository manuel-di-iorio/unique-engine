function Vec2(_x = 0, _y = 0) constructor {
    self.x = _x;
    self.y = _y;

    function set(_x, _y) {
        self.x = _x;
        self.y = _y;
        return self;
    }

    function clone() {
        return new Vec2(self.x, self.y);
    }

    function copy(vec) {
        self.x = vec.x;
        self.y = vec.y;
        return self;
    }

    function add(vec) {
        self.x += vec.x;
        self.y += vec.y;
        return self;
    }

    function sub(vec) {
        self.x -= vec.x;
        self.y -= vec.y;
        return self;
    }

    function multiply(vec) {
        self.x *= vec.x;
        self.y *= vec.y;
        return self;
    }

    function scale(s) {
        self.x *= s;
        self.y *= s;
        return self;
    }

    function dot(vec) {
        return self.x * vec.x + self.y * vec.y;
    }

    function length() {
        return sqrt(self.x * self.x + self.y * self.y);
    }

    function normalize() {
        var len = length();
        if (len > 0) {
            var inv = 1 / len;
            self.x *= inv;
            self.y *= inv;
        }
        return self;
    }

    function equals(vec) {
        return self.x == vec.x && self.y == vec.y;
    }

    function lerp(vec, t) {
        self.x += (vec.x - self.x) * t;
        self.y += (vec.y - self.y) * t;
        return self;
    }

    function angleTo(vec) {
        var dot = self.dot(vec);
        var len1 = self.length();
        var len2 = vec.length();
        var denom = len1 * len2;
        if (denom == 0) return 0;

        var cos_theta = clamp(dot / denom, -1, 1);
        return arccos(cos_theta);
    }

    function distanceTo(vec) {
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        return sqrt(dx * dx + dy * dy);
    }

    function perp() {
        return new Vec2(-self.y, self.x);
    }

    function rotate(angle) {
        var cosA = cos(angle);
        var sinA = sin(angle);
        var nx = self.x * cosA - self.y * sinA;
        var ny = self.x * sinA + self.y * cosA;
        self.x = nx;
        self.y = ny;
        return self;
    }
}
