/// A 3D ray defined by an origin point and a normalized direction vector.
/// Used for raycasting, intersection tests, and spatial queries.
function UeRay(_origin = new UeVector3(), _direction = new UeVector3(0, 0, -1)) constructor {
    /// The origin point of the ray
    self.origin = _origin.clone();
    /// The normalized direction vector of the ray
    self.direction = _direction.clone().normalize();

    /// Sets the ray's origin and direction based on two points: from -> to
    function setFromPoints(from, to) {
        self.origin.copy(from);
        self.direction.copy(to).sub(from).normalize();
        return self;
    }

    /// Returns the point at distance t along the ray
    function getPoint(t) {
        return self.origin.clone().add(self.direction.clone().scale(t));
    }

    /// Returns intersection point with a plane or undefined if no intersection
    function intersectPlane(plane) {
        var denom = plane.normal.dot(self.direction);
        if (abs(denom) < 0.00001) return undefined; // Parallel, no intersection
        var t = -(plane.normal.dot(self.origin) + plane.d) / denom;
        if (t < 0) return undefined; // Intersection behind origin
        return getPoint(t);
    }

    /// Returns the shortest distance from the ray to a given point
    function distanceToPoint(point) {
        var v = point.clone().sub(self.origin);
        var t = self.direction.dot(v);
        var proj = self.direction.clone().scale(t);
        return v.sub(proj).length();
    }

    /// Returns true if a point is within maxDist from the ray
    function isPointClose(point, maxDist) {
        return distanceToPoint(point) <= maxDist;
    }

    /// Returns a clone (deep copy) of this ray
    function clone() {
        return variable_clone(self);
    }

    /// Copies origin and direction from another ray
    function copy(ray) {
        self.origin.copy(ray.origin);
        self.direction.copy(ray.direction);
        return self;
    }

    /// Applies a 4x4 transformation matrix to the ray's origin and direction
    function applyMatrix4(matrix4) {
        self.origin = matrix4.applyToVector3(self.origin);
        var endPoint = self.origin.clone().add(self.direction);
        endPoint = matrix4.applyToVector3(endPoint);
        self.direction.copy(endPoint.sub(self.origin).normalize());
        return self;
    }

    /// Gets the point at distance t along the ray, writes into target Vector3
    function at(t, target) {
        target.copy(self.direction).scale(t).add(self.origin);
        return target;
    }

    /// Gets the closest point on the ray to a given point, stores result in target
    function closestPointToPoint(point, target) {
        var v = point.clone().sub(self.origin);
        var t = self.direction.dot(v);
        if (t < 0) t = 0;
        return self.at(t, target);
    }

    /// Returns squared distance from the ray to a point (UeVector3)
    function distanceSqToPoint(point) {
        var v = point.clone().sub(self.origin);
        var t = self.direction.dot(v);
        if (t < 0) t = 0;
        var projected = self.direction.clone().scale(t).add(self.origin);
        return point.clone().sub(projected).lengthSq();
    }

    /// Returns squared distance between ray and segment defined by v0 and v1.
    /// Optionally outputs closest points on ray and segment.
    function distanceSqToSegment(v0, v1, optionalPointOnRay = undefined, optionalPointOnSegment = undefined) {
        var segCenter = v0.clone().add(v1).scale(0.5);
        var segDir = v1.clone().sub(v0).normalize();
        var segExtent = v1.clone().sub(v0).length() * 0.5;

        var diff = self.origin.clone().sub(segCenter);
        var a01 = -self.direction.dot(segDir);
        var b0 = diff.dot(self.direction);
        var b1 = -diff.dot(segDir);
        var c = diff.lengthSq();
        var det = abs(1 - a01 * a01);
        var s0, s1, sqrDist;

        if (det > 0) {
            s0 = a01 * b1 - b0;
            s1 = a01 * b0 - b1;

            if (s0 >= 0) {
                if (s1 >= -segExtent && s1 <= segExtent) {
                    var invDet = 1 / det;
                    s0 *= invDet;
                    s1 *= invDet;
                    sqrDist = s0 * (s0 + a01 * s1 + 2 * b0) + s1 * (a01 * s0 + s1 + 2 * b1) + c;
                } else if (s1 < -segExtent) {
                    s1 = -segExtent;
                    s0 = max(0, -(a01 * s1 + b0));
                    sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
                } else {
                    s1 = segExtent;
                    s0 = max(0, -(a01 * s1 + b0));
                    sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
                }
            } else {
                if (s1 <= -segExtent) {
                    s0 = max(0, -b0);
                    s1 = -segExtent;
                    sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
                } else if (s1 <= segExtent) {
                    s0 = 0;
                    sqrDist = s1 * (s1 + 2 * b1) + c;
                } else {
                    s0 = max(0, - (a01 * segExtent + b0));
                    s1 = segExtent;
                    sqrDist = -s0 * s0 + s1 * (s1 + 2 * b1) + c;
                }
            }
        } else {
            s0 = max(0, -b0);
            s1 = (s1 < -segExtent) ? -segExtent : segExtent;
            sqrDist = s0 * (s0 + 2 * b0) + s1 * (s1 + 2 * b1) + c;
        }

        if (optionalPointOnRay) optionalPointOnRay.copy(self.at(s0, new UeVector3()));
        if (optionalPointOnSegment) optionalPointOnSegment.copy(segDir.clone().scale(s1).add(segCenter));

        return sqrDist;
    }

    /// Returns distance from origin to plane along ray direction, or undefined if no intersection
    function distanceToPlane(plane) {
        var denom = plane.normal.dot(self.direction);
        if (abs(denom) < 1000000) return undefined;
        var t = -(plane.normal.dot(self.origin) + plane.d) / denom;
        return (t >= 0) ? t : undefined;
    }

    /// Returns distance from the ray to a point
    function distanceToPoint(point) {
        return sqrt(distanceSqToPoint(point));
    }

    /// Checks if this ray equals another (origin and direction)
    function equals(ray) {
        return self.origin.equals(ray.origin) && self.direction.equals(ray.direction);
    }

    /// Returns intersection point with axis-aligned bounding box or undefined if none
    function intersectBox(box, target) {
        var tmin = 0, tmax = infinity;
        
        for (var i = 0; i < 3; i++) {
            var invD = 1 / self.direction.getComponent(i);
            var t0 = (box.sizeMin.getComponent(i) - self.origin.getComponent(i)) * invD;
            var t1 = (box.sizeMax.getComponent(i) - self.origin.getComponent(i)) * invD;
            if (invD < 0) {
                var tmp = t0; t0 = t1; t1 = tmp;
            }
            tmin = max(tmin, t0);
            tmax = min(tmax, t1);
            if (tmax < tmin) return undefined;
        }

        if (target) self.at(tmin, target);
        else target = self.at(tmin, new UeVector3());

        return target;
    }

    /// Returns intersection point with plane or null if none
    function intersectPlane(plane, target) {
        var denom = plane.normal.dot(self.direction);
        if (abs(denom) < 1000000) return null;

        var t = -(plane.normal.dot(self.origin) + plane.d) / denom;
        if (t < 0) return null;

        if (target) self.at(t, target);
        else target = self.at(t, new UeVector3());

        return target;
    }

    /// Returns intersection point with sphere or null if none
    function intersectSphere(sphere, target) {
        var v = sphere.center.clone().sub(self.origin);
        var tca = v.dot(self.direction);
        var d2 = v.lengthSq() - tca * tca;
        var r2 = sphere.radius * sphere.radius;

        if (d2 > r2) return null;

        var thc = sqrt(r2 - d2);
        var t0 = tca - thc;
        var t1 = tca + thc;

        if (t0 < 0 && t1 < 0) return null;

        var t = (t0 < 0) ? t1 : t0;

        if (target) self.at(t, target);
        else target = self.at(t, new UeVector3());

        return target;
    }

    /// Returns intersection point with triangle or null if none
    /// backfaceCulling: if true, ignore intersections from back faces
    function intersectTriangle(a, b, c, backfaceCulling, target) {
        var edge1 = b.clone().sub(a);
        var edge2 = c.clone().sub(a);
        var pvec = self.direction.clone().cross(edge2);
        var det = edge1.dot(pvec);

        if (backfaceCulling && det < 1000000) return null;
        if (!backfaceCulling && abs(det) < 1000000) return null;

        var invDet = 1 / det;
        var tvec = self.origin.clone().sub(a);
        var u = tvec.dot(pvec) * invDet;
        if (u < 0 || u > 1) return null;

        var qvec = tvec.clone().cross(edge1);
        var v = self.direction.dot(qvec) * invDet;
        if (v < 0 || u + v > 1) return null;

        var t = edge2.dot(qvec) * invDet;
        if (t < 0) return null;

        if (target) self.at(t, target);
        else target = self.at(t, new UeVector3());

        return target;
    }

    /// Returns true if the ray intersects the axis-aligned bounding box
    function intersectsBox(box) {
        return self.intersectBox(box, new UeVector3()) != undefined;
    }

    /// Returns true if the ray intersects the plane
    function intersectsPlane(plane) {
        return self.distanceToPlane(plane) != undefined;
    }

    /// Returns true if the ray intersects the sphere
    function intersectsSphere(sphere) {
        return self.intersectSphere(sphere, new UeVector3()) != undefined;
    }

    /// Sets the ray direction to look at vector v (world space)
    function lookAt(v) {
        self.direction.copy(v).sub(self.origin).normalize();
        return self;
    }

    /// Shifts the origin along the direction by distance t
    function recast(t) {
        self.origin.add(self.direction.clone().scale(t));
        return self;
    }

    /// Sets origin and normalized direction
    function set(origin, direction) {
        self.origin.copy(origin);
        self.direction.copy(direction).normalize();
        return self;
    }
}
