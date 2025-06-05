function Ray(_origin = new Vec3(), _direction = new Vec3(0, 0, -1)) constructor {
    self.origin = _origin;
    self.direction = _direction.normalize();

    /// Set ray from two points: from -> to
    function setFromPoints(from, to) {
        self.origin.copy(from);
        self.direction.copy(to).sub(from).normalize();
        return self;
    }

    /// Get point at distance t along the ray
    function getPoint(t) {
        return self.origin.clone().add(self.direction.clone().scale(t));
    }

    /// Intersect this ray with a plane; returns point or undefined
    function intersectPlane(plane) {
        var denom = plane.normal.dot(self.direction);
        if (abs(denom) < 0.00001) return undefined; // Ray is parallel to plane

        var t = -(plane.normal.dot(self.origin) + plane.d) / denom;
        if (t < 0) return undefined; // Intersection behind ray origin

        return getPoint(t);
    }

    /// Distance from a point to this ray
    function distanceToPoint(point) {
        var v = point.clone().sub(self.origin);
        var t = self.direction.dot(v);
        var proj = self.direction.clone().scale(t);
        return v.sub(proj).length();
    }

    /// Returns true if the point is within a max distance from the ray
    function isPointClose(point, maxDist) {
        return distanceToPoint(point) <= maxDist;
    }

    /// Clones the ray
    function clone() {
        return new Ray(self.origin, self.direction);
    }

    /// Copies from another ray
    function copy(ray) {
        self.origin.copy(ray.origin);
        self.direction.copy(ray.direction);
        return self;
    }
}
