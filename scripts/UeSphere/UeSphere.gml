/// A bounding sphere defined by a center and a radius.
function UeSphere(center = undefined, radius = -1) constructor {
    self.isSphere = true;
    self.center = center ?? UE_VECTOR3_ZERO;
    self.radius = radius;

    /// Sets the center and radius of the sphere.
    function set(center, radius) {
        gml_pragma("forceinline");
        self.center.copy(center);
        self.radius = radius;
        return self;
    }

    /// Copies values from another sphere.
    function copy(sphere) {
        gml_pragma("forceinline");
        self.center.copy(sphere.center);
        self.radius = sphere.radius;
        return self;
    }

    /// Returns a clone of this sphere.
    function clone() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// Checks if the sphere is empty (radius < 0).
    function isEmpty() {
        gml_pragma("forceinline");
        return self.radius < 0;
    }

    /// Makes the sphere empty.
    function makeEmpty() {
        gml_pragma("forceinline");
        self.center.set(0, 0, 0);
        self.radius = -1;
        return self;
    }

    /// Checks if the sphere contains a given point.
    function containsPoint(point) {
        gml_pragma("forceinline");
        return self.center.distanceToSquared(point) <= self.radius * self.radius;
    }

    /// Returns the distance from the point to the sphere surface.
    function distanceToPoint(point) {
        gml_pragma("forceinline");
        return self.center.distanceTo(point) - self.radius;
    }

    /// Clamps a point inside the sphere boundary.
    function clampPoint(point, target = new UeVector3()) {
        gml_pragma("forceinline");
        var d = self.center.distanceTo(point);
        if (d > self.radius) {
            target.copy(point).sub(self.center).normalize();
            target.scale(self.radius).add(self.center);
        } else {
            target.copy(point);
        }
        return target;
    }

    /// Applies a 4x4 matrix transformation to the sphere.
    function applyMatrix4(matrix) {
        gml_pragma("forceinline");
        self.center = matrix.applyToVector3(self.center);
        var scale = matrix.getMaxScaleOnAxis();
        self.radius *= scale;
        return self;
    }

    /// Expands the sphere to include a point.
    function expandByPoint(point) {
        gml_pragma("forceinline");
        if (self.isEmpty()) {
            self.center.copy(point);
            self.radius = 0;
            return self;
        }

        var dir = point.clone().sub(self.center);
        var dist = dir.length();

        if (dist > self.radius) {
            var newRadius = (self.radius + dist) * 0.5;
            var offset = dir.normalize().scale(newRadius - self.radius);
            self.center.add(offset);
            self.radius = newRadius;
        }

        return self;
    }

    /// Sets the sphere from an array of points and optional center.
    function setFromPoints(points, optionalCenter = undefined) {
        gml_pragma("forceinline");
        if (optionalCenter != undefined) {
            self.center.copy(optionalCenter);
        } else {
            var box = new UeBox3().setFromPoints(points);
            box.getCenter(self.center);
        }

        self.radius = 0;
        for (var i = 0, n = array_length(points); i < n; i++) {
            self.radius = max(self.radius, self.center.distanceTo(points[i]));
        }

        return self;
    }

    /// Translates the sphere by an offset vector.
    function translate(offset) {
        gml_pragma("forceinline");
        self.center.add(offset);
        return self;
    }

    /// Checks equality with another sphere.
    function equals(sphere) {
        gml_pragma("forceinline");
        return self.center.equals(sphere.center) && self.radius == sphere.radius;
    }

    /// Returns the minimal bounding box containing this sphere.
    function getBoundingBox(target = new UeBox3()) {
        gml_pragma("forceinline");
        target.setFromCenterAndSize(
            self.center,
            new UeVector3(1, 1, 1).scale(self.radius * 2)
        );
        return target;
    }

    /// Checks if this sphere intersects a given box.
    function intersectsBox(box) {
        gml_pragma("forceinline");
        return box.distanceToPoint(self.center) <= self.radius;
    }

    /// Checks if this sphere intersects a given plane.
    function intersectsPlane(plane) {
        gml_pragma("forceinline");
        return abs(plane.distanceToPoint(self.center)) <= self.radius;
    }

    /// Checks if this sphere intersects another sphere.
    function intersectsSphere(sphere) {
        gml_pragma("forceinline");
        var rSum = self.radius + sphere.radius;
        return self.center.distanceToSquared(sphere.center) <= rSum * rSum;
    }

    /// Expands this sphere to include another sphere.
    function union(sphere) {
        gml_pragma("forceinline");
        if (self.isEmpty()) return copy(sphere);
        if (sphere.isEmpty) return self;

        var d = self.center.distanceTo(sphere.center);

        if (d + sphere.radius <= self.radius) return self;
        if (d + self.radius <= sphere.radius) return copy(sphere);

        var newRadius = (self.radius + d + sphere.radius) * 0.5;
        var dir = sphere.center.clone().sub(self.center).normalize();
        self.center.add(dir.scale(newRadius - self.radius));
        self.radius = newRadius;

        return self;
    }
}
