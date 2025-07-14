/// Represents an axis-aligned 2D bounding box (AABB), defined by min and max corners.
function UeBox2(_min = new UeVector2(infinity, infinity), _max = new UeVector2(-infinity, -infinity)) constructor {
    self.min = _min;
    self.max = _max;
    
    /// Returns a clone of this box.
    function clone() {
        return variable_clone(self);
    }
    
    /// Sets the box limits using two vectors.
    function set(_min, _max) {
        self.min.copy(_min);
        self.max.copy(_max);
        return self;
    }
    
    /// Empties the box so that it contains no points.
    function makeEmpty() {
        self.min.set(+infinity, +infinity);
        self.max.set(-infinity, -infinity);
        return self;
    }
    
    /// Returns true if the box has no area.
    function isEmpty() {
        return self.max.x < self.min.x || self.max.y < self.min.y;
    }
    
    /// Sets the box bounds from an array of Vector2 points.
    function setFromPoints(points) {
        makeEmpty();
        for (var i = 0, n = array_length(points); i < n; i++) {
            expandByPoint(points[i]);
        }
        return self;
    }
    
    /// Sets the box using a center point and size.
    function setFromCenterAndSize(center, size) {
        var half = size.clone().scale(0.5);
        self.min.copy(center).sub(half);
        self.max.copy(center).add(half);
        return self;
    }
    
    /// Copies the bounds from another box.
    function copy(box) {
        self.min.copy(box.min);
        self.max.copy(box.max);
        return self;
    }
    
    /// Expands the box to include a given point.
    function expandByPoint(point) {
        self.min.x = min(self.min.x, point.x);
        self.min.y = min(self.min.y, point.y);
        self.max.x = max(self.max.x, point.x);
        self.max.y = max(self.max.y, point.y);
        return self;
    }
    
    /// Expands the box by a scalar amount in all directions.
    function expandByScalar(scalar) {
        self.min.x -= scalar;
        self.min.y -= scalar;
        self.max.x += scalar;
        self.max.y += scalar;
        return self;
    }
    
    /// Expands the box in all directions by the given vector.
    function expandByVector(vec) {
        self.min.sub(vec);
        self.max.add(vec);
        return self;
    }
    
    /// Returns true if the box contains the given point.
    function containsPoint(point) {
        return (
            point.x >= self.min.x && point.x <= self.max.x &&
            point.y >= self.min.y && point.y <= self.max.y
        );
    }
    
    /// Returns true if the given box is entirely inside this box.
    function containsBox(box) {
        return (
            self.min.x <= box.min.x && box.max.x <= self.max.x &&
            self.min.y <= box.min.y && box.max.y <= self.max.y
        );
    }
    
    /// Updates this box to be the intersection with another box.
    function intersect(box) {
        self.min.x = max(self.min.x, box.min.x);
        self.min.y = max(self.min.y, box.min.y);
        self.max.x = min(self.max.x, box.max.x);
        self.max.y = min(self.max.y, box.max.y);
    
        if (isEmpty()) makeEmpty();
        return self;
    }
    
    /// Returns true if this box intersects another.
    function intersectsBox(box) {
        return !(
            box.max.x < self.min.x || box.min.x > self.max.x ||
            box.max.y < self.min.y || box.min.y > self.max.y
        );
    }
    
    /// Merges this box with another, expanding bounds to fit both.
    function union(box) {
        self.min.x = min(self.min.x, box.min.x);
        self.min.y = min(self.min.y, box.min.y);
        self.max.x = max(self.max.x, box.max.x);
        self.max.y = max(self.max.y, box.max.y);
        return self;
    }
    
    /// Returns the center point of the box.
    function getCenter(target = new UeVector2()) {
        return target.copy(self.min).add(self.max).scale(0.5);
    }
    
    /// Returns the width and height of the box.
    function getSize(target = new UeVector2()) {
        return target.copy(self.max).sub(self.min);
    }
    
    /// Returns the normalized coordinates of a point (0..1 range) relative to box bounds.
    function getParameter(point, target = new UeVector2()) {
        target.x = (point.x - self.min.x) / (self.max.x - self.min.x);
        target.y = (point.y - self.min.y) / (self.max.y - self.min.y);
        return target;
    }
    
    /// Clamps a point to the box bounds.
    function clampPoint(point, target = new UeVector2()) {
        target.x = clamp(point.x, self.min.x, self.max.x);
        target.y = clamp(point.y, self.min.y, self.max.y);
        return target;
    }
    
    /// Returns the distance from the point to the box (0 if inside).
    function distanceToPoint(point) {
        var clamped = clampPoint(point);
        return clamped.distanceTo(point);
    }
    
    /// Translates (moves) the box by an offset.
    function translate(offset) {
        self.min.add(offset);
        self.max.add(offset);
        return self;
    }
    
    /// Returns true if this box is equal to another.
    function equals(box) {
        return self.min.equals(box.min) && self.max.equals(box.max);
    }
}
