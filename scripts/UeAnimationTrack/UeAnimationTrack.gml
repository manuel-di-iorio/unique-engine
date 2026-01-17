/**
 * UeAnimationTrack
 * Handles keyframe animation for a single node (Object3D or Bone).
 * @param {string} nodeName Name of the node to animate
 */
function UeAnimationTrack(nodeName) constructor {
  self.nodeName = nodeName;

  /** @type {Array<Array>} Array of [time, value] for position (vec3) */
  self.positionKeys = [];

  /** @type {Array<Array>} Array of [time, value] for rotation (quaternion) */
  self.rotationKeys = [];

  /** @type {Array<Array>} Array of [time, value] for scale (vec3) */
  self.scaleKeys = [];

  /** @private @type {Array<real>} Internal temp vectors to avoid allocations during interpolation */
  self._tempPos = vec3_create();
  self._tempRot = quat_create();
  self._tempScale = vec3_create();
  
  /** @private @type {Array<real>} Resulting position from last interpolation */
  self.__position = undefined;
  /** @private @type {Array<real>} Resulting rotation from last interpolation */
  self.__rotation = undefined;
  /** @private @type {Array<real>} Resulting scale from last interpolation */
  self.__scale = undefined;

  /** @private @type {struct} Caches for last used keyframe index to speed up lookups */
  self._posCache = { lastIndex: 0 };
  self._rotCache = { lastIndex: 0 };
  self._scaleCache = { lastIndex: 0 };

  /**
   * Interpolates the track at a given time.
   * @param {real} time Current animation time in ticks
   */
  static interpolate = function (time) {
    gml_pragma("forceinline");
    self.__position = undefined;
    self.__rotation = undefined;
    self.__scale = undefined;

    // Reset caches if time jumped backwards (e.g. animation looped)
    if (array_length(self.positionKeys) > 0 && time < self.positionKeys[self._posCache.lastIndex][0]) self._posCache.lastIndex = 0;
    if (array_length(self.rotationKeys) > 0 && time < self.rotationKeys[self._rotCache.lastIndex][0]) self._rotCache.lastIndex = 0;
    if (array_length(self.scaleKeys) > 0 && time < self.scaleKeys[self._scaleCache.lastIndex][0]) self._scaleCache.lastIndex = 0;

    // Position interpolation
    if (array_length(self.positionKeys) > 0) {
      self.__position = self._interpolateVec3(self.positionKeys, time, self._tempPos, self._posCache);
    }

    // Rotation interpolation
    if (array_length(self.rotationKeys) > 0) {
      self.__rotation = self._interpolateQuat(self.rotationKeys, time, self._tempRot, self._rotCache);
    }

    // Scale interpolation
    if (array_length(self.scaleKeys) > 0) {
      self.__scale = self._interpolateVec3(self.scaleKeys, time, self._tempScale, self._scaleCache);
    }
  }

  /** @private
   *  Performs linear interpolation between two vec3 keyframes using binary search.
   *  @param {Array<Array>} keys Sorted array of [time, value] pairs
   *  @param {real} time Current animation time in ticks
   *  @param {Array<real>} target Pre-allocated vec3 to store the result
   *  @param {object} cache Optional object to store last index for faster lookup
   *  @returns {Array<real>} Interpolated vec3 (same as target parameter)
   */
  static _interpolateVec3 = function (keys, time, target, cache = {}) {
    var n = array_length(keys);
    if (n == 1 || time <= keys[0][0]) return keys[0][1];
    if (time >= keys[n - 1][0]) return keys[n - 1][1];

    // Use cached index if possible
    var left = 0, right = n - 1;
    if (cache.lastIndex != undefined) {
      left = cache.lastIndex;
      right = left + 1;
      if (time >= keys[right][0]) {
        left = 0; // fallback to full binary search
        right = n - 1;
      }
    }

    // Binary search
    while (left <= right) {
      var mid = floor((left + right) / 2);
      if (keys[mid][0] == time) {
        cache.lastIndex = mid;
        return keys[mid][1];
      }
      if (keys[mid][0] < time) left = mid + 1;
      else right = mid - 1;
    }

    var k1 = keys[right];
    var k2 = keys[left];
    cache.lastIndex = right;
    var t = (time - k1[0]) / (k2[0] - k1[0]);
    return vec3_lerp_vectors(target, k1[1], k2[1], t);
  }

  /** @private
  *  Performs spherical linear interpolation between two quaternion keyframes using binary search.
  *  @param {Array<Array>} keys Sorted array of [time, value] pairs
  *  @param {real} time Current animation time in ticks
  *  @param {Array<real>} target Pre-allocated quaternion to store the result
  *  @param {object} cache Optional object to store last index for faster lookup
  *  @returns {Array<real>} Interpolated quaternion (same as target parameter)
  */
  static _interpolateQuat = function (keys, time, target, cache = {}) {
    var n = array_length(keys);
    if (n == 1 || time <= keys[0][0]) return keys[0][1];
    if (time >= keys[n - 1][0]) return keys[n - 1][1];

    var left = 0, right = n - 1;
    if (cache.lastIndex != undefined) {
      left = cache.lastIndex;
      right = left + 1;
      if (time >= keys[right][0]) {
        left = 0;
        right = n - 1;
      }
    }

    while (left <= right) {
      var mid = floor((left + right) / 2);
      if (keys[mid][0] == time) {
        cache.lastIndex = mid;
        return keys[mid][1];
      }
      if (keys[mid][0] < time) left = mid + 1;
      else right = mid - 1;
    }

    var k1 = keys[right];
    var k2 = keys[left];
    cache.lastIndex = right;
    var t = (time - k1[0]) / (k2[0] - k1[0]);
    return quat_slerp_quaternions(target, k1[1], k2[1], t);
  }
}
