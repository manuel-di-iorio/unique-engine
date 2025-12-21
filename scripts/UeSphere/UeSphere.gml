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
    /// Supports an array of UeVector3
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
        
        // Array of Vector3
        for (var i = 0; i < n; i++) {
            var p = points[i];
            var dx = p.x - self.center.x, dy = p.y - self.center.y, dz = p.z - self.center.z;
            var distSq = dx*dx + dy*dy + dz*dz;
            self.radius = max(self.radius, sqrt(distSq));
        }

        return self;
    }

    /// Sets the sphere from a flat array of positions (like BufferAttribute).
    /// Supports a flat array of numbers [x0,y0,z0,x1,y1,z1, ...] with optional offset.
    static setFromBufferAttribute = function(buffer, offset = 0) {
        gml_pragma("forceinline");
        var n = array_length(buffer);
        if (n == 0 || offset >= n) return self;

        // First pass: compute bounding box to get center
        var box = new UeBox3().setFromBufferAttribute(buffer, offset);
        box.getCenter(self.center);

        // Second pass: compute radius
        self.radius = 0;
        for (var i = offset; i < n; i += 3) {
            if (i + 2 >= n) break;
            var px = buffer[i], py = buffer[i + 1], pz = buffer[i + 2];
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
    /// Point must be a UeVector3.
    static expandByPoint = function(point) {
        gml_pragma("forceinline");
        if (isEmpty()) {
            self.center.copy(point);
            self.radius = 0;
        } else {
            var dx = point.x - self.center.x, dy = point.y - self.center.y, dz = point.z - self.center.z;
            self.radius = max(self.radius, sqrt(dx*dx + dy*dy + dz*dz));
        }
        return self;
    }

    /// Checks if the sphere contains a point.
    /// Point must be a UeVector3.
    static containsPoint = function(point) {
        gml_pragma("forceinline");
        var dx = point.x - self.center.x, dy = point.y - self.center.y, dz = point.z - self.center.z;
        return (dx*dx + dy*dy + dz*dz) <= (self.radius * self.radius);
    }

    /// Returns the distance from the sphere boundary to a point.
    /// Point must be a UeVector3.
    static distanceToPoint = function(point) {
        gml_pragma("forceinline");
        var dx = point.x - self.center.x, dy = point.y - self.center.y, dz = point.z - self.center.z;
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
    /// Point must be a UeVector3. Returns a UeVector3.
    static clampPoint = function(point, target = new UeVector3()) {
        gml_pragma("forceinline");
        var dx = point.x - self.center.x, dy = point.y - self.center.y, dz = point.z - self.center.z;
        var d2 = dx*dx + dy*dy + dz*dz;
        if (d2 > (self.radius * self.radius)) {
            var d = sqrt(d2);
            var f = self.radius / d;
            target.x = self.center.x + dx * f;
            target.y = self.center.y + dy * f;
            target.z = self.center.z + dz * f;
        } else {
            target.copy(point);
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

    /// Expands this sphere to include another sphere.
    static union = function(sphere) {
        gml_pragma("forceinline");
        // If this sphere is empty, copy the other sphere
        if (isEmpty()) {
            self.center.copy(sphere.center);
            self.radius = sphere.radius;
            return self;
        }
        
        // If the other sphere is empty, do nothing
        if (sphere.isEmpty()) {
            return self;
        }
        
        // Calculate distance between centers
        var dist = self.center.distanceTo(sphere.center);
        
        // If one sphere completely contains the other, use the larger one
        if (dist + sphere.radius <= self.radius) {
            // This sphere already contains the other, do nothing
            return self;
        }
        if (dist + self.radius <= sphere.radius) {
            // The other sphere contains this one, copy it
            self.center.copy(sphere.center);
            self.radius = sphere.radius;
            return self;
        }
        
        // Otherwise, create a new sphere that contains both
        // The new center is on the line between the two centers
        // The new radius is (distance + r1 + r2) / 2
        var newRadius = (dist + self.radius + sphere.radius) * 0.5;
        var t = (dist + self.radius - sphere.radius) / (2 * dist);
        
        // Interpolate between centers
        var dir = new UeVector3().subVectors(sphere.center, self.center);
        self.center.addScaledVector(dir, t);
        self.radius = newRadius;
        
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
