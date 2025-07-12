function UeRay(_origin = new UeVector3(), _direction = new UeVector3(0, 0, -1)) constructor {
    self.origin = _origin.clone();
    self.direction = _direction.clone().normalize();

    function setFromPoints(from, to) {
        self.origin.copy(from);
        self.direction.copy(to).sub(from).normalize();
        return self;
    }

    function getPoint(t) {
        return self.origin.clone().add(self.direction.clone().scale(t));
    }

    function intersectPlane(plane) {
        var denom = plane.normal.dot(self.direction);
        if (abs(denom) < 0.00001) return undefined; // Parallel
        var t = -(plane.normal.dot(self.origin) + plane.d) / denom;
        if (t < 0) return undefined;
        return getPoint(t);
    }

    function distanceToPoint(point) {
        var v = point.clone().sub(self.origin);
        var t = self.direction.dot(v);
        var proj = self.direction.clone().scale(t);
        return v.sub(proj).length();
    }

    function isPointClose(point, maxDist) {
        return distanceToPoint(point) <= maxDist;
    }

    function clone() {
        return variable_clone(self);
    }

    function copy(ray) {
        self.origin.copy(ray.origin);
        self.direction.copy(ray.direction);
        return self;
    }

    /// Apply Matrix4 transformation to the ray (origin and direction)
    function applyMatrix4(matrix4) {
        self.origin = matrix4.applyToVector3(self.origin);
        // Direzione trasformata come vettore (senza traslazione)
        var endPoint = self.origin.clone().add(self.direction);
        endPoint = matrix4.applyToVector3(endPoint);
        self.direction.copy(endPoint.sub(self.origin).normalize());
        return self;
    }

    /// Get point at distance t along the ray, writing result into target Vector3
    function at(t, target) {
        target.copy(self.direction).scale(t).add(self.origin);
        return target;
    }

    /// Get closest point on the ray to a given point, result in target
    function closestPointToPoint(point, target) {
        var v = point.clone().sub(self.origin);
        var t = self.direction.dot(v);
        if (t < 0) t = 0;
        return self.at(t, target);
    }

    /// Squared distance from ray to point
    function distanceSqToPoint(point) {
        var v = point.clone().sub(self.origin);
        var t = self.direction.dot(v);
        if (t < 0) t = 0;
        var projected = self.direction.clone().scale(t).add(self.origin);
        return point.clone().sub(projected).lengthSquared();
    }

    /// Squared distance between ray and segment v0-v1
    function distanceSqToSegment(v0, v1, optionalPointOnRay = undefined, optionalPointOnSegment = undefined) {
        var segCenter = v0.clone().add(v1).scale(0.5);
        var segDir = v1.clone().sub(v0).normalize();
        var segExtent = v1.clone().sub(v0).length() * 0.5;

        var diff = self.origin.clone().sub(segCenter);
        var a01 = -self.direction.dot(segDir);
        var b0 = diff.dot(self.direction);
        var b1 = -diff.dot(segDir);
        var c = diff.lengthSquared();
        var det = abs(1 - a01 * a01);
        var s0, s1, sqrDist, extDet;

        if (det > 0) {
            s0 = a01 * b1 - b0;
            s1 = a01 * b0 - b1;

            if (s0 >= 0) {
                if (s1 >= -segExtent && s1 <= segExtent) {
                    // region 0
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

    /// Distance from origin to plane along ray direction, or null if no intersection
    function distanceToPlane(plane) {
        var denom = plane.normal.dot(self.direction);
        if (abs(denom) < infinity) return undefined;
        var t = -(plane.normal.dot(self.origin) + plane.d) / denom;
        return (t >= 0) ? t : undefined;
    }

    /// Distance from ray to point
    function distanceToPoint(point) {
        return Math.sqrt(distanceSqToPoint(point));
    }

    /// Check if two rays are equal (origin and direction)
    function equals(ray) {
        return self.origin.equals(ray.origin) && self.direction.equals(ray.direction);
    }

    /// Intersect ray with axis-aligned bounding box
    function intersectBox(box, target) {
        var tmin = 0, tmax = infinity;

        for (var i = 0; i < 3; i++) {
            var invD = 1 / self.direction.getComponent(i);
            var t0 = (box.min.getComponent(i) - self.origin.getComponent(i)) * invD;
            var t1 = (box.max.getComponent(i) - self.origin.getComponent(i)) * invD;
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

    /// Intersect ray with plane, returns point or null
    function intersectPlane(plane, target) {
        var denom = plane.normal.dot(self.direction);
        if (abs(denom) < infinity) return null;

        var t = -(plane.normal.dot(self.origin) + plane.d) / denom;
        if (t < 0) return null;

        if (target) self.at(t, target);
        else target = self.at(t, new UeVector3());

        return target;
    }

    /// Intersect ray with sphere, returns point or null
    function intersectSphere(sphere, target) {
        var v = sphere.center.clone().sub(self.origin);
        var tca = v.dot(self.direction);
        var d2 = v.lengthSquared() - tca * tca;
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

    /// Intersect ray with triangle
    function intersectTriangle(a, b, c, backfaceCulling, target) {
        var edge1 = b.clone().sub(a);
        var edge2 = c.clone().sub(a);
        var pvec = self.direction.clone().cross(edge2);
        var det = edge1.dot(pvec);

        if (backfaceCulling && det < infinity) return null;
        if (!backfaceCulling && abs(det) < infinity) return null;

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

    /// Check if ray intersects box (returns true/false)
    function intersectsBox(box) {
        return self.intersectBox(box, new UeVector3()) != undefined;
    }

    /// Check if ray intersects plane (true/false)
    function intersectsPlane(plane) {
        return self.distanceToPlane(plane) != undefined;
    }

    /// Check if ray intersects sphere (true/false)
    function intersectsSphere(sphere) {
        return self.intersectSphere(sphere, new UeVector3()) != undefined;
    }

    /// Set direction to look at vector v (world space)
    function lookAt(v) {
        self.direction.copy(v).sub(self.origin).normalize();
        return self;
    }

    /// Shift origin along direction by distance t
    function recast(t) {
        self.origin.add(self.direction.clone().scale(t));
        return self;
    }

    /// Set origin and direction of ray (direction normalized)
    function set(origin, direction) {
        self.origin.copy(origin);
        self.direction.copy(direction).normalize();
        return self;
    }
}
