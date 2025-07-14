function UeBox3(_min = new UeVector3(infinity, infinity, infinity), _max = new UeVector3(-infinity, -infinity, -infinity)) constructor {
    self.sizeMin = _min;
    self.sizeMax = _max;

    function set(_min, _max) {
        self.sizeMin.copy(_min);
        self.sizeMax.copy(_max);
        return self;
    }

    function setFromArray(arr) {
        makeEmpty();
        for (var i = 0, n = array_length(arr); i < n; i += 3) {
            var xx = arr[i];
            var yy = arr[i + 1];
            var zz = arr[i + 2];
            expandByPoint(new UeVector3(xx, yy, zz));
        }
        return self;
    }

    function setFromCenterAndSize(center, size) {
        var halfSize = size.clone().scale(0.5);
        self.sizeMin.copy(center).sub(halfSize);
        self.sizeMax.copy(center).add(halfSize);
        return self;
    }

    function setFromPoints(points) {
        makeEmpty();
        for (var i = 0, n = array_length(points); i < n; i++) {
            expandByPoint(points[i]);
        }
        return self;
    }

    function setFromObject(object, precise = false) {
        makeEmpty(); 
        expandByObject(object, precise);
        return self;
    }

    function clone() {
        return variable_clone(self);
    }

    function copy(box) {
        self.sizeMin.copy(box.sizeMin);
        self.sizeMax.copy(box.sizeMax);
        return self;
    }

    function makeEmpty() {
        self.sizeMin.set(infinity, infinity, infinity);
        self.sizeMax.set(-infinity, -infinity, -infinity);
        return self;
    }

    function isEmpty() {
        return (
            self.sizeMax.x < self.sizeMin.x ||
            self.sizeMax.y < self.sizeMin.y ||
            self.sizeMax.z < self.sizeMin.z
        );
    }

    function expandByPoint(point) {
        self.sizeMin.x = min(self.sizeMin.x, point.x);
        self.sizeMin.y = min(self.sizeMin.y, point.y);
        self.sizeMin.z = min(self.sizeMin.z, point.z);

        self.sizeMax.x = max(self.sizeMax.x, point.x);
        self.sizeMax.y = max(self.sizeMax.y, point.y);
        self.sizeMax.z = max(self.sizeMax.z, point.z);

        return self;
    }

    function expandByScalar(scalar) {
        self.sizeMin.x -= scalar;
        self.sizeMin.y -= scalar;
        self.sizeMin.z -= scalar;

        self.sizeMax.x += scalar;
        self.sizeMax.y += scalar;
        self.sizeMax.z += scalar;

        return self;
    }

    function expandByVector(vec) {
        self.sizeMin.sub(vec);
        self.sizeMax.add(vec);
        return self;
    }

    function expandByObject(object, precise = false) {
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

    function containsPoint(point) {
        return (
            point.x >= self.sizeMin.x && point.x <= self.sizeMax.x &&
            point.y >= self.sizeMin.y && point.y <= self.sizeMax.y &&
            point.z >= self.sizeMin.z && point.z <= self.sizeMax.z
        );
    }

    function containsBox(box) {
        return (
            self.sizeMin.x <= box.sizeMin.x && box.sizeMax.x <= self.sizeMax.x &&
            self.sizeMin.y <= box.sizeMin.y && box.sizeMax.y <= self.sizeMax.y &&
            self.sizeMin.z <= box.sizeMin.z && box.sizeMax.z <= self.sizeMax.z
        );
    }

    function intersect(box) {
        self.sizeMin.x = max(self.sizeMin.x, box.sizeMin.x);
        self.sizeMin.y = max(self.sizeMin.y, box.sizeMin.y);
        self.sizeMin.z = max(self.sizeMin.z, box.sizeMin.z);

        self.sizeMax.x = min(self.sizeMax.x, box.sizeMax.x);
        self.sizeMax.y = min(self.sizeMax.y, box.sizeMax.y);
        self.sizeMax.z = min(self.sizeMax.z, box.sizeMax.z);

        if (isEmpty()) makeEmpty();
        return self;
    }

    function intersectsBox(box) {
        return !(
            box.sizeMax.x < self.sizeMin.x || box.sizeMin.x > self.sizeMax.x ||
            box.sizeMax.y < self.sizeMin.y || box.sizeMin.y > self.sizeMax.y ||
            box.sizeMax.z < self.sizeMin.z || box.sizeMin.z > self.sizeMax.z
        );
    }

    function intersectsPlane(plane) {
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

    function getCenter(target = new UeVector3()) {
        return target.copy(self.sizeMin).add(self.sizeMax).scale(0.5);
    }

    function getSize(target = new UeVector3()) {
        return target.copy(self.sizeMax).sub(self.sizeMin);
    }

    function getParameter(point, target = new UeVector3()) {
        target.x = (point.x - self.sizeMin.x) / (self.sizeMax.x - self.sizeMin.x);
        target.y = (point.y - self.sizeMin.y) / (self.sizeMax.y - self.sizeMin.y);
        target.z = (point.z - self.sizeMin.z) / (self.sizeMax.z - self.sizeMin.z);
        return target;
    }

    function applyMatrix4(matrix) {
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

    function translate(offset) {
        self.sizeMin.add(offset);
        self.sizeMax.add(offset);
        return self;
    }

    function equals(box) {
        return self.sizeMin.equals(box.sizeMin) && self.sizeMax.equals(box.sizeMax);
    }

    function clampPoint(point, target = new UeVector3()) {
        target.x = clamp(point.x, self.sizeMin.x, self.sizeMax.x);
        target.y = clamp(point.y, self.sizeMin.y, self.sizeMax.y);
        target.z = clamp(point.z, self.sizeMin.z, self.sizeMax.z);
        return target;
    }

    function distanceToPoint(point) {
        var clamped = clampPoint(point);
        return clamped.distanceTo(point);
    }

    function getBoundingSphere(target) {
        var center = getCenter();
        var radius = center.distanceTo(self.sizeMax);
        target.center.copy(center);
        target.radius = radius;
        return target;
    }

    function union(box) {
        self.sizeMin.x = min(self.sizeMin.x, box.sizeMin.x);
        self.sizeMin.y = min(self.sizeMin.y, box.sizeMin.y);
        self.sizeMin.z = min(self.sizeMin.z, box.sizeMin.z);

        self.sizeMax.x = max(self.sizeMax.x, box.sizeMax.x);
        self.sizeMax.y = max(self.sizeMax.y, box.sizeMax.y);
        self.sizeMax.z = max(self.sizeMax.z, box.sizeMax.z);

        return self;
    }
}
