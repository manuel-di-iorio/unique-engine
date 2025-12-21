/// @function UeEuler(x, y, z, order)
/// @desc Costruttore Euler angles
function UeEuler(_x = 0, _y = 0, _z = 0, _order = "XYZ") constructor {
  self.isEuler = true;
  self.x = _x;
  self.y = _y;
  self.z = _z;
  self.order = _order;

    static set = function (x, y, z, order = "XYZ") {
    gml_pragma("forceinline");
    self.x = x;
    self.y = y;
    self.z = z;
    self.order = order;
    return self;
  }

    static clone = function () {
    gml_pragma("forceinline");
    return variable_clone(self);
  }

    static copy = function (euler) {
    gml_pragma("forceinline");
    self.x = euler.x;
    self.y = euler.y;
    self.z = euler.z;
    self.order = euler.order;
    return self;
  }

    static equals = function (euler) {
    gml_pragma("forceinline");
    return (self.x == euler.x) &&
      (self.y == euler.y) &&
      (self.z == euler.z) &&
      (self.order == euler.order);
  }

    static fromArray = function (arr) {
    gml_pragma("forceinline");
    self.x = arr[0];
    self.y = arr[1];
    self.z = arr[2];
    if (array_length(arr) > 3) self.order = arr[3];
    return self;
  }

    static toArray = function (arr = array_create(4), offset = 0) {
    gml_pragma("forceinline");
    arr[offset] = self.x;
    arr[offset + 1] = self.y;
    arr[offset + 2] = self.z;
    arr[offset + 3] = self.order;
    return arr;
  }

    /// Converts the euler angles to a JSON representation (struct).
    static toJSON = function () {
    gml_pragma("forceinline");
    return { x: self.x, y: self.y, z: self.z, order: self.order };
  }

    /// Loads the euler angles from a JSON representation (struct or array).
    static fromJSON = function (data) {
    gml_pragma("forceinline");
    self.x = data[$ "x"] ?? 0;
    self.y = data[$ "y"] ?? 0;
    self.z = data[$ "z"] ?? 0;
    self.order = data[$ "order"] ?? "XYZ";
    return self;
  }

    static setFromVector3 = function (v, order = undefined) {
    gml_pragma("forceinline");
    self.x = v.x;
    self.y = v.y;
    self.z = v.z;
    if (order != undefined) self.order = self.order;
    return self;
  }

    static reorder = function (newOrder) {
    gml_pragma("forceinline");
    var q = new UeQuaternion();
    q.setFromEuler(self.x, self.y, self.z);
    return self.setFromQuaternion(q, newOrder);
  }
    
    static setFromQuaternion = function (q, order = undefined) {
    gml_pragma("forceinline");
    order ??= self.order;
    global.UE_DUMMY_MATRIX4.makeRotationFromQuaternion(q);
    return self.setFromRotationMatrix(global.UE_DUMMY_MATRIX4, order);
  }
    
    static setFromRotationMatrix = function (m, order) {
    gml_pragma("forceinline");
    order ??= self.order;
    self.order = order;

    var te = m.data;
    var m11 = te[0], m12 = te[4], m13 = te[8];
    var m21 = te[1], m22 = te[5], m23 = te[9];
    var m31 = te[2], m32 = te[6], m33 = te[10];

    switch (order) {
      case "XYZ":
        self.y = darcsin(clamp(m13, -1, 1));
        if (abs(m13) < 0.9999999) {
          self.x = darctan2(-m23, m33);
          self.z = darctan2(-m12, m11);
        } else {
          self.x = darctan2(m32, m22);
          self.z = 0;
        }
        break;

      case "YXZ":
        self.x = darcsin(-clamp(m23, -1, 1));
        if (abs(m23) < 0.9999999) {
          self.y = darctan2(m13, m33);
          self.z = darctan2(m21, m22);
        } else {
          self.y = darctan2(-m31, m11);
          self.z = 0;
        }
        break;

      case "ZXY":
        self.x = darcsin(clamp(m32, -1, 1));
        if (abs(m32) < 0.9999999) {
          self.y = darctan2(-m31, m33);
          self.z = darctan2(-m12, m22);
        } else {
          self.y = 0;
          self.z = darctan2(m21, m11);
        }
        break;

      case "ZYX":
        self.y = darcsin(-clamp(m31, -1, 1));
        if (abs(m31) < 0.9999999) {
          self.x = darctan2(m32, m33);
          self.z = darctan2(m21, m11);
        } else {
          self.x = 0;
          self.z = darctan2(-m12, m22);
        }
        break;

      case "YZX":
        self.z = darcsin(clamp(m21, -1, 1));
        if (abs(m21) < 0.9999999) {
          self.x = darctan2(-m23, m22);
          self.y = darctan2(-m31, m11);
        } else {
          self.x = 0;
          self.y = darctan2(m13, m33);
        }
        break;

      case "XZY":
        self.z = darcsin(-clamp(m12, -1, 1));
        if (abs(m12) < 0.9999999) {
          self.x = darctan2(m32, m22);
          self.y = darctan2(m13, m11);
        } else {
          self.x = darctan2(-m23, m33);
          self.y = 0;
        }
        break;
    }

    return self;
  }
}
