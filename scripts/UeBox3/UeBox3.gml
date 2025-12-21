/// Represents an axis-aligned 3D bounding box (AABB) defined by min and max corners.
function UeBox3(_min = undefined, _max = undefined) constructor {
  self.sizeMin = _min ?? new UeVector3(infinity, infinity, infinity);
  self.sizeMax = _max ?? new UeVector3(-infinity, -infinity, -infinity);

    /// Sets the min and max corners of the box.
    static set = function (_min, _max) {
    gml_pragma("forceinline");
    self.sizeMin.copy(_min);
    self.sizeMax.copy(_max);
    return self;
  }

    /// Sets the box from a center point and size.
    static setFromCenterAndSize = function (center, size) {
    gml_pragma("forceinline");
    var halfSize = size.clone().scale(0.5);
    self.sizeMin.copy(center).sub(halfSize);
    self.sizeMax.copy(center).add(halfSize);
    return self;
  }

    /// Sets the box to enclose an array of points.
    /// Supports an array of UeVector3
    static setFromPoints = function (points) {
    gml_pragma("forceinline");
    makeEmpty();
    var n = array_length(points);

    for (var i = 0; i < n; i++) {
      var p = points[i];
      self.sizeMin.x = min(self.sizeMin.x, p.x);
      self.sizeMin.y = min(self.sizeMin.y, p.y);
      self.sizeMin.z = min(self.sizeMin.z, p.z);
      self.sizeMax.x = max(self.sizeMax.x, p.x);
      self.sizeMax.y = max(self.sizeMax.y, p.y);
      self.sizeMax.z = max(self.sizeMax.z, p.z);
    }

    return self;
  }

    /// Sets the box from a flat array of positions (like BufferAttribute).
    /// Supports a flat array of numbers [x0,y0,z0,x1,y1,z1, ...] with optional offset.
    static setFromBufferAttribute = function (buffer, offset = 0) {
    gml_pragma("forceinline");
    makeEmpty();
    var n = array_length(buffer);
    if (n == 0 || offset >= n) return self;

    for (var i = offset; i < n; i += 3) {
      if (i + 2 >= n) break;
      var px = buffer[i], py = buffer[i + 1], pz = buffer[i + 2];
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
    static expandByObject = function (object, precise = false) {
    gml_pragma("forceinline");
    var geometry = object[$ "geometry"];

    if (geometry != undefined) {
      if (precise) {
        if (geometry.position != undefined) {
          var matrix = object.matrixWorld;
          var pos = geometry.position;
          var n = array_length(pos);
          var tempPoint = global.UE_DUMMY_VECTOR3;
          for (var i = 0; i < n; i += 3) {
            tempPoint.set(pos[i], pos[i + 1], pos[i + 2]).applyMatrix4(matrix);
            expandByPoint(tempPoint);
          }
        }
      } else {
        //geometry.computeBoundingBox();
        if (geometry[$ "boundingBox"] != undefined) {
          var box = geometry.boundingBox.clone();
          box.applyMatrix4(object.matrixWorld);
          union(box);
        }
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
    static setFromObject = function (object, precise = false) {
    gml_pragma("forceinline");
    makeEmpty();
    expandByObject(object, precise);
    return self;
  }

    /// Creates and returns a clone of this box.
    static clone = function () {
    gml_pragma("forceinline");
    return variable_clone(self);
  }

    /// Copies the min and max corners from another box.
    static copy = function (box) {
    gml_pragma("forceinline");
    self.sizeMin.copy(box.sizeMin);
    self.sizeMax.copy(box.sizeMax);
    return self;
  }

    /// Resets the box to an empty state (infinite bounds).
    static makeEmpty = function () {
    gml_pragma("forceinline");
    self.sizeMin.set(infinity, infinity, infinity);
    self.sizeMax.set(-infinity, -infinity, -infinity);
    return self;
  }

    /// Returns true if the box corresponds to an empty volume.
    static isEmpty = function () {
    gml_pragma("forceinline");
    return (self.sizeMax.x < self.sizeMin.x) || (self.sizeMax.y < self.sizeMin.y) || (self.sizeMax.z < self.sizeMin.z);
  }

    /// Returns the center point of the box.
    static getCenter = function (target = new UeVector3()) {
    gml_pragma("forceinline");
    return target.addVectors(self.sizeMin, self.sizeMax).multiplyScalar(0.5);
  }

    /// Returns the size (width, height, depth) of the box.
    static getSize = function (target = new UeVector3()) {
    gml_pragma("forceinline");
    return target.subVectors(self.sizeMax, self.sizeMin);
  }

    /// Expands the box bounds to include the given point.
    /// Point must be a UeVector3.
    static expandByPoint = function (point) {
    gml_pragma("forceinline");
    self.sizeMin.x = min(self.sizeMin.x, point.x);
    self.sizeMin.y = min(self.sizeMin.y, point.y);
    self.sizeMin.z = min(self.sizeMin.z, point.z);
    self.sizeMax.x = max(self.sizeMax.x, point.x);
    self.sizeMax.y = max(self.sizeMax.y, point.y);
    self.sizeMax.z = max(self.sizeMax.z, point.z);
    return self;
  }

    /// Expands the box by the given vector, moving both min and max bounds.
    static expandByVector = function (vector) {
    gml_pragma("forceinline");
    self.sizeMin.sub(vector);
    self.sizeMax.add(vector);
    return self;
  }

    /// Expands the box uniformly by a scalar value in all directions.
    static expandByScalar = function (scalar) {
    gml_pragma("forceinline");
    self.sizeMin.addScalar(-scalar);
    self.sizeMax.addScalar(scalar);
    return self;
  }

    /// Returns true if the box contains the given point.
    /// Point must be a UeVector3.
    static containsPoint = function (point) {
    gml_pragma("forceinline");
    return point.x >= self.sizeMin.x && point.x <= self.sizeMax.x &&
      point.y >= self.sizeMin.y && point.y <= self.sizeMax.y &&
      point.z >= self.sizeMin.z && point.z <= self.sizeMax.z;
  }

    /// Returns true if the given box is fully contained within this box.
    static containsBox = function (box) {
    gml_pragma("forceinline");
    return self.sizeMin.x <= box.sizeMin.x && box.sizeMax.x <= self.sizeMax.x &&
      self.sizeMin.y <= box.sizeMin.y && box.sizeMax.y <= self.sizeMax.y &&
      self.sizeMin.z <= box.sizeMin.z && box.sizeMax.z <= self.sizeMax.z;
  }

    /// Returns a parameter representing where a point lies within the box (0-1).
    /// Point must be a UeVector3.
    static getParameter = function (point, target = new UeVector3()) {
    gml_pragma("forceinline");
    target.set(
      (point.x - self.sizeMin.x) / (self.sizeMax.x - self.sizeMin.x),
      (point.y - self.sizeMin.y) / (self.sizeMax.y - self.sizeMin.y),
      (point.z - self.sizeMin.z) / (self.sizeMax.z - self.sizeMin.z)
    );
    return target;
  }

    /// Returns true if this box intersects another box.
    static intersectsBox = function (box) {
    gml_pragma("forceinline");
    return !(box.sizeMax.x < self.sizeMin.x || box.sizeMin.x > self.sizeMax.x ||
      box.sizeMax.y < self.sizeMin.y || box.sizeMin.y > self.sizeMax.y ||
      box.sizeMax.z < self.sizeMin.z || box.sizeMin.z > self.sizeMax.z);
  }

    /// Returns true if this box intersects a sphere.
    static intersectsSphere = function (sphere) {
    gml_pragma("forceinline");
    var closestPoint = clampPoint(sphere.center);
    var dx = closestPoint.x - sphere.center.x;
    var dy = closestPoint.y - sphere.center.y;
    var dz = closestPoint.z - sphere.center.z;
    return (dx * dx + dy * dy + dz * dz) <= (sphere.radius * sphere.radius);
  }

    /// Returns true if this box intersects a plane.
    static intersectsPlane = function (plane) {
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
    /// Point must be a UeVector3. Returns a UeVector3.
    static clampPoint = function (point, target = new UeVector3()) {
    gml_pragma("forceinline");
    target.x = clamp(point.x, self.sizeMin.x, self.sizeMax.x);
    target.y = clamp(point.y, self.sizeMin.y, self.sizeMax.y);
    target.z = clamp(point.z, self.sizeMin.z, self.sizeMax.z);
    return target;
  }

    /// Returns the distance to a given point (0 if point is inside).
    /// Point must be a UeVector3.
    static distanceToPoint = function (point) {
    gml_pragma("forceinline");
    var cp = clampPoint(point);
    var dx = point.x - cp.x, dy = point.y - cp.y, dz = point.z - cp.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

    /// Computes the bounding sphere that encloses this box.
    static getBoundingSphere = function (target = new UeSphere()) {
    gml_pragma("forceinline");
    getCenter(target.center);
    target.radius = getSize().length() * 0.5;
    return target;
  }

    /// Intersects this box with another.
    static intersect = function (box) {
    gml_pragma("forceinline");
    self.sizeMin.maxVec(box.sizeMin);
    self.sizeMax.minVec(box.sizeMax);
    if (isEmpty()) makeEmpty();
    return self;
  }

    /// Expands this box to enclose another box.
    static union = function (box) {
    gml_pragma("forceinline");
    self.sizeMin.minVec(box.sizeMin);
    self.sizeMax.maxVec(box.sizeMax);
    return self;
  }

    /// Applies a 4x4 matrix transformation to the box (recomputing it).
    static applyMatrix4 = function (matrix) {
    gml_pragma("forceinline");
    if (isEmpty()) return self;

    var minX = self.sizeMin.x, minY = self.sizeMin.y, minZ = self.sizeMin.z;
    var maxX = self.sizeMax.x, maxY = self.sizeMax.y, maxZ = self.sizeMax.z;

    makeEmpty();
    var v = global.UE_DUMMY_VECTOR3;
    v.set(minX, minY, minZ).applyMatrix4(matrix); expandByPoint(v);
    v.set(minX, minY, maxZ).applyMatrix4(matrix); expandByPoint(v);
    v.set(minX, maxY, minZ).applyMatrix4(matrix); expandByPoint(v);
    v.set(minX, maxY, maxZ).applyMatrix4(matrix); expandByPoint(v);
    v.set(maxX, minY, minZ).applyMatrix4(matrix); expandByPoint(v);
    v.set(maxX, minY, maxZ).applyMatrix4(matrix); expandByPoint(v);
    v.set(maxX, maxY, minZ).applyMatrix4(matrix); expandByPoint(v);
    v.set(maxX, maxY, maxZ).applyMatrix4(matrix); expandByPoint(v);

    return self;
  }

    /// Translates the box by a given offset vector.
    static translate = function (offset) {
    gml_pragma("forceinline");
    self.sizeMin.add(offset);
    self.sizeMax.add(offset);
    return self;
  }

    /// Returns true if this box is equal to another.
    static equals = function (box) {
    gml_pragma("forceinline");
    return box.sizeMin.equals(self.sizeMin) && box.sizeMax.equals(self.sizeMax);
  }

    /// Converts the box to a JSON representation.
    static toJSON = function () {
    gml_pragma("forceinline");
    return {
      min: self.sizeMin.toJSON(),
      max: self.sizeMax.toJSON()
    };
  }

    /// Loads the box from a JSON representation.
    static fromJSON = function (data) {
    gml_pragma("forceinline");
    self.sizeMin.fromJSON(data.min);
    self.sizeMax.fromJSON(data.max);
    return self;
  }
}
