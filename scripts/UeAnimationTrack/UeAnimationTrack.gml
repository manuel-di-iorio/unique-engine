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

  /** @private @type {struct} Optional baked data for high-performance playback */
  self._baked = {
    pos: undefined,
    rot: undefined,
    scl: undefined,
    duration: 1,
    sampleCount: 0
  };

  /** @private @type {struct} Caches for last used keyframe index to speed up lookups */
  self._posCache = { lastIndex: 0 };
  self._rotCache = { lastIndex: 0 };
  self._scaleCache = { lastIndex: 0 };

  /** @private @type {real} Cached array lengths */
  self._posLen = 0;
  self._rotLen = 0;
  self._scaleLen = 0;

  /**
   * Updates metadata and bakes the track into a fixed-frequency lookup table.
   * Should be called after modifying keyframe arrays.
   * @param {real} duration Total duration of the animation in ticks
   * @param {real} fps Samples per second to bake
   */
  static update = function(duration, fps = 60) {
    gml_pragma("forceinline");
    self._posLen = array_length(self.positionKeys);
    self._rotLen = array_length(self.rotationKeys);
    self._scaleLen = array_length(self.scaleKeys);
    
    // Reset caches for baking process
    self._posCache.lastIndex = 0;
    self._rotCache.lastIndex = 0;
    self._scaleCache.lastIndex = 0;
    self._lastTime = -1;

    var totalSamples = ceil(duration * (fps / 60)) + 1; 
    
    var _pLen = self._posLen;
    var _rLen = self._rotLen;
    var _sLen = self._scaleLen;
    
    if (_pLen > 0) {
        self._baked.pos = array_create(totalSamples * 3);
        for (var i = 0; i < totalSamples; i++) {
            var t = (i / (totalSamples - 1)) * duration;
            var res = self._interpolateVec3(self.positionKeys, _pLen, t, self._tempPos, self._posCache);
            var idx = i * 3;
            self._baked.pos[idx] = res[0]; self._baked.pos[idx+1] = res[1]; self._baked.pos[idx+2] = res[2];
        }
    }
    
    if (_rLen > 0) {
        self._baked.rot = array_create(totalSamples * 4);
        for (var i = 0; i < totalSamples; i++) {
            var t = (i / (totalSamples - 1)) * duration;
            var res = self._interpolateQuat(self.rotationKeys, _rLen, t, self._tempRot, self._rotCache);
            var idx = i * 4;
            self._baked.rot[idx] = res[0]; self._baked.rot[idx+1] = res[1]; self._baked.rot[idx+2] = res[2]; self._baked.rot[idx+3] = res[3];
        }
    }
    
    if (_sLen > 0) {
        self._baked.scl = array_create(totalSamples * 3);
        for (var i = 0; i < totalSamples; i++) {
            var t = (i / (totalSamples - 1)) * duration;
            var res = self._interpolateVec3(self.scaleKeys, _sLen, t, self._tempScale, self._scaleCache);
            var idx = i * 3;
            self._baked.scl[idx] = res[0]; self._baked.scl[idx+1] = res[1]; self._baked.scl[idx+2] = res[2];
        }
    }
    
    self._baked.duration = duration;
    self._baked.sampleCount = totalSamples;
    return self;
  }

  /**
   * Interpolates the track at a given time using baked data.
   * @param {real} time Current animation time in ticks
   */
  static interpolate = function (time) {
    gml_pragma("forceinline");
    
    if (time == self._lastTime) return;
    self._lastTime = time;

    self.__position = undefined;
    self.__rotation = undefined;
    self.__scale = undefined;

    var _b = self._baked;
    if (_b.sampleCount == 0) return;

    var sample = (time / _b.duration) * (_b.sampleCount - 1);
    var idx = floor(sample);
    
    if (_b.pos != undefined) {
        var i3 = idx * 3;
        var res = self._tempPos;
        var bData = _b.pos;
        res[0] = bData[i3]; res[1] = bData[i3+1]; res[2] = bData[i3+2];
        self.__position = res;
    }

    if (_b.rot != undefined) {
        var i4 = idx * 4;
        var res = self._tempRot;
        var bData = _b.rot;
        res[0] = bData[i4]; res[1] = bData[i4+1]; res[2] = bData[i4+2]; res[3] = bData[i4+3];
        self.__rotation = res;
    }

    if (_b.scl != undefined) {
        var i3 = idx * 3;
        var res = self._tempScale;
        var bData = _b.scl;
        res[0] = bData[i3]; res[1] = bData[i3+1]; res[2] = bData[i3+2];
        self.__scale = res;
    }
  }

  /** @private
   *  Performs linear interpolation between two vec3 keyframes using binary search.
   *  @param {Array<real>} keys Flattened array of [time, x, y, z]
   *  @param {real} n Array length
   *  @param {real} time Current animation time in ticks
   *  @param {Array<real>} target Pre-allocated vec3 to store the result
   *  @param {object} cache Optional object to store last index for faster lookup
   *  @returns {Array<real>} Interpolated vec3 (same as target parameter)
   */
  static _interpolateVec3 = function (keys, n, time, target, cache) {
    var count = n >> 2; // Number of keys (each key is 4 elements: t, x, y, z)
    
    if (count == 1 || time <= keys[0]) {
        target[0] = keys[1]; target[1] = keys[2]; target[2] = keys[3];
        return target;
    }
    if (time >= keys[n - 4]) {
        target[0] = keys[n-3]; target[1] = keys[n-2]; target[2] = keys[n-1];
        return target;
    }

    // 1. Check current cached index
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

    // 2. Check next index (loop-friendly)
    var nextIdx = (lastIdx + 4 < n) ? lastIdx + 4 : 0;
    if (time >= keys[nextIdx] && (nextIdx + 4 >= n || time < keys[nextIdx + 4])) {
        cache.lastIndex = nextIdx;
        var t1 = keys[nextIdx];
        var t2 = keys[nextIdx + 4];
        var f = (time - t1) / (t2 - t1);
        target[0] = keys[nextIdx + 1] + (keys[nextIdx + 5] - keys[nextIdx + 1]) * f;
        target[1] = keys[nextIdx + 2] + (keys[nextIdx + 6] - keys[nextIdx + 2]) * f;
        target[2] = keys[nextIdx + 3] + (keys[nextIdx + 7] - keys[nextIdx + 3]) * f;
        return target;
    }

    // 3. Fallback to binary search
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
  *  @param {real} n Array length
  *  @param {real} time Current animation time in ticks
  *  @param {Array<real>} target Pre-allocated quaternion to store the result
  *  @param {object} cache Optional object to store last index for faster lookup
  *  @returns {Array<real>} Interpolated quaternion (same as target parameter)
  */
  static _interpolateQuat = function (keys, n, time, target, cache) {
    var count = n / 5; // Each key is 5 elements: t, x, y, z, w
    
    if (count == 1 || time <= keys[0]) {
        target[0] = keys[1]; target[1] = keys[2]; target[2] = keys[3]; target[3] = keys[4];
        return target;
    }
    if (time >= keys[n - 5]) {
        target[0] = keys[n-4]; target[1] = keys[n-3]; target[2] = keys[n-2]; target[3] = keys[n-1];
        return target;
    }

    // 1. Check current cached index
    var lastIdx = cache.lastIndex;
    if (time >= keys[lastIdx] && time < keys[lastIdx + 5]) {
        var t1 = keys[lastIdx];
        var t2 = keys[lastIdx + 5];
        var f = (time - t1) / (t2 - t1);
        return slerpFlat(target, 0, keys, lastIdx + 1, keys, lastIdx + 6, f);
    }

    // 2. Check next index (loop-friendly)
    var nextIdx = (lastIdx + 5 < n) ? lastIdx + 5 : 0;
    if (time >= keys[nextIdx] && (nextIdx + 5 < n && time < keys[nextIdx + 5])) {
        cache.lastIndex = nextIdx;
        var t1 = keys[nextIdx];
        var t2 = keys[nextIdx + 5];
        var f = (time - t1) / (t2 - t1);
        return slerpFlat(target, 0, keys, nextIdx + 1, keys, nextIdx + 6, f);
    }

    // 3. Fallback to binary search
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

    var idx1 = (right * 5) | 0;
    var idx2 = (left * 5) | 0;
    cache.lastIndex = idx1;
    
    var t1 = keys[idx1];
    var t2 = keys[idx2];
    var f = (time - t1) / (t2 - t1);
    
    return slerpFlat(target, 0, keys, idx1 + 1, keys, idx2 + 1, f);
  }
}
