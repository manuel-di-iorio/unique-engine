/// A 3D ray defined by an origin point and a normalized direction vector.
/// Used for raycasting, intersection tests, and spatial queries.
function UeRay(_origin = undefined, _direction = undefined) constructor {
    /// The origin point of the ray
    self.origin = _origin ? _origin.clone() : new UeVector3();
    /// The normalized direction vector of the ray
    self.direction = _direction ? _direction.clone().normalize() : global.UE_OBJECT3D_DEFAULT_UP.clone().normalize();

    /// Sets the ray's origin and direction based on two points: from -> to
    static setFromPoints = function(from, to) {
        gml_pragma("forceinline");
        self.origin.copy(from);
        self.direction.copy(to).sub(from).normalize();
        return self;
    }

    /// Returns the point at distance t along the ray
    static getPoint = function(t) {
        gml_pragma("forceinline");
        return self.origin.clone().add(self.direction.clone().scale(t));
    }

    /// Returns true if a point is within maxDist from the ray
    static isPointClose = function(point, maxDist) {
        gml_pragma("forceinline");
        return distanceToPoint(point) <= maxDist;
    }

    /// Returns a clone (deep copy) of this ray
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// Copies origin and direction from another ray
    static copy = function(ray) {
        gml_pragma("forceinline");
        self.origin.copy(ray.origin);
        self.direction.copy(ray.direction);
        return self;
    }

    /// Applies a 4x4 transformation matrix to the ray's origin and direction
    static applyMatrix4 = function(matrix4) {
        gml_pragma("forceinline");
        self.origin = matrix4.applyToVector3(self.origin);
        var endPoint = self.origin.clone().add(self.direction);
        endPoint = matrix4.applyToVector3(endPoint);
        self.direction.copy(endPoint.sub(self.origin).normalize());
        return self;
    }

    /// Gets the point at distance t along the ray, writes into target Vector3
    static at = function(t, target) {
        gml_pragma("forceinline");
        target ??= new UeVector3();
        target.copy(self.direction).scale(t).add(self.origin);
        return target;
    }

    /// Gets the closest point on the ray to a given point, stores result in target
    static closestPointToPoint = function(point, target) {
        gml_pragma("forceinline");
        var v = point.clone().sub(self.origin);
        var t = self.direction.dot(v);
        if (t < 0) t = 0;
        return self.at(t, target);
    }

    /// Returns squared distance from the ray to a point (UeVector3)
    static distanceSqToPoint = function(point) {
        gml_pragma("forceinline");
        // Compute the vector from the origin towards the point
        var vx = point.x - self.origin.x;
        var vy = point.y - self.origin.y;
        var vz = point.z - self.origin.z;
        
        // Dot product
        var t = self.direction.x * vx + self.direction.y * vy + self.direction.z * vz;
        if (t < 0) t = 0;
        
        // Compute the projected point
        var projectedX = self.origin.x + self.direction.x * t;
        var projectedY = self.origin.y + self.direction.y * t;
        var projectedZ = self.origin.z + self.direction.z * t;
        
        // Compute the quadratic distance
        var dx = point.x - projectedX;
        var dy = point.y - projectedY;
        var dz = point.z - projectedZ;
        
        return dx * dx + dy * dy + dz * dz;
    }

    /// Returns squared distance between ray and segment defined by v0 and v1.
    /// Optionally outputs closest points on ray and segment.
    static distanceSqToSegment = function(v0, v1, optionalPointOnRay, optionalPointOnSegment) {
        gml_pragma("forceinline");
        var origin = self.origin;
        var dir = self.direction;
    
        // Prepara dummy vectors
        var segCenter = global.UE_DUMMY_VECTOR3_E.copy(v0).add(v1).multiplyScalar(0.5);
        var segDir = global.UE_DUMMY_VECTOR3_F.copy(v1).sub(v0);
        var segLength = segDir.length();
        segDir.multiplyScalar(1 / segLength);
        var segExtent = 0.5 * segLength;
    
        var diff = global.UE_DUMMY_VECTOR3_G.copy(origin).sub(segCenter);
    
        var a01 = -dir.dot(segDir);
        var b0 = diff.dot(dir);
        var b1 = -diff.dot(segDir);
        var c = diff.lengthSq();
    
        var det = 1 - a01 * a01;
        var s0, s1;
    
        if (abs(det) > UE_EPSILON) {
            var invDet = 1 / det;
            s0 = (a01 * b1 - b0) * invDet;
            s1 = (a01 * b0 - b1) * invDet;
    
            // Clamp s1 to segment
            if (s1 < -segExtent) {
                s1 = -segExtent;
            } else if (s1 > segExtent) {
                s1 = segExtent;
            }
    
            // Clamp s0 to ray
            if (s0 < 0) s0 = 0;
    
        } else {
            // Parallel case
            s0 = 0;
            s1 = clamp(-b1, -segExtent, segExtent);
        }
    
        // Closest points
        var closestRayPoint = global.UE_DUMMY_VECTOR3_H.copy(dir).multiplyScalar(s0).add(origin);
        var closestSegPoint = global.UE_DUMMY_VECTOR3_J.copy(segDir).multiplyScalar(s1).add(segCenter);
    
        // Optional output
        if (optionalPointOnRay) optionalPointOnRay.copy(closestRayPoint);
        if (optionalPointOnSegment) optionalPointOnSegment.copy(closestSegPoint);
    
        return closestRayPoint.distanceToSquared(closestSegPoint);
    }


    /// Returns distance from origin to plane along ray direction, or undefined if no intersection
    static distanceToPlane = function(plane) {
        gml_pragma("forceinline");
        var denom = plane.normal.dot(self.direction);
        if (abs(denom) < UE_EPSILON) return undefined;
        var t = -(plane.normal.dot(self.origin) + plane.constant) / denom;
        return (t >= 0) ? t : undefined;
    }

    /// Returns distance from the ray to a point
    static distanceToPoint = function(point) {
        gml_pragma("forceinline");
        return sqrt(distanceSqToPoint(point));
    }

    /// Checks if this ray equals another (origin and direction)
    static equals = function(ray) {
        gml_pragma("forceinline");
        return self.origin.equals(ray.origin) && self.direction.equals(ray.direction);
    }

    /// Returns intersection point with axis-aligned bounding box or undefined if none
    static intersectBox = function(box, target) {
        gml_pragma("forceinline");
        var tmin = 0, tmax = infinity;
    
        for (var i = 0; i < 3; i++) {
            var originComp = self.origin.getComponent(i);
            var dirComp = self.direction.getComponent(i);
    
            if (abs(dirComp) < UE_EPSILON) {
                // Ray is parallel to slab
                if (originComp < box.sizeMin.getComponent(i) || originComp > box.sizeMax.getComponent(i)) {
                    return undefined;
                }
                continue;
            }
    
            var invD = 1 / dirComp;
            var t0 = (box.sizeMin.getComponent(i) - originComp) * invD;
            var t1 = (box.sizeMax.getComponent(i) - originComp) * invD;
    
            if (invD < 0) {
                var tmp = t0; t0 = t1; t1 = tmp;
            }
    
            tmin = max(tmin, t0);
            tmax = min(tmax, t1);
    
            if (tmax < tmin) return undefined;
        }
    
        if (target == undefined) target = new UeVector3();
        // If tmin is infinity (no intersection), return undefined
        if (tmin == infinity) return undefined;
        self.at(tmin, target);
        return target;
    }

    /// Returns intersection point with plane or undefined if none
    static intersectPlane = function(plane, target = new UeVector3()) {
        gml_pragma("forceinline");
        var denom = plane.normal.dot(self.direction);
        if (abs(denom) < UE_EPSILON) return undefined;

        var t = -(plane.normal.dot(self.origin) + plane.constant) / denom;
        if (t < 0) return undefined;

        return self.at(t, target);
    }

    /// Returns intersection point with sphere or undefined if none
    static intersectSphere = function(sphere, target) {
        gml_pragma("forceinline");
        var vx = sphere.center.x - self.origin.x;
        var vy = sphere.center.y - self.origin.y;
        var vz = sphere.center.z - self.origin.z;
        
        var tca = vx * self.direction.x + vy * self.direction.y + vz * self.direction.z;
        var vLenSq = vx * vx + vy * vy + vz * vz;
        var d2 = vLenSq - tca * tca;
        
        var r2 = sphere.radius * sphere.radius;
        if (d2 > r2) return undefined; // Early exit se non c'è intersezione
        
        var thc = sqrt(r2 - d2);
        var t0 = tca - thc;
        
        // Ottimizzazione: controlla prima t0, poi t1 solo se necessario
        if (t0 >= 0) {
            return self.at(t0, target);
        }
        
        var t1 = tca + thc;
        if (t1 < 0) return undefined;
        
        return self.at(t1, target);
    }

    /// Returns intersection point with triangle or undefined if none
    /// backfaceCulling: if true, ignore intersections from back faces
    static intersectTriangle = function(a, b, c, backfaceCulling, target) {
        gml_pragma("forceinline");
        var edge1 = b.clone().sub(a);
        var edge2 = c.clone().sub(a);
        var pvec = self.direction.clone().cross(edge2);
        var det = edge1.dot(pvec);

        if (backfaceCulling && det < 1000000) return undefined;
        if (!backfaceCulling && abs(det) < 1000000) return undefined;

        var invDet = 1 / det;
        var tvec = self.origin.clone().sub(a);
        var u = tvec.dot(pvec) * invDet;
        if (u < 0 || u > 1) return undefined;

        var qvec = tvec.clone().cross(edge1);
        var v = self.direction.dot(qvec) * invDet;
        if (v < 0 || u + v > 1) return undefined;

        var t = edge2.dot(qvec) * invDet;
        if (t < 0) return undefined;

        if (target) self.at(t, target);
        else target = self.at(t, new UeVector3());

        return target;
    }

    /// Returns true if the ray intersects the axis-aligned bounding box
    static intersectsBox = function(box) {
        gml_pragma("forceinline");
        return self.intersectBox(box, new UeVector3()) != undefined;
    }

    /// Returns true if the ray intersects the plane
    static intersectsPlane = function(plane) {
        gml_pragma("forceinline");
        return self.distanceToPlane(plane) != undefined;
    }

    /// Returns true if the ray intersects the sphere
    static intersectsSphere = function(sphere) {
        gml_pragma("forceinline");
        return intersectSphere(sphere, new UeVector3()) != undefined;
    }

    /// Sets the ray direction to look at vector v (world space)
    static lookAt = function(v) {
        gml_pragma("forceinline");
        self.direction.copy(v).sub(self.origin).normalize();
        return self;
    }

    /// Shifts the origin along the direction by distance t
    static recast = function(t) {
        gml_pragma("forceinline");
        self.origin.add(self.direction.clone().scale(t));
        return self;
    }

    /// Sets origin and normalized direction
    static set = function(origin, direction) {
        gml_pragma("forceinline");
        self.origin.copy(origin);
        self.direction.copy(direction).normalize();
        return self;
    }
}
