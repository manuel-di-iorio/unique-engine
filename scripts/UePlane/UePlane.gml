function Plane(_normal = new Vec3(0, 1, 0), _d = 0) constructor {
    self.normal = _normal;
    self.d = _d;

    /// Sets plane from normal and a point on the plane
    function setFromNormalAndPoint(_normal, point) {
        self.normal.copy(_normal).normalize();
        self.d = -self.normal.dot(point);
        return self;
    }

    /// Sets plane from three non-collinear points (counter-clockwise winding)
    function setFromPoints(p1, p2, p3) {
        var u = p2.clone().sub(p1);
        var v = p3.clone().sub(p1);
        self.normal = u.cross(v).normalize();
        self.d = -self.normal.dot(p1);
        return self;
    }

    /// Returns signed distance from point to the plane
    function distanceToPoint(point) {
        return self.normal.dot(point) + self.d;
    }

    /// Projects a point onto the plane
    function projectPoint(point) {
        var dist = distanceToPoint(point);
        return point.clone().sub(self.normal.clone().scale(dist));
    }

    /// Returns true if a point lies on the plane (within a small epsilon)
    function isPointOnPlane(point, epsilon = 0.0001) {
        return abs(distanceToPoint(point)) < epsilon;
    }

    /// Clones the current plane
    function clone() {
        return variable_clone(self);
    }

    /// Copies another plane into this one
    function copy(plane) {
        self.normal.copy(plane.normal);
        self.d = plane.d;
        return self;
    }

    /// Flips the normal and distance (i.e. inverts the plane)
    function flip() {
        self.normal.scale(-1);
        self.d = -self.d;
        return self;
    }
}
