/**
 * UeAnimationTrack
 * Handles keyframe animation for a single node (Object3D or Bone).
 * @param {string} nodeName Name of the node to animate
 */
function UeAnimationTrack(nodeName) constructor {
  self.nodeName = nodeName;

  /** @type {Array<real>} Flattened array of [time, x, y, z] for position */
  self.positionKeys = [];

  /** @type {Array<real>} Flattened array of [time, x, y, z, w] for rotation (quaternion) */
  self.rotationKeys = [];

  /** @type {Array<real>} Flattened array of [time, x, y, z] for scale */
  self.scaleKeys = [];

  /** @private @type {real} Last interpolation time to avoid redundant calculations */
  self._lastTime = -1;

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
    
    // Skip if time hasn't changed
    if (time == self._lastTime) return;
    self._lastTime = time;

    self.__position = undefined;
    self.__rotation = undefined;
    self.__scale = undefined;

    // Reset caches if time jumped backwards (e.g. animation looped)
    if (array_length(self.positionKeys) > 0 && time < self.positionKeys[self._posCache.lastIndex]) self._posCache.lastIndex = 0;
    if (array_length(self.rotationKeys) > 0 && time < self.rotationKeys[self._rotCache.lastIndex]) self._rotCache.lastIndex = 0;
    if (array_length(self.scaleKeys) > 0 && time < self.scaleKeys[self._scaleCache.lastIndex]) self._scaleCache.lastIndex = 0;

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
   *  @param {Array<real>} keys Flattened array of [time, x, y, z]
   *  @param {real} time Current animation time in ticks
   *  @param {Array<real>} target Pre-allocated vec3 to store the result
   *  @param {object} cache Optional object to store last index for faster lookup
   *  @returns {Array<real>} Interpolated vec3 (same as target parameter)
   */
  static _interpolateVec3 = function (keys, time, target, cache = {}) {
    var n = array_length(keys); // Total elements
    var count = n >> 2; // Number of keys (each key is 4 elements: t, x, y, z)
    
    if (count == 1 || time <= keys[0]) {
        target[0] = keys[1]; target[1] = keys[2]; target[2] = keys[3];
        return target;
    }
    if (time >= keys[n - 4]) {
        target[0] = keys[n-3]; target[1] = keys[n-2]; target[2] = keys[n-1];
        return target;
    }

    // Use cached index if possible (lastIndex points to the 'time' element of the key)
    var lastIdx = cache.lastIndex;
    if (time >= keys[lastIdx] && time < keys[lastIdx + 4]) {
        var t1 = keys[lastIdx];
        var t2 = keys[lastIdx + 4];
        var f = (time - t1) / (t2 - t1);
        
        target[0] = keys[lastIdx + 1] + (keys[lastIdx + 5] - keys[lastIdx + 1]) * f;
        target[1] = keys[lastIdx + 2] + (keys[lastIdx + 6] - keys[lastIdx + 2]) * f;
        target[2] = keys[lastIdx + 3] + (keys[lastIdx + 7] - keys[lastIdx + 3]) * f;
        return target;
    }

    // Binary search
    var left = 0, right = count - 1;
    while (left <= right) {
      var mid = (left + right) >> 1;
      var midTime = keys[mid << 2];
      if (midTime == time) {
        var idx = mid << 2;
        cache.lastIndex = idx;
        target[0] = keys[idx + 1]; target[1] = keys[idx + 2]; target[2] = keys[idx + 3];
        return target;
      }
      if (midTime < time) left = mid + 1;
      else right = mid - 1;
    }

    var idx1 = right << 2;
    var idx2 = left << 2;
    cache.lastIndex = idx1;
    
    var t1 = keys[idx1];
    var t2 = keys[idx2];
    var f = (time - t1) / (t2 - t1);
    
    target[0] = keys[idx1 + 1] + (keys[idx2 + 1] - keys[idx1 + 1]) * f;
    target[1] = keys[idx1 + 2] + (keys[idx2 + 2] - keys[idx1 + 2]) * f;
    target[2] = keys[idx1 + 3] + (keys[idx2 + 3] - keys[idx1 + 3]) * f;
    return target;
  }

  /** @private
  *  Performs spherical linear interpolation between two quaternion keyframes using binary search.
  *  @param {Array<real>} keys Flattened array of [time, x, y, z, w]
  *  @param {real} time Current animation time in ticks
  *  @param {Array<real>} target Pre-allocated quaternion to store the result
  *  @param {object} cache Optional object to store last index for faster lookup
  *  @returns {Array<real>} Interpolated quaternion (same as target parameter)
  */
  static _interpolateQuat = function (keys, time, target, cache = {}) {
    var n = array_length(keys);
    var count = n div 5; // Each key is 5 elements: t, x, y, z, w
    
    if (count == 1 || time <= keys[0]) {
        target[0] = keys[1]; target[1] = keys[2]; target[2] = keys[3]; target[3] = keys[4];
        return target;
    }
    if (time >= keys[n - 5]) {
        target[0] = keys[n-4]; target[1] = keys[n-3]; target[2] = keys[n-2]; target[3] = keys[n-1];
        return target;
    }

    // Use cached index if possible
    var lastIdx = cache.lastIndex;
    if (time >= keys[lastIdx] && time < keys[lastIdx + 5]) {
        var t1 = keys[lastIdx];
        var t2 = keys[lastIdx + 5];
        var f = (time - t1) / (t2 - t1);
        
        // Use quat_slerp_flat or similar if available, or just call slerp
        // For performance, we can inline a bit or use global temps
        var q1 = global.UE_QUAT_TEMP0;
        var q2 = global.UE_QUAT_TEMP1;
        q1[0] = keys[lastIdx+1]; q1[1] = keys[lastIdx+2]; q1[2] = keys[lastIdx+3]; q1[3] = keys[lastIdx+4];
        q2[0] = keys[lastIdx+6]; q2[1] = keys[lastIdx+7]; q2[2] = keys[lastIdx+8]; q2[3] = keys[lastIdx+9];
        
        return quat_slerp_quaternions(target, q1, q2, f);
    }

    var left = 0, right = count - 1;
    while (left <= right) {
      var mid = (left + right) >> 1;
      var midIdx = mid * 5;
      var midTime = keys[midIdx];
      if (midTime == time) {
        cache.lastIndex = midIdx;
        target[0] = keys[midIdx + 1]; target[1] = keys[midIdx + 2]; target[2] = keys[midIdx + 3]; target[3] = keys[midIdx + 4];
        return target;
      }
      if (midTime < time) left = mid + 1;
      else right = mid - 1;
    }

    var idx1 = right * 5;
    var idx2 = left * 5;
    cache.lastIndex = idx1;
    
    var t1 = keys[idx1];
    var t2 = keys[idx2];
    var f = (time - t1) / (t2 - t1);
    
    var q1 = global.UE_QUAT_TEMP0;
    var q2 = global.UE_QUAT_TEMP1;
    q1[0] = keys[idx1+1]; q1[1] = keys[idx1+2]; q1[2] = keys[idx1+3]; q1[3] = keys[idx1+4];
    q2[0] = keys[idx2+1]; q2[1] = keys[idx2+2]; q2[2] = keys[idx2+3]; q2[3] = keys[idx2+4];
    
    return quat_slerp_quaternions(target, q1, q2, f);
  }
}
