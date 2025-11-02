/// Represents an axis-aligned 3D bounding box (AABB) defined by min and max corners.
function UeBox3(_min = undefined, _max = undefined) constructor {
    self.sizeMin = _min ?? new UeVector3(infinity, infinity, infinity);
    self.sizeMax = _max ?? new UeVector3(-infinity, -infinity, -infinity);

    /// Sets the min and max corners of the box.
    function set(_min, _max) {
        gml_pragma("forceinline");
        self.sizeMin.copy(_min);
        self.sizeMax.copy(_max);
        return self;
    }

    /// Sets the box bounds from a flat array of coordinates [x0, y0, z0, x1, y1, z1, ...].
    function setFromArray(arr) {
        gml_pragma("forceinline");
        makeEmpty();
        for (var i = 0, n = array_length(arr); i < n; i += 3) {
            var xx = arr[i];
            var yy = arr[i + 1];
            var zz = arr[i + 2];
            expandByPoint(new UeVector3(xx, yy, zz));
        }
        return self;
    }

    /// Sets the box from a center point (UeVector3) and size (UeVector3).
    function setFromCenterAndSize(center, size) {
        gml_pragma("forceinline");
        var halfSize = size.clone().scale(0.5);
        self.sizeMin.copy(center).sub(halfSize);
        self.sizeMax.copy(center).add(halfSize);
        return self;
    }

    /// Sets the box to enclose an array of points (UeVector3).
    function setFromPoints(points) {
        gml_pragma("forceinline");
        makeEmpty();
        for (var i = 0, n = array_length(points); i < n; i++) {
            expandByPoint(points[i]);
        }
        return self;
    }

    /// Sets the box to enclose an object and its children, optionally with precise geometry.
    function setFromObject(object, precise = false) {
        gml_pragma("forceinline");
        makeEmpty(); 
        expandByObject(object, precise);
        return self;
    }

    /// Creates and returns a clone of this box.
    function clone() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// Copies the min and max corners from another box.
    function copy(box) {
        gml_pragma("forceinline");
        self.sizeMin.copy(box.sizeMin);
        self.sizeMax.copy(box.sizeMax);
        return self;
    }

    /// Empties the box (min at +inf, max at -inf).
    function makeEmpty() {
        gml_pragma("forceinline");
        self.sizeMin.set(infinity, infinity, infinity);
        self.sizeMax.set(-infinity, -infinity, -infinity);
        return self;
    }

    /// Returns true if the box is empty (no volume).
    function isEmpty() {
        gml_pragma("forceinline");
        return (
            self.sizeMax.x < self.sizeMin.x ||
            self.sizeMax.y < self.sizeMin.y ||
            self.sizeMax.z < self.sizeMin.z
        );
    }

    /// Expands the box to include a given point.
    function expandByPoint(point) {
        gml_pragma("forceinline");
        self.sizeMin.x = min(self.sizeMin.x, point.x);
        self.sizeMin.y = min(self.sizeMin.y, point.y);
        self.sizeMin.z = min(self.sizeMin.z, point.z);

        self.sizeMax.x = max(self.sizeMax.x, point.x);
        self.sizeMax.y = max(self.sizeMax.y, point.y);
        self.sizeMax.z = max(self.sizeMax.z, point.z);

        return self;
    }

    /// Expands the box by a scalar amount in all directions.
    function expandByScalar(scalar) {
        gml_pragma("forceinline");
        self.sizeMin.subScalar(scalar);
        self.sizeMax.addScalar(scalar);
        return self;
    }

    /// Expands the box by a vector in all directions.
    function expandByVector(vec) {
        gml_pragma("forceinline");
        self.sizeMin.sub(vec);
        self.sizeMax.add(vec);
        return self;
    }

    /// Expands the box to include the bounding box of an object and its children.
    /// If `precise` is true, uses geometry vertices; otherwise uses cached bounding box.
    function expandByObject(object, precise = false) {
        gml_pragma("forceinline");
        var box = undefined;
        var geometry = object[$ "geometry"];

        if (geometry != undefined) {
            if (precise) {
                box = new UeBox3().setFromPoints(geometry.vertices);
            } else {
                box = geometry.boundingBox.clone();
            }

            box.applyMatrix4(object.matrixWorld);
            union(box);
        }

        for (var i = 0, n = array_length(object.children); i < n; i++) {
            expandByObject(object.children[i], precise);
        }

        return self;
    }

    /// Returns true if the box contains the given point.
    function containsPoint(point) {
        gml_pragma("forceinline");
        return (
            point.x >= self.sizeMin.x && point.x <= self.sizeMax.x &&
            point.y >= self.sizeMin.y && point.y <= self.sizeMax.y &&
            point.z >= self.sizeMin.z && point.z <= self.sizeMax.z
        );
    }

    /// Returns true if the given box is fully contained within this box.
    function containsBox(box) {
        gml_pragma("forceinline");
        return (
            self.sizeMin.x <= box.sizeMin.x && box.sizeMax.x <= self.sizeMax.x &&
            self.sizeMin.y <= box.sizeMin.y && box.sizeMax.y <= self.sizeMax.y &&
            self.sizeMin.z <= box.sizeMin.z && box.sizeMax.z <= self.sizeMax.z
        );
    }

    /// Updates this box to the intersection of itself and another box.
    function intersect(box) {
        gml_pragma("forceinline");
        self.sizeMin.x = max(self.sizeMin.x, box.sizeMin.x);
        self.sizeMin.y = max(self.sizeMin.y, box.sizeMin.y);
        self.sizeMin.z = max(self.sizeMin.z, box.sizeMin.z);

        self.sizeMax.x = min(self.sizeMax.x, box.sizeMax.x);
        self.sizeMax.y = min(self.sizeMax.y, box.sizeMax.y);
        self.sizeMax.z = min(self.sizeMax.z, box.sizeMax.z);

        if (isEmpty()) makeEmpty();
        return self;
    }

    /// Returns true if this box intersects another box.
    function intersectsBox(box) {
        gml_pragma("forceinline");
        return !(
            box.sizeMax.x < self.sizeMin.x || box.sizeMin.x > self.sizeMax.x ||
            box.sizeMax.y < self.sizeMin.y || box.sizeMin.y > self.sizeMax.y ||
            box.sizeMax.z < self.sizeMin.z || box.sizeMin.z > self.sizeMax.z
        );
    }

    /// Returns true if this box intersects a plane.
    function intersectsPlane(plane) {
        gml_pragma("forceinline");
        var _min = self.sizeMin;
        var _max = self.sizeMax;
        var normal = plane.normal;

        var p_near = new UeVector3(
            normal.x >= 0 ? _min.x : _max.x,
            normal.y >= 0 ? _min.y : _max.y,
            normal.z >= 0 ? _min.z : _max.z
        );

        var p_far = new UeVector3(
            normal.x >= 0 ? _max.x : _min.x,
            normal.y >= 0 ? _max.y : _min.y,
            normal.z >= 0 ? _max.z : _min.z
        );

        var dist_near = plane.distanceToPoint(p_near);
        var dist_far  = plane.distanceToPoint(p_far);

        return dist_near <= 0 && dist_far >= 0;
    }

    /// Returns the center point of the box.
    function getCenter(target = new UeVector3()) {
        gml_pragma("forceinline");
        return target.copy(self.sizeMin).add(self.sizeMax).scale(0.5);
    }

    /// Returns the size (width, height, depth) of the box.
    function getSize(target = new UeVector3()) {
        gml_pragma("forceinline");
        return target.copy(self.sizeMax).sub(self.sizeMin);
    }

    /// Returns normalized coordinates (0..1) of a point relative to the box bounds.
    function getParameter(point, target = new UeVector3()) {
        gml_pragma("forceinline");
        target.x = (point.x - self.sizeMin.x) / (self.sizeMax.x - self.sizeMin.x);
        target.y = (point.y - self.sizeMin.y) / (self.sizeMax.y - self.sizeMin.y);
        target.z = (point.z - self.sizeMin.z) / (self.sizeMax.z - self.sizeMin.z);
        return target;
    }

    /// Applies a 4x4 transformation matrix to the box and updates its bounds.
    function applyMatrix4(matrix) {
        gml_pragma("forceinline");
        var points = [
            new UeVector3(self.sizeMin.x, self.sizeMin.y, self.sizeMin.z),
            new UeVector3(self.sizeMin.x, self.sizeMin.y, self.sizeMax.z),
            new UeVector3(self.sizeMin.x, self.sizeMax.y, self.sizeMin.z),
            new UeVector3(self.sizeMin.x, self.sizeMax.y, self.sizeMax.z),
            new UeVector3(self.sizeMax.x, self.sizeMin.y, self.sizeMin.z),
            new UeVector3(self.sizeMax.x, self.sizeMin.y, self.sizeMax.z),
            new UeVector3(self.sizeMax.x, self.sizeMax.y, self.sizeMin.z),
            new UeVector3(self.sizeMax.x, self.sizeMax.y, self.sizeMax.z)
        ];

        makeEmpty();
        for (var i = 0, n = array_length(points); i < n; i++) {
            var p = matrix.applyToVector3(points[i]);
            expandByPoint(p);
        }

        return self;
    }

    /// Moves (translates) the box by a given offset vector.
    function translate(offset) {
        gml_pragma("forceinline");
        self.sizeMin.add(offset);
        self.sizeMax.add(offset);
        return self;
    }

    /// Returns true if this box equals another box.
    function equals(box) {
        gml_pragma("forceinline");
        return self.sizeMin.equals(box.sizeMin) && self.sizeMax.equals(box.sizeMax);
    }

    /// Clamps a point to stay within the bounds of the box.
    function clampPoint(point, target = new UeVector3()) {
        gml_pragma("forceinline");
        target.x = clamp(point.x, self.sizeMin.x, self.sizeMax.x);
        target.y = clamp(point.y, self.sizeMin.y, self.sizeMax.y);
        target.z = clamp(point.z, self.sizeMin.z, self.sizeMax.z);
        return target;
    }

    /// Returns the distance from a point to the box (0 if the point is inside).
    function distanceToPoint(point) {
        gml_pragma("forceinline");
        var clamped = clampPoint(point);
        return clamped.distanceTo(point);
    }

    /// Calculates the bounding sphere that encloses the box.
    /// The `target` must have `.center` (UeVector3) and `.radius` (number) properties.
    function getBoundingSphere(target) {
        gml_pragma("forceinline");
        var center = getCenter();
        var radius = center.distanceTo(self.sizeMax);
        target.center.copy(center);
        target.radius = radius;
        return target;
    }

    /// Expands this box to include another box.
    function union(box) {
        gml_pragma("forceinline");
        self.sizeMin.x = min(self.sizeMin.x, box.sizeMin.x);
        self.sizeMin.y = min(self.sizeMin.y, box.sizeMin.y);
        self.sizeMin.z = min(self.sizeMin.z, box.sizeMin.z);

        self.sizeMax.x = max(self.sizeMax.x, box.sizeMax.x);
        self.sizeMax.y = max(self.sizeMax.y, box.sizeMax.y);
        self.sizeMax.z = max(self.sizeMax.z, box.sizeMax.z);

        return self;
    }
}
