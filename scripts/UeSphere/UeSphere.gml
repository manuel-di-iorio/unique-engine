/// A bounding sphere defined by a center and a radius.
function UeSphere(center = undefined, radius = -1) constructor {
    self.isSphere = true;
    self.center = center ?? UE_VECTOR3_ZERO;
    self.radius = radius;

    /// Sets the center and radius of the sphere.
    static set = function(center, radius) {
        gml_pragma("forceinline");
        self.center.copy(center);
        self.radius = radius;
        return self;
    }

    /// Copies values from another sphere.
    static copy = function(sphere) {
        gml_pragma("forceinline");
        self.center.copy(sphere.center);
        self.radius = sphere.radius;
        return self;
    }

    /// Returns a clone of this sphere.
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// Checks if the sphere is empty (radius < 0).
    static isEmpty = function() {
        gml_pragma("forceinline");
        return self.radius < 0;
    }

    /// Makes the sphere empty.
    static makeEmpty = function() {
        gml_pragma("forceinline");
        self.center.set(0, 0, 0);
        self.radius = -1;
        return self;
    }

    /// Checks if the sphere contains a given point.
    static containsPoint = function(point) {
        gml_pragma("forceinline");
        return self.center.distanceToSquared(point) <= self.radius * self.radius;
    }

    /// Returns the distance from the point to the sphere surface.
    static distanceToPoint = function(point) {
        gml_pragma("forceinline");
        return self.center.distanceTo(point) - self.radius;
    }

    /// Clamps a point inside the sphere boundary.
    static clampPoint = function(point, target = new UeVector3()) {
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
    static applyMatrix4 = function(matrix) {
        gml_pragma("forceinline");
        self.center = matrix.applyToVector3(self.center);
        var scale = matrix.getMaxScaleOnAxis();
        self.radius *= scale;
        return self;
    }

    /// Expands the sphere to include a point.
    static expandByPoint = function(point) {
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
    static setFromPoints = function(points, optionalCenter = undefined) {
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
    static translate = function(offset) {
        gml_pragma("forceinline");
        self.center.add(offset);
        return self;
    }

    /// Checks equality with another sphere.
    static equals = function(sphere) {
        gml_pragma("forceinline");
        return self.center.equals(sphere.center) && self.radius == sphere.radius;
    }

    /// Returns the minimal bounding box containing this sphere.
    static getBoundingBox = function(target = new UeBox3()) {
        gml_pragma("forceinline");
        target.setFromCenterAndSize(
            self.center,
            new UeVector3(1, 1, 1).scale(self.radius * 2)
        );
        return target;
    }

    /// Checks if this sphere intersects a given box.
    static intersectsBox = function(box) {
        gml_pragma("forceinline");
        return box.distanceToPoint(self.center) <= self.radius;
    }

    /// Checks if this sphere intersects a given plane.
    static intersectsPlane = function(plane) {
        gml_pragma("forceinline");
        return abs(plane.distanceToPoint(self.center)) <= self.radius;
    }

    /// Checks if this sphere intersects another sphere.
    static intersectsSphere = function(sphere) {
        gml_pragma("forceinline");
        var rSum = self.radius + sphere.radius;
        return self.center.distanceToSquared(sphere.center) <= rSum * rSum;
    }

    /// Expands this sphere to include another sphere.
    static union = function(sphere) {
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
    static toJSON = function() {
        gml_pragma("forceinline");
        return {
            center: { x: center.x, y: center.y, z: center.z },
            radius
        };
    }

    static fromJSON = function(data) {
        gml_pragma("forceinline");
        center.set(data.center.x, data.center.y, data.center.z);
        radius = data.radius;
        return self;
    }
}
