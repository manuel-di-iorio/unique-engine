/// Represents an axis-aligned 2D bounding box (AABB), defined by min and max corners.
function UeBox2(_min = undefined, _max = undefined) constructor {
    self.sizeMin = _min ?? new UeVector2(infinity, infinity);
    self.sizeMax = _max ?? new UeVector2(-infinity, -infinity);
    
    /// Returns a clone of this box.
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }
    
    /// Sets the box limits using two vectors.
    static set = function(_min, _max) {
        gml_pragma("forceinline");
        self.sizeMin.copy(_min);
        self.sizeMax.copy(_max);
        return self;
    }
    
    /// Empties the box so that it contains no points.
    static makeEmpty = function() {
        gml_pragma("forceinline");
        self.sizeMin.set(+infinity, +infinity);
        self.sizeMax.set(-infinity, -infinity);
        return self;
    }
    
    /// Returns true if the box has no area.
    static isEmpty = function() {
        gml_pragma("forceinline");
        return self.sizeMax.x < self.sizeMin.x || self.sizeMax.y < self.sizeMin.y;
    }
    
    /// Sets the box bounds from an array of Vector2 points or flat array of numbers.
    /// Supports either an array of UeVector2 or a flat array [x0,y0,x1,y1,...].
    static setFromPoints = function(points) {
        gml_pragma("forceinline");
        makeEmpty();
        var n = array_length(points);
        if (n == 0) return self;

        // Check if first element is a Vector (has .x property) or a number
        var isVectorArray = (n > 0 && variable_struct_exists(points[0], "x"));
        
        if (isVectorArray) {
            // Array of Vector2
            for (var i = 0; i < n; i++) {
                var p = points[i];
                self.sizeMin.x = min(self.sizeMin.x, p.x);
                self.sizeMin.y = min(self.sizeMin.y, p.y);
                self.sizeMax.x = max(self.sizeMax.x, p.x);
                self.sizeMax.y = max(self.sizeMax.y, p.y);
            }
        } else {
            // Flat array of numbers [x0,y0,x1,y1,...]
            for (var i = 0; i < n; i += 2) {
                var px = points[i], py = points[i+1];
                self.sizeMin.x = min(self.sizeMin.x, px);
                self.sizeMin.y = min(self.sizeMin.y, py);
                self.sizeMax.x = max(self.sizeMax.x, px);
                self.sizeMax.y = max(self.sizeMax.y, py);
            }
        }
        return self;
    }
    
    /// Sets the box from a flat array of positions (like BufferAttribute).
    /// Supports a flat array of numbers [x0,y0,x1,y1,...] with optional offset.
    static setFromBufferAttribute = function(buffer, offset = 0) {
        gml_pragma("forceinline");
        makeEmpty();
        var n = array_length(buffer);
        if (n == 0 || offset >= n) return self;

        for (var i = offset; i < n; i += 2) {
            if (i + 1 >= n) break;
            var px = buffer[i], py = buffer[i + 1];
            self.sizeMin.x = min(self.sizeMin.x, px);
            self.sizeMin.y = min(self.sizeMin.y, py);
            self.sizeMax.x = max(self.sizeMax.x, px);
            self.sizeMax.y = max(self.sizeMax.y, py);
        }
        return self;
    }
    
    /// Sets the box using a center point and size.
    static setFromCenterAndSize = function(center, size) {
        gml_pragma("forceinline");
        var half = size.clone().scale(0.5);
        self.sizeMin.copy(center).sub(half);
        self.sizeMax.copy(center).add(half);
        return self;
    }
    
    /// Copies the bounds from another box.
    static copy = function(box) {
        gml_pragma("forceinline");
        self.sizeMin.copy(box.sizeMin);
        self.sizeMax.copy(box.sizeMax);
        return self;
    }
    
    /// Expands the box to include a given point.
    /// Point must be a UeVector2.
    static expandByPoint = function(point) {
        gml_pragma("forceinline");
        self.sizeMin.x = min(self.sizeMin.x, point.x);
        self.sizeMin.y = min(self.sizeMin.y, point.y);
        self.sizeMax.x = max(self.sizeMax.x, point.x);
        self.sizeMax.y = max(self.sizeMax.y, point.y);
        return self;
    }
    
    /// Expands the box by a scalar amount in all directions.
    static expandByScalar = function(scalar) {
        gml_pragma("forceinline");
        self.sizeMin.x -= scalar;
        self.sizeMin.y -= scalar;
        self.sizeMax.x += scalar;
        self.sizeMax.y += scalar;
        return self;
    }
    
    /// Expands the box in all directions by the given vector.
    static expandByVector = function(vec) {
        gml_pragma("forceinline");
        self.sizeMin.sub(vec);
        self.sizeMax.add(vec);
        return self;
    }
    
    /// Returns true if the box contains the given point.
    /// Point must be a UeVector2.
    static containsPoint = function(point) {
        gml_pragma("forceinline");
        return (
            point.x >= self.sizeMin.x && point.x <= self.sizeMax.x &&
            point.y >= self.sizeMin.y && point.y <= self.sizeMax.y
        );
    }
    
    /// Returns true if the given box is entirely inside this box.
    static containsBox = function(box) {
        gml_pragma("forceinline");
        return (
            self.sizeMin.x <= box.sizeMin.x && box.sizeMax.x <= self.sizeMax.x &&
            self.sizeMin.y <= box.sizeMin.y && box.sizeMax.y <= self.sizeMax.y
        );
    }
    
    /// Updates this box to be the intersection with another box.
    static intersect = function(box) {
        gml_pragma("forceinline");
        self.sizeMin.x = max(self.sizeMin.x, box.sizeMin.x);
        self.sizeMin.y = max(self.sizeMin.y, box.sizeMin.y);
        self.sizeMax.x = min(self.sizeMax.x, box.sizeMax.x);
        self.sizeMax.y = min(self.sizeMax.y, box.sizeMax.y);
    
        if (isEmpty()) makeEmpty();
        return self;
    }
    
    /// Returns true if this box intersects another.
    static intersectsBox = function(box) {
        gml_pragma("forceinline");
        return !(
            box.sizeMax.x < self.sizeMin.x || box.sizeMin.x > self.sizeMax.x ||
            box.sizeMax.y < self.sizeMin.y || box.sizeMin.y > self.sizeMax.y
        );
    }
    
    /// Merges this box with another, expanding bounds to fit both.
    static union = function(box) {
        gml_pragma("forceinline");
        self.sizeMin.x = min(self.sizeMin.x, box.sizeMin.x);
        self.sizeMin.y = min(self.sizeMin.y, box.sizeMin.y);
        self.sizeMax.x = max(self.sizeMax.x, box.sizeMax.x);
        self.sizeMax.y = max(self.sizeMax.y, box.sizeMax.y);
        return self;
    }
    
    /// Returns the center point of the box.
    static getCenter = function(target = new UeVector2()) {
        gml_pragma("forceinline");
        return target.copy(self.sizeMin).add(self.sizeMax).scale(0.5);
    }
    
    /// Returns the width and height of the box.
    static getSize = function(target = new UeVector2()) {
        gml_pragma("forceinline");
        return target.copy(self.sizeMax).sub(self.sizeMin);
    }
    
    /// Returns the normalized coordinates of a point (0..1 range) relative to box bounds.
    /// Point must be a UeVector2.
    static getParameter = function(point, target = new UeVector2()) {
        gml_pragma("forceinline");
        target.x = (point.x - self.sizeMin.x) / (self.sizeMax.x - self.sizeMin.x);
        target.y = (point.y - self.sizeMin.y) / (self.sizeMax.y - self.sizeMin.y);
        return target;
    }
    
    /// Clamps a point to the box bounds.
    /// Point must be a UeVector2. Returns a UeVector2.
    static clampPoint = function(point, target = new UeVector2()) {
        gml_pragma("forceinline");
        target.x = clamp(point.x, self.sizeMin.x, self.sizeMax.x);
        target.y = clamp(point.y, self.sizeMin.y, self.sizeMax.y);
        return target;
    }
    
    /// Returns the distance from the point to the box (0 if inside).
    /// Point must be a UeVector2.
    static distanceToPoint = function(point) {
        gml_pragma("forceinline");
        var cp = clampPoint(point);
        var dx = point.x - cp.x, dy = point.y - cp.y;
        return sqrt(dx*dx + dy*dy);
    }
    
    /// Translates (moves) the box by an offset.
    static translate = function(offset) {
        gml_pragma("forceinline");
        self.sizeMin.add(offset);
        self.sizeMax.add(offset);
        return self;
    }
    
    /// Returns true if this box is equal to another.
    static equals = function(box) {
        gml_pragma("forceinline");
        return self.sizeMin.equals(box.sizeMin) && self.sizeMax.equals(box.sizeMax);
    }

    /// Converts the box to a JSON representation.
    static toJSON = function() {
        gml_pragma("forceinline");
        return { 
            min: self.sizeMin.toJSON(), 
            max: self.sizeMax.toJSON() 
        };
    }

    /// Loads the box from a JSON representation.
    static fromJSON = function(data) {
        gml_pragma("forceinline");
        self.sizeMin.fromJSON(data.min);
        self.sizeMax.fromJSON(data.max);
        return self;
    }
}
