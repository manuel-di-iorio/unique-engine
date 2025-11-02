/// Represents an axis-aligned 2D bounding box (AABB), defined by min and max corners.
function UeBox2(_min = undefined, _max = undefined) constructor {
    self.sizeMin = _min ?? new UeVector2(infinity, infinity);
    self.sizeMax = _max ?? new UeVector2(-infinity, -infinity);
    
    /// Returns a clone of this box.
    function clone() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }
    
    /// Sets the box limits using two vectors.
    function set(_min, _max) {
        gml_pragma("forceinline");
        self.sizeMin.copy(_min);
        self.sizeMax.copy(_max);
        return self;
    }
    
    /// Empties the box so that it contains no points.
    function makeEmpty() {
        gml_pragma("forceinline");
        self.sizeMin.set(+infinity, +infinity);
        self.sizeMax.set(-infinity, -infinity);
        return self;
    }
    
    /// Returns true if the box has no area.
    function isEmpty() {
        gml_pragma("forceinline");
        return self.sizeMax.x < self.sizeMin.x || self.sizeMax.y < self.sizeMin.y;
    }
    
    /// Sets the box bounds from an array of Vector2 points.
    function setFromPoints(points) {
        gml_pragma("forceinline");
        makeEmpty();
        for (var i = 0, n = array_length(points); i < n; i++) {
            expandByPoint(points[i]);
        }
        return self;
    }
    
    /// Sets the box using a center point and size.
    function setFromCenterAndSize(center, size) {
        gml_pragma("forceinline");
        var half = size.clone().scale(0.5);
        self.sizeMin.copy(center).sub(half);
        self.sizeMax.copy(center).add(half);
        return self;
    }
    
    /// Copies the bounds from another box.
    function copy(box) {
        gml_pragma("forceinline");
        self.sizeMin.copy(box.sizeMin);
        self.sizeMax.copy(box.sizeMax);
        return self;
    }
    
    /// Expands the box to include a given point.
    function expandByPoint(point) {
        gml_pragma("forceinline");
        self.sizeMin.x = min(self.sizeMin.x, point.x);
        self.sizeMin.y = min(self.sizeMin.y, point.y);
        self.sizeMax.x = max(self.sizeMax.x, point.x);
        self.sizeMax.y = max(self.sizeMax.y, point.y);
        return self;
    }
    
    /// Expands the box by a scalar amount in all directions.
    function expandByScalar(scalar) {
        gml_pragma("forceinline");
        self.sizeMin.x -= scalar;
        self.sizeMin.y -= scalar;
        self.sizeMax.x += scalar;
        self.sizeMax.y += scalar;
        return self;
    }
    
    /// Expands the box in all directions by the given vector.
    function expandByVector(vec) {
        gml_pragma("forceinline");
        self.sizeMin.sub(vec);
        self.sizeMax.add(vec);
        return self;
    }
    
    /// Returns true if the box contains the given point.
    function containsPoint(point) {
        gml_pragma("forceinline");
        return (
            point.x >= self.sizeMin.x && point.x <= self.sizeMax.x &&
            point.y >= self.sizeMin.y && point.y <= self.sizeMax.y
        );
    }
    
    /// Returns true if the given box is entirely inside this box.
    function containsBox(box) {
        gml_pragma("forceinline");
        return (
            self.sizeMin.x <= box.sizeMin.x && box.sizeMax.x <= self.sizeMax.x &&
            self.sizeMin.y <= box.sizeMin.y && box.sizeMax.y <= self.sizeMax.y
        );
    }
    
    /// Updates this box to be the intersection with another box.
    function intersect(box) {
        gml_pragma("forceinline");
        self.sizeMin.x = max(self.sizeMin.x, box.sizeMin.x);
        self.sizeMin.y = max(self.sizeMin.y, box.sizeMin.y);
        self.sizeMax.x = min(self.sizeMax.x, box.sizeMax.x);
        self.sizeMax.y = min(self.sizeMax.y, box.sizeMax.y);
    
        if (isEmpty()) makeEmpty();
        return self;
    }
    
    /// Returns true if this box intersects another.
    function intersectsBox(box) {
        gml_pragma("forceinline");
        return !(
            box.sizeMax.x < self.sizeMin.x || box.sizeMin.x > self.sizeMax.x ||
            box.sizeMax.y < self.sizeMin.y || box.sizeMin.y > self.sizeMax.y
        );
    }
    
    /// Merges this box with another, expanding bounds to fit both.
    function union(box) {
        gml_pragma("forceinline");
        self.sizeMin.x = min(self.sizeMin.x, box.sizeMin.x);
        self.sizeMin.y = min(self.sizeMin.y, box.sizeMin.y);
        self.sizeMax.x = max(self.sizeMax.x, box.sizeMax.x);
        self.sizeMax.y = max(self.sizeMax.y, box.sizeMax.y);
        return self;
    }
    
    /// Returns the center point of the box.
    function getCenter(target = new UeVector2()) {
        gml_pragma("forceinline");
        return target.copy(self.sizeMin).add(self.sizeMax).scale(0.5);
    }
    
    /// Returns the width and height of the box.
    function getSize(target = new UeVector2()) {
        gml_pragma("forceinline");
        return target.copy(self.sizeMax).sub(self.sizeMin);
    }
    
    /// Returns the normalized coordinates of a point (0..1 range) relative to box bounds.
    function getParameter(point, target = new UeVector2()) {
        gml_pragma("forceinline");
        target.x = (point.x - self.sizeMin.x) / (self.sizeMax.x - self.sizeMin.x);
        target.y = (point.y - self.sizeMin.y) / (self.sizeMax.y - self.sizeMin.y);
        return target;
    }
    
    /// Clamps a point to the box bounds.
    function clampPoint(point, target = new UeVector2()) {
        gml_pragma("forceinline");
        target.x = clamp(point.x, self.sizeMin.x, self.sizeMax.x);
        target.y = clamp(point.y, self.sizeMin.y, self.sizeMax.y);
        return target;
    }
    
    /// Returns the distance from the point to the box (0 if inside).
    function distanceToPoint(point) {
        gml_pragma("forceinline");
        var clamped = clampPoint(point);
        return clamped.distanceTo(point);
    }
    
    /// Translates (moves) the box by an offset.
    function translate(offset) {
        gml_pragma("forceinline");
        self.sizeMin.add(offset);
        self.sizeMax.add(offset);
        return self;
    }
    
    /// Returns true if this box is equal to another.
    function equals(box) {
        gml_pragma("forceinline");
        return self.sizeMin.equals(box.sizeMin) && self.sizeMax.equals(box.sizeMax);
    }
}
