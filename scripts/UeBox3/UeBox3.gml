/// Rappresenta un box 3D allineato agli assi (AABB), con limiti min e max in 3D.
function UeBox3(_min = new UeVector3(infinity, infinity, infinity), _max = new UeVector3(-infinity, -infinity, -infinity)) constructor {
    self.min_ = _min;
    self.max_ = _max;

    function set(_min, _max) {
        self.min_.copy(_min);
        self.max_.copy(_max);
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
        self.min_.copy(center).sub(halfSize);
        self.max_.copy(center).add(halfSize);
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
        self.min_.copy(box.min_);
        self.max_.copy(box.max_);
        return self;
    }

    function makeEmpty() {
        self.min_.set(+infinity, +infinity, +infinity);
        self.max_.set(-infinity, -infinity, -infinity);
        return self;
    }

    function isEmpty() {
        return (self.max_.x < self.min_.x) || (self.max_.y < self.min_.y) || (self.max_.z < self.min_.z);
    }

    function expandByPoint(point) {
        self.min_.x = min(self.min_.x, point.x);
        self.min_.y = min(self.min_.y, point.y);
        self.min_.z = min(self.min_.z, point.z);

        self.max_.x = max(self.max_.x, point.x);
        self.max_.y = max(self.max_.y, point.y);
        self.max_.z = max(self.max_.z, point.z);

        return self;
    }

    function expandByScalar(scalar) {
        self.min_.x -= scalar;
        self.min_.y -= scalar;
        self.min_.z -= scalar;

        self.max_.x += scalar;
        self.max_.y += scalar;
        self.max_.z += scalar;

        return self;
    }

    function expandByVector(vec) {
        self.min_.sub(vec);
        self.max_.add(vec);
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
            point.x >= self.min_.x && point.x <= self.max_.x &&
            point.y >= self.min_.y && point.y <= self.max_.y &&
            point.z >= self.min_.z && point.z <= self.max_.z
        );
    }

    function containsBox(box) {
        return (
            self.min_.x <= box.min_.x && box.max_.x <= self.max_.x &&
            self.min_.y <= box.min_.y && box.max_.y <= self.max_.y &&
            self.min_.z <= box.min_.z && box.max_.z <= self.max_.z
        );
    }

    function intersect(box) {
        self.min_.x = max(self.min_.x, box.min_.x);
        self.min_.y = max(self.min_.y, box.min_.y);
        self.min_.z = max(self.min_.z, box.min_.z);

        self.max_.x = min(self.max_.x, box.max_.x);
        self.max_.y = min(self.max_.y, box.max_.y);
        self.max_.z = min(self.max_.z, box.max_.z);

        if (isEmpty()) makeEmpty();
        return self;
    }

    function intersectsBox(box) {
        return !(
            box.max_.x < self.min_.x || box.min_.x > self.max_.x ||
            box.max_.y < self.min_.y || box.min_.y > self.max_.y ||
            box.max_.z < self.min_.z || box.min_.z > self.max_.z
        );
    }

    function intersectsPlane(plane) {
        var min_ = self.min_;
        var max_ = self.max_;
        var normal = plane.normal;

        var p_near = new UeVector3(
            normal.x >= 0 ? min_.x : max_.x,
            normal.y >= 0 ? min_.y : max_.y,
            normal.z >= 0 ? min_.z : max_.z
        );

        var p_far = new UeVector3(
            normal.x >= 0 ? max_.x : min_.x,
            normal.y >= 0 ? max_.y : min_.y,
            normal.z >= 0 ? max_.z : min_.z
        );

        var dist_near = plane.distanceToPoint(p_near);
        var dist_far  = plane.distanceToPoint(p_far);

        return dist_near <= 0 && dist_far >= 0;
    }

    function getCenter(target = new UeVector3()) {
        return target.copy(self.min_).add(self.max_).scale(0.5);
    }

    function getSize(target = new UeVector3()) {
        return target.copy(self.max_).sub(self.min_);
    }

    function getParameter(point, target = new UeVector3()) {
        target.x = (point.x - self.min_.x) / (self.max_.x - self.min_.x);
        target.y = (point.y - self.min_.y) / (self.max_.y - self.min_.y);
        target.z = (point.z - self.min_.z) / (self.max_.z - self.min_.z);
        return target;
    }

    function applyMatrix4(matrix) {
        var points = [
            new UeVector3(self.min_.x, self.min_.y, self.min_.z),
            new UeVector3(self.min_.x, self.min_.y, self.max_.z),
            new UeVector3(self.min_.x, self.max_.y, self.min_.z),
            new UeVector3(self.min_.x, self.max_.y, self.max_.z),
            new UeVector3(self.max_.x, self.min_.y, self.min_.z),
            new UeVector3(self.max_.x, self.min_.y, self.max_.z),
            new UeVector3(self.max_.x, self.max_.y, self.min_.z),
            new UeVector3(self.max_.x, self.max_.y, self.max_.z)
        ];

        makeEmpty();
        for (var i = 0, n = array_length(points); i < n; i++) {
            var p = matrix.applyToVector3(points[i]);
            expandByPoint(p);
        }

        return self;
    }

    function translate(offset) {
        self.min_.add(offset);
        self.max_.add(offset);
        return self;
    }

    function equals(box) {
        return self.min_.equals(box.min_) && self.max_.equals(box.max_);
    }

    function clampPoint(point, target = new UeVector3()) {
        target.x = clamp(point.x, self.min_.x, self.max_.x);
        target.y = clamp(point.y, self.min_.y, self.max_.y);
        target.z = clamp(point.z, self.min_.z, self.max_.z);
        return target;
    }

    function distanceToPoint(point) {
        var clamped = clampPoint(point);
        return clamped.distanceTo(point);
    }

    function getBoundingSphere(target) {
        var center = getCenter();
        var radius = center.distanceTo(self.max_);
        target.center.copy(center);
        target.radius = radius;
        return target;
    }

    function union(box) {
        self.min_.x = min(self.min_.x, box.min_.x);
        self.min_.y = min(self.min_.y, box.min_.y);
        self.min_.z = min(self.min_.z, box.min_.z);

        self.max_.x = max(self.max_.x, box.max_.x);
        self.max_.y = max(self.max_.y, box.max_.y);
        self.max_.z = max(self.max_.z, box.max_.z);

        return self;
    }
}
