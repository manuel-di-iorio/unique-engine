function UePlane(_normal = undefined, _constant = 0) constructor {
    self.normal = _normal ?? global.UE_OBJECT3D_DEFAULT_UP.clone();
    self.constant = _constant;
    
    /// Read-only flag to check if a given object is of type Plane
    self.isPlane = true;
    
    /// Sets plane from normal and a point on the plane
    function setFromNormalAndPoint(_normal, point) {
        gml_pragma("forceinline");
        self.normal.copy(_normal).normalize();
        self.constant = -self.normal.dot(point);
        return self;
    }
    
    /// Sets plane from three non-collinear points (counter-clockwise winding)
    function setFromPoints(p1, p2, p3) {
        gml_pragma("forceinline");
        var u = p2.clone().sub(p1);
        var v = p3.clone().sub(p1);
        self.normal = u.cross(v).normalize();
        self.constant = -self.normal.dot(p1);
        return self;
    }
    
    /// Returns signed distance from point to the plane
    function distanceToPoint(point) {
        gml_pragma("forceinline");
        return self.normal.dot(point) + self.constant;
    }
    
    /// Projects a point onto the plane
    function projectPoint(point) {
        gml_pragma("forceinline");
        var dist = distanceToPoint(point);
        return point.clone().sub(self.normal.clone().scale(dist));
    }
    
    /// Returns true if a point lies on the plane (within a small epsilon)
    function isPointOnPlane(point, epsilon = UE_EPSILON) {
        gml_pragma("forceinline");
        return abs(distanceToPoint(point)) < epsilon;
    }
    
    /// Clones the current plane
    function clone() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }
    
    /// Copies another plane into this one
    function copy(plane) {
        gml_pragma("forceinline");
        self.normal.copy(plane.normal);
        self.constant = plane.constant;
        return self;
    }
    
    /// Flips the normal and distance (i.e. inverts the plane)
    function flip() {
        gml_pragma("forceinline");
        self.normal.scale(-1);
        self.constant = -self.constant;
        return self;
    }
    
    /// Apply a Matrix4 to the plane. The matrix must be an affine, homogeneous transform
    function applyMatrix4(matrix, optionalNormalMatrix = undefined) {
        gml_pragma("forceinline");
        var normalMatrix = optionalNormalMatrix ?? new UeMatrix3().getNormalMatrix(matrix);
        
        var referencePoint = coplanarPoint();
        referencePoint.applyMatrix4(matrix);
        
        var normal = self.normal.clone().applyMatrix3(normalMatrix);
        setFromNormalAndPoint(normal, referencePoint);
        
        return self;
    }
    
    /// Returns a Vector3 coplanar to the plane, by calculating the projection of the normal vector at the origin onto the plane
    function coplanarPoint() {
        gml_pragma("forceinline");
        return self.normal.clone().scale(-self.constant);
    }
    
    /// Returns the signed distance from the sphere to the plane
    function distanceToSphere(sphere) {
        gml_pragma("forceinline");
        return distanceToPoint(sphere.center) - sphere.radius;
    }
    
    /// Checks to see if two planes are equal (their normal and constant properties match)
    function equals(plane) {
        gml_pragma("forceinline");
        return plane.normal.equals(self.normal) && (abs(plane.constant - self.constant) < 0.0001);
    }
    
    /// Returns the intersection point of the passed line and the plane. Returns undefined if the line does not intersect
    function intersectLine(line) {
        gml_pragma("forceinline");
        var dir = line.delta();
        var denominator = self.normal.dot(dir);
        
        if (abs(denominator) < UE_EPSILON) {
            // Line is parallel to plane
            if (distanceToPoint(line.start) == 0) {
                // Line is coplanar with plane, return start point
                return line.start.clone();
            } else {
                // Line is parallel but not coplanar
                return undefined;
            }
        }
        
        var t = -(self.normal.dot(line.start) + self.constant) / denominator;
        
        if (t < 0 || t > 1) {
            // Intersection point is outside the line segment
            return undefined;
        }
        
        return line.start.clone().add(dir.scale(t));
    }
    
    /// Determines whether or not this plane intersects box
    function intersectsBox(box) {
        gml_pragma("forceinline");
        // Get the positive and negative vertices of the box relative to the plane normal
        var _min = box.min;
        var _max = box.max;
        
        var positive = new UeVector3(
            self.normal.x > 0 ? _max.x : _min.x,
            self.normal.y > 0 ? _max.y : _min.y,
            self.normal.z > 0 ? _max.z : _min.z
        );
        
        var negative = new UeVector3(
            self.normal.x > 0 ? _min.x : _max.x,
            self.normal.y > 0 ? _min.y : _max.y,
            self.normal.z > 0 ? _min.z : _max.z
        );
        
        var distPositive = distanceToPoint(positive);
        var distNegative = distanceToPoint(negative);
        
        // If signs are different, box intersects plane
        return (distPositive * distNegative) <= 0;
    }
    
    /// Tests whether a line segment intersects with (passes through) the plane
    /// @todo Needs to implement the Line3 math class first.
    //function intersectsLine(line) {
        //var startDistance = distanceToPoint(line._start);
        //var endDistance = distanceToPoint(line._end);
        //
        //// If start and end are on opposite sides, line intersects plane
        //return (startDistance * endDistance) <= 0;
    //}
    
    /// Determines whether or not this plane intersects sphere
    function intersectsSphere(sphere) {
        gml_pragma("forceinline");
        return abs(distanceToPoint(sphere.center)) <= sphere.radius;
    }
    
    /// Negates both the normal vector and the constant
    function negate() {
        gml_pragma("forceinline");
        self.normal.scale(-1);
        self.constant = -self.constant;
        return self;
    }
    
    /// Normalizes the normal vector, and adjusts the constant value accordingly
    function normalize() {
        gml_pragma("forceinline");
        var normalLength = self.normal.length();
        self.normal.normalize();
        self.constant = self.constant / normalLength;
        return self;
    }
    
    /// Sets this plane's normal and constant properties by copying the values from the given normal
    function set(_normal, constant) {
        gml_pragma("forceinline");
        self.normal.copy(_normal);
        self.constant = constant;
        return self;
    }
    
    /// Set the individual components that define the plane
    function setComponents(x, y, z, w) {
        gml_pragma("forceinline");
        self.normal.set(x, y, z);
        self.constant = w;
        return self;
    }
    
    /// Sets the plane's properties as defined by a normal and an arbitrary coplanar point
    function setFromNormalAndCoplanarPoint(_normal, point) {
        gml_pragma("forceinline");
        return setFromNormalAndPoint(_normal, point);
    }
    
    /// Alias for setFromPoints - Defines the plane based on the 3 provided points
    function setFromCoplanarPoints(a, b, c) {
        gml_pragma("forceinline");
        return setFromPoints(a, b, c);
    }
    
    /// Translates the plane by the distance defined by the offset vector
    function translate(offset) {
        gml_pragma("forceinline");
        self.constant = self.constant - offset.dot(self.normal);
        return self;
    }
}