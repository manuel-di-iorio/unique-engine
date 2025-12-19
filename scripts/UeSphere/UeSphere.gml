/// Represents a bounding sphere defined by a center point and a radius.
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

    /// Sets the sphere from an array of points and optional center.
    /// Supports a flat array of numbers [x0,y0,z0, ...].
    static setFromPoints = function(points, optionalCenter = undefined) {
        gml_pragma("forceinline");
        var n = array_length(points);
        if (n == 0) return self;

        if (optionalCenter != undefined) {
            self.center.copy(optionalCenter);
        } else {
            var box = new UeBox3().setFromPoints(points);
            box.getCenter(self.center);
        }

        self.radius = 0;
        for (var i = 0; i < n; i += 3) {
            var px = points[i], py = points[i+1], pz = points[i+2];
            var dx = px - self.center.x, dy = py - self.center.y, dz = pz - self.center.z;
            var distSq = dx*dx + dy*dy + dz*dz;
            self.radius = max(self.radius, sqrt(distSq));
        }

        return self;
    }

    /// Returns a deep clone of the sphere.
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// Copies the properties from another sphere.
    static copy = function(sphere) {
        gml_pragma("forceinline");
        self.center.copy(sphere.center);
        self.radius = sphere.radius;
        return self;
    }

    /// Returns true if the sphere is empty (radius < 0).
    static isEmpty = function() {
        gml_pragma("forceinline");
        return self.radius < 0;
    }

    /// Resets the sphere to an empty state.
    static makeEmpty = function() {
        gml_pragma("forceinline");
        self.center.set(0, 0, 0);
        self.radius = -1;
        return self;
    }

    /// Expands the sphere to include the given point.
    /// Point can be an array [x,y,z].
    static expandByPoint = function(point) {
        gml_pragma("forceinline");
        var dx = point[0] - self.center.x, dy = point[1] - self.center.y, dz = point[2] - self.center.z;
        self.radius = max(self.radius, sqrt(dx*dx + dy*dy + dz*dz));
        return self;
    }

    /// Checks if the sphere contains a point.
    /// Point can be an array [x,y,z].
    static containsPoint = function(point) {
        gml_pragma("forceinline");
        var dx = point[0] - self.center.x, dy = point[1] - self.center.y, dz = point[2] - self.center.z;
        return (dx*dx + dy*dy + dz*dz) <= (self.radius * self.radius);
    }

    /// Returns the distance from the sphere boundary to a point.
    /// Point can be an array [x,y,z].
    static distanceToPoint = function(point) {
        gml_pragma("forceinline");
        var dx = point[0] - self.center.x, dy = point[1] - self.center.y, dz = point[2] - self.center.z;
        return sqrt(dx*dx + dy*dy + dz*dz) - self.radius;
    }

    /// Checks for intersection with another sphere.
    static intersectsSphere = function(sphere) {
        gml_pragma("forceinline");
        var radiusSum = self.radius + sphere.radius;
        return (self.center.distanceToSquared(sphere.center) <= (radiusSum * radiusSum));
    }

    /// Checks for intersection with a box.
    static intersectsBox = function(box) {
        gml_pragma("forceinline");
        return box.intersectsSphere(self);
    }

    /// Checks for intersection with a plane.
    static intersectsPlane = function(plane) {
        gml_pragma("forceinline");
        return (abs(plane.distanceToPoint(self.center)) <= self.radius);
    }

    /// Clamps a point to the boundary of the sphere.
    /// Point can be an array [x,y,z]. Returns an array [x,y,z].
    static clampPoint = function(point, target = array_create(3)) {
        gml_pragma("forceinline");
        var dx = point[0] - self.center.x, dy = point[1] - self.center.y, dz = point[2] - self.center.z;
        var d2 = dx*dx + dy*dy + dz*dz;
        if (d2 > (self.radius * self.radius)) {
            var d = sqrt(d2);
            var f = self.radius / d;
            target[0] = self.center.x + dx * f;
            target[1] = self.center.y + dy * f;
            target[2] = self.center.z + dz * f;
        } else {
            target[0] = point[0]; target[1] = point[1]; target[2] = point[2];
        }
        return target;
    }

    /// Returns the bounding box of the sphere.
    static getBoundingBox = function(target = new UeBox3()) {
        gml_pragma("forceinline");
        if (isEmpty()) {
            target.makeEmpty();
            return target;
        }
        target.set(self.center, self.center);
        target.expandByScalar(self.radius);
        return target;
    }

    /// Translates the sphere by an offset vector.
    static translate = function(offset) {
        gml_pragma("forceinline");
        self.center.add(offset);
        return self;
    }

    /// Returns true if this sphere is equal to another.
    static equals = function(sphere) {
        gml_pragma("forceinline");
        return (sphere.center.equals(self.center) && (sphere.radius == self.radius));
    }

    /// Applies a 4x4 matrix transformation to the sphere.
    static applyMatrix4 = function(matrix) {
        gml_pragma("forceinline");
        self.center.applyMatrix4(matrix);
        self.radius = self.radius * matrix.getMaxScaleOnAxis();
        return self;
    }

    /// Converts the sphere to a JSON representation.
    static toJSON = function() {
        gml_pragma("forceinline");
        return { 
            center: self.center.toJSON(), 
            radius: self.radius 
        };
    }

    /// Loads the sphere from a JSON representation.
    static fromJSON = function(data) {
        gml_pragma("forceinline");
        self.center.fromJSON(data.center);
        self.radius = data.radius;
        return self;
    }
}
