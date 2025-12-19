/// Represents an axis-aligned 3D bounding box (AABB) defined by min and max corners.
function UeBox3(_min = undefined, _max = undefined) constructor {
    self.sizeMin = _min ?? new UeVector3(infinity, infinity, infinity);
    self.sizeMax = _max ?? new UeVector3(-infinity, -infinity, -infinity);

    /// Sets the min and max corners of the box.
    static set = function(_min, _max) {
        gml_pragma("forceinline");
        self.sizeMin.copy(_min);
        self.sizeMax.copy(_max);
        return self;
    }

    /// Sets the box from a center point and size.
    static setFromCenterAndSize = function(center, size) {
        gml_pragma("forceinline");
        var halfSize = size.clone().scale(0.5);
        self.sizeMin.copy(center).sub(halfSize);
        self.sizeMax.copy(center).add(halfSize);
        return self;
    }

    /// Sets the box to enclose an array of points.
    /// Supports a flat array of numbers [x0,y0,z0, ...].
    static setFromPoints = function(points) {
        gml_pragma("forceinline");
        makeEmpty();
        var n = array_length(points);
        if (n == 0) return self;

        for (var i = 0; i < n; i += 3) {
            var px = points[i], py = points[i+1], pz = points[i+2];
            self.sizeMin.x = min(self.sizeMin.x, px);
            self.sizeMin.y = min(self.sizeMin.y, py);
            self.sizeMin.z = min(self.sizeMin.z, pz);
            self.sizeMax.x = max(self.sizeMax.x, px);
            self.sizeMax.y = max(self.sizeMax.y, py);
            self.sizeMax.z = max(self.sizeMax.z, pz);
        }
        return self;
    }

    /// Expands the box to include the bounding box of an object and its children.
    /// If `precise` is true, uses geometry vertices; otherwise uses cached bounding box.
    static expandByObject = function(object, precise = false) {
        gml_pragma("forceinline");
        var geometry = object[$ "geometry"];
        
        if (geometry != undefined) {
            if (precise) {
                if (geometry.position != undefined) {
                    var matrix = object.matrixWorld;
                    var pos = geometry.position;
                    var n = array_length(pos);
                    var tempPoint = new UeVector3();
                    var tempArr = [0, 0, 0];
                    for (var i = 0; i < n; i += 3) {
                        tempPoint.set(pos[i], pos[i+1], pos[i+2]).applyMatrix4(matrix);
                        tempArr[0] = tempPoint.x; tempArr[1] = tempPoint.y; tempArr[2] = tempPoint.z;
                        expandByPoint(tempArr);
                    }
                }
            } else {
                geometry.computeBoundingBox();
                var box = geometry.boundingBox.clone();
                box.applyMatrix4(object.matrixWorld);
                union(box);
            }
        }
        
        // Always expand by children, even if this object has no geometry
        var children = object.children;
        for (var i = 0, l = array_length(children); i < l; i++) {
            expandByObject(children[i], precise);
        }
        
        return self;
    }

    /// Sets the box to enclose an object and its children, optionally with precise geometry.
    static setFromObject = function(object, precise = false) {
        gml_pragma("forceinline");
        makeEmpty(); 
        expandByObject(object, precise);
        return self;
    }

    /// Creates and returns a clone of this box.
    static clone = function() {
        gml_pragma("forceinline");
        return variable_clone(self);
    }

    /// Copies the min and max corners from another box.
    static copy = function(box) {
        gml_pragma("forceinline");
        self.sizeMin.copy(box.sizeMin);
        self.sizeMax.copy(box.sizeMax);
        return self;
    }

    /// Resets the box to an empty state (infinite bounds).
    static makeEmpty = function() {
        gml_pragma("forceinline");
        self.sizeMin.set(infinity, infinity, infinity);
        self.sizeMax.set(-infinity, -infinity, -infinity);
        return self;
    }

    /// Returns true if the box corresponds to an empty volume.
    static isEmpty = function() {
        gml_pragma("forceinline");
        return (self.sizeMax.x < self.sizeMin.x) || (self.sizeMax.y < self.sizeMin.y) || (self.sizeMax.z < self.sizeMin.z);
    }

    /// Returns the center point of the box.
    static getCenter = function(target = new UeVector3()) {
        gml_pragma("forceinline");
        return target.addVectors(self.sizeMin, self.sizeMax).multiplyScalar(0.5);
    }

    /// Returns the size (width, height, depth) of the box.
    static getSize = function(target = new UeVector3()) {
        gml_pragma("forceinline");
        return target.subVectors(self.sizeMax, self.sizeMin);
    }

    /// Expands the box bounds to include the given point.
    /// Point can be an array [x,y,z].
    static expandByPoint = function(point) {
        gml_pragma("forceinline");
        self.sizeMin.x = min(self.sizeMin.x, point[0]);
        self.sizeMin.y = min(self.sizeMin.y, point[1]);
        self.sizeMin.z = min(self.sizeMin.z, point[2]);
        self.sizeMax.x = max(self.sizeMax.x, point[0]);
        self.sizeMax.y = max(self.sizeMax.y, point[1]);
        self.sizeMax.z = max(self.sizeMax.z, point[2]);
        return self;
    }

    /// Expands the box by the given vector, moving both min and max bounds.
    static expandByVector = function(vector) {
        gml_pragma("forceinline");
        self.sizeMin.sub(vector);
        self.sizeMax.add(vector);
        return self;
    }

    /// Expands the box uniformly by a scalar value in all directions.
    static expandByScalar = function(scalar) {
        gml_pragma("forceinline");
        self.sizeMin.addScalar(-scalar);
        self.sizeMax.addScalar(scalar);
        return self;
    }

    /// Returns true if the box contains the given point.
    /// Point can be an array [x,y,z].
    static containsPoint = function(point) {
        gml_pragma("forceinline");
        return point[0] >= self.sizeMin.x && point[0] <= self.sizeMax.x &&
               point[1] >= self.sizeMin.y && point[1] <= self.sizeMax.y &&
               point[2] >= self.sizeMin.z && point[2] <= self.sizeMax.z;
    }

    /// Returns true if the given box is fully contained within this box.
    static containsBox = function(box) {
        gml_pragma("forceinline");
        return self.sizeMin.x <= box.sizeMin.x && box.sizeMax.x <= self.sizeMax.x &&
               self.sizeMin.y <= box.sizeMin.y && box.sizeMax.y <= self.sizeMax.y &&
               self.sizeMin.z <= box.sizeMin.z && box.sizeMax.z <= self.sizeMax.z;
    }

    /// Returns a parameter representing where a point lies within the box (0-1).
    /// Point can be an array [x,y,z].
    static getParameter = function(point, target = new UeVector3()) {
        gml_pragma("forceinline");
        target.set(
            (point[0] - self.sizeMin.x) / (self.sizeMax.x - self.sizeMin.x),
            (point[1] - self.sizeMin.y) / (self.sizeMax.y - self.sizeMin.y),
            (point[2] - self.sizeMin.z) / (self.sizeMax.z - self.sizeMin.z)
        );
        return target;
    }

    /// Returns true if this box intersects another box.
    static intersectsBox = function(box) {
        gml_pragma("forceinline");
        return !(box.sizeMax.x < self.sizeMin.x || box.sizeMin.x > self.sizeMax.x ||
                 box.sizeMax.y < self.sizeMin.y || box.sizeMin.y > self.sizeMax.y ||
                 box.sizeMax.z < self.sizeMin.z || box.sizeMin.z > self.sizeMax.z);
    }

    /// Returns true if this box intersects a sphere.
    static intersectsSphere = function(sphere) {
        gml_pragma("forceinline");
        var closestPoint = clampPoint(sphere.center.toArray());
        var dx = closestPoint[0] - sphere.center.x;
        var dy = closestPoint[1] - sphere.center.y;
        var dz = closestPoint[2] - sphere.center.z;
        return (dx*dx + dy*dy + dz*dz) <= (sphere.radius * sphere.radius);
    }

    /// Returns true if this box intersects a plane.
    static intersectsPlane = function(plane) {
        gml_pragma("forceinline");
        var _min, _max;
        if (plane.normal.x > 0) {
            _min = plane.normal.x * self.sizeMin.x;
            _max = plane.normal.x * self.sizeMax.x;
        } else {
            _min = plane.normal.x * self.sizeMax.x;
            _max = plane.normal.x * self.sizeMin.x;
        }

        if (plane.normal.y > 0) {
            _min += plane.normal.y * self.sizeMin.y;
            _max += plane.normal.y * self.sizeMax.y;
        } else {
            _min += plane.normal.y * self.sizeMax.y;
            _max += plane.normal.y * self.sizeMin.y;
        }

        if (plane.normal.z > 0) {
            _min += plane.normal.z * self.sizeMin.z;
            _max += plane.normal.z * self.sizeMax.z;
        } else {
            _min += plane.normal.z * self.sizeMax.z;
            _max += plane.normal.z * self.sizeMin.z;
        }

        return (_min <= -plane.constant && _max >= -plane.constant);
    }

    /// Clamps a point to the inside of the box.
    /// Point can be an array [x,y,z]. Returns an array [x,y,z].
    static clampPoint = function(point, target = array_create(3)) {
        gml_pragma("forceinline");
        target[0] = clamp(point[0], self.sizeMin.x, self.sizeMax.x);
        target[1] = clamp(point[1], self.sizeMin.y, self.sizeMax.y);
        target[2] = clamp(point[2], self.sizeMin.z, self.sizeMax.z);
        return target;
    }

    /// Returns the distance to a given point (0 if point is inside).
    /// Point can be an array [x,y,z].
    static distanceToPoint = function(point) {
        gml_pragma("forceinline");
        var cp = clampPoint(point);
        var dx = point[0] - cp[0], dy = point[1] - cp[1], dz = point[2] - cp[2];
        return sqrt(dx*dx + dy*dy + dz*dz);
    }

    /// Computes the bounding sphere that encloses this box.
    static getBoundingSphere = function(target = new UeSphere()) {
        gml_pragma("forceinline");
        getCenter(target.center);
        target.radius = getSize().length() * 0.5;
        return target;
    }

    /// Intersects this box with another.
    static intersect = function(box) {
        gml_pragma("forceinline");
        self.sizeMin.maxVec(box.sizeMin);
        self.sizeMax.minVec(box.sizeMax);
        if (isEmpty()) makeEmpty();
        return self;
    }

    /// Expands this box to enclose another box.
    static union = function(box) {
        gml_pragma("forceinline");
        self.sizeMin.minVec(box.sizeMin);
        self.sizeMax.maxVec(box.sizeMax);
        return self;
    }

    /// Applies a 4x4 matrix transformation to the box (recomputing it).
    static applyMatrix4 = function(matrix) {
        gml_pragma("forceinline");
        if (isEmpty()) return self;

        static points = array_create(24);
        var minX = self.sizeMin.x, minY = self.sizeMin.y, minZ = self.sizeMin.z;
        var maxX = self.sizeMax.x, maxY = self.sizeMax.y, maxZ = self.sizeMax.z;
        
        var e = matrix.data;
        var transform = function(_points, _idx, _x, _y, _z, _m) {
            var w = _m[3]*_x + _m[7]*_y + _m[11]*_z + _m[15];
            w = (w != 0) ? 1 / w : 1;
            _points[_idx]   = (_m[0]*_x + _m[4]*_y + _m[8]*_z + _m[12]) * w;
            _points[_idx+1] = (_m[1]*_x + _m[5]*_y + _m[9]*_z + _m[13]) * w;
            _points[_idx+2] = (_m[2]*_x + _m[6]*_y + _m[10]*_z + _m[14]) * w;
        };

        transform(points, 0,  minX, minY, minZ, e);
        transform(points, 3,  minX, minY, maxZ, e);
        transform(points, 6,  minX, maxY, minZ, e);
        transform(points, 9,  minX, maxY, maxZ, e);
        transform(points, 12, maxX, minY, minZ, e);
        transform(points, 15, maxX, minY, maxZ, e);
        transform(points, 18, maxX, maxY, minZ, e);
        transform(points, 21, maxX, maxY, maxZ, e);

        return setFromPoints(points);
    }

    /// Translates the box by a given offset vector.
    static translate = function(offset) {
        gml_pragma("forceinline");
        self.sizeMin.add(offset);
        self.sizeMax.add(offset);
        return self;
    }

    /// Returns true if this box is equal to another.
    static equals = function(box) {
        gml_pragma("forceinline");
        return box.sizeMin.equals(self.sizeMin) && box.sizeMax.equals(self.sizeMax);
    }

    /// Converts the box to a JSON representation.
    static toJSON = function() {
        gml_pragma("forceinline");
        return { 
            min: self.sizeMin.toJSON(), 
            max: self.sizeMax.toJSON() 
        };
    }

    /// Loads the box from a JSON representation.
    static fromJSON = function(data) {
        gml_pragma("forceinline");
        self.sizeMin.fromJSON(data.min);
        self.sizeMax.fromJSON(data.max);
        return self;
    }
}
