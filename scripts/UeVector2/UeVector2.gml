function UeVector2(_x = 0, _y = 0) constructor {
    self.x = _x;
    self.y = _y;

    static set = function(_x, _y) {
        gml_pragma("forceinline");
        self.x = _x;
        self.y = _y;
        return self;
    }
    
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    static copy = function(vec) {
        gml_pragma("forceinline");
        self.x = vec.x;
        self.y = vec.y;
        return self;
    }

    static add = function(vec) {
        gml_pragma("forceinline");
        self.x += vec.x;
        self.y += vec.y;
        return self;
    }

    static sub = function(vec) {
        gml_pragma("forceinline");
        self.x -= vec.x;
        self.y -= vec.y;
        return self;
    }

    static multiply = function(vec) {
        gml_pragma("forceinline");
        self.x *= vec.x;
        self.y *= vec.y;
        return self;
    }

    static scale = function(s) {
        gml_pragma("forceinline");
        self.x *= s;
        self.y *= s;
        return self;
    }

    static dot = function(vec) {
        gml_pragma("forceinline");
        return self.x * vec.x + self.y * vec.y;
    }

    static length = function() {
        return sqrt(self.x * self.x + self.y * self.y);
    }

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

    static equals = function(vec) {
        gml_pragma("forceinline");
        return self.x == vec.x && self.y == vec.y;
    }

    static lerp = function(vec, t) {
        gml_pragma("forceinline");
        self.x += (vec.x - self.x) * t;
        self.y += (vec.y - self.y) * t;
        return self;
    }

    static angleTo = function(vec) {
        gml_pragma("forceinline");
        var dot = self.dot(vec);
        var len1 = self.length();
        var len2 = vec.length();
        var denom = len1 * len2;
        if (denom == 0) return 0;

        var cos_theta = clamp(dot / denom, -1, 1);
        return darccos(cos_theta);
    }

    static distanceTo = function(vec) {
        gml_pragma("forceinline");
        var dx = self.x - vec.x;
        var dy = self.y - vec.y;
        return sqrt(dx * dx + dy * dy);
    }

    static perp = function() {
        gml_pragma("forceinline");
        return new UeVector2(-self.y, self.x);
    }

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
