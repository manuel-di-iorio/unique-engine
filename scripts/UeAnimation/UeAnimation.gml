/**
 * UeAnimation
 * Represents a set of animation tracks (aiAnimation).
 * @param {string} name Name of the animation
 * @param {real} duration Total duration in ticks
 * @param {real} ticksPerSecond Speed of animation (default 24)
 */
function UeAnimation(name, duration, ticksPerSecond = 24) constructor {
    self.name = name;
    self.duration = duration;
    self.ticksPerSecond = ticksPerSecond;

    /** @type {Array<UeAnimationTrack>} List of tracks for this animation */
    self.tracks = [];

    /** @type {Array<real>} Global timestamps for optimized baking */
    self.globalTimes = [];

    /** @private @type {struct} Map of track indices to target objects, cached per root */
    self._targetCache = {};

    /**
     * Adds an animation track to this animation.
     * @param {UeAnimationTrack} track The track to add
     */
    static addTrack = function (track) {
        gml_pragma("forceinline");
        array_push(self.tracks, track);
        return self;
    }

    /**
     * Binds the animation to a specific root hierarchy and caches target nodes.
     * @param {UeObject3D} root The root of the hierarchy
     */
    static bind = function (root) {
        gml_pragma("forceinline");
        var rootId = root.uuid;
        var boundTracks = [];
        
        var _tracks = self.tracks;
        
        // Ensure global timestamps and track baking are up to date
        if (array_length(self.globalTimes) == 0) {
            self.update();
        }
        
        for (var i = 0, il = array_length(_tracks); i < il; i++) {
            var track = _tracks[i];
            
            var target = root.getObjectByName(track.nodeName);
            if (target != undefined) {
                var isBone = target[$ "isBone"] ?? false;
                var hasPos = array_length(track.positionKeys) > (isBone ? 0 : 4);
                var hasRot = array_length(track.rotationKeys) > (isBone ? 0 : 5);
                var hasScl = array_length(track.scaleKeys) > (isBone ? 0 : 4);

                array_push(boundTracks, {
                    baked: track._baked,
                    posKeys: track.positionKeys,
                    rotKeys: track.rotationKeys,
                    sclKeys: track.scaleKeys,
                    targetPos: hasPos ? target.position : undefined,
                    targetRot: hasRot ? target.rotation : undefined,
                    targetScl: hasScl ? target.scale : undefined
                });
            }
        }
        
        self._targetCache[$ rootId] = boundTracks;
        return self;
    }

    /**
     * Updates and bakes all tracks in this animation for maximum performance.
     * This uses the Global Timestamp Mapping technique.
     */
    static update = function () {
        gml_pragma("forceinline");
        var _tracks = self.tracks;
        
        // 1. Collect all unique keyframe times from all tracks
        var timesMap = {};
        for (var i = 0, il = array_length(_tracks); i < il; i++) {
            var track = _tracks[i];
            
            var keys = track.positionKeys;
            for (var j = 0, jl = array_length(keys); j < jl; j += 4) {
                timesMap[$ string(keys[j])] = keys[j];
            }
            
            keys = track.rotationKeys;
            for (var j = 0, jl = array_length(keys); j < jl; j += 5) {
                timesMap[$ string(keys[j])] = keys[j];
            }
            
            keys = track.scaleKeys;
            for (var j = 0, jl = array_length(keys); j < jl; j += 4) {
                timesMap[$ string(keys[j])] = keys[j];
            }
        }
        
        // 2. Sort and unique times
        var times = variable_struct_get_names(timesMap);
        var timesCount = array_length(times);
        self.globalTimes = array_create(timesCount);
        for (var i = 0; i < timesCount; i++) {
            self.globalTimes[i] = timesMap[$ times[i]];
        }
        array_sort(self.globalTimes, true);
        
        // 3. Map tracks to these global times
        for (var i = 0, il = array_length(_tracks); i < il; i++) {
            _tracks[i].update(self.duration, self.globalTimes);
        }

        return self;
    }

    /**
     * Evaluates the animation for a given time and applies it to a target hierarchy.
     * This function uses a single binary search over global timestamps and then
     * interpolates track data using pre-mapped indices for maximum efficiency.
     * 
     * @param {real} time Current time in seconds.
     * @param {UeObject3D} root The root of the hierarchy to which the animation should be applied.
     * @param {real} [weight=1.0] Interpolation weight (0.0 to 1.0). If < 1.0, it blends with current object transform.
     */
    static evaluate = function (time, root, weight = 1.0) {
        gml_pragma("forceinline");
        
        // Convert time to ticks and handle looping based on animation duration
        var ticks = (time * self.ticksPerSecond) % self.duration;
        
        var rootId = root.uuid;
        var boundTracks = self._targetCache[$ rootId];
        
        // If the animation hasn't been bound to this hierarchy yet, bind it now and cache the results.
        if (boundTracks == undefined) {
            self.bind(root);
            boundTracks = self._targetCache[$ rootId];
        }

        var il = array_length(boundTracks);
        if (il == 0) return;

        // 1. Single binary search for the whole animation
        var gTimes = self.globalTimes;
        var gCount = array_length(gTimes);
        if (gCount == 0) return;
        
        var left = 0, right = gCount - 1;
        while (left <= right) {
            var mid = (left + right) >> 1;
            if (gTimes[mid] <= ticks) left = mid + 1;
            else right = mid - 1;
        }
        var gIdx = max(0, right);

        // 2. Interpolate each track using the pre-mapped indices
        for (var i = 0; i < il; i++) {
            var data = boundTracks[i];
            var baked = data.baked;
            
            // Position
            var keys = data.posKeys;
            var bIdx = baked.posIdx;
            if (bIdx != undefined && gIdx < array_length(bIdx)) {
                var idx1 = bIdx[gIdx];
                var n = array_length(keys);
                var tPos = data.targetPos;
                
                var vx, vy, vz;
                if (idx1 + 4 >= n || ticks <= keys[idx1]) {
                    vx = keys[idx1+1]; vy = keys[idx1+2]; vz = keys[idx1+3];
                } else {
                    var idx2 = idx1 + 4;
                    var t1 = keys[idx1], t2 = keys[idx2];
                    var f = (ticks - t1) / (t2 - t1);
                    vx = keys[idx1+1] + (keys[idx2+1] - keys[idx1+1]) * f;
                    vy = keys[idx1+2] + (keys[idx2+2] - keys[idx1+2]) * f;
                    vz = keys[idx1+3] + (keys[idx2+3] - keys[idx1+3]) * f;
                }

                if (weight == 1.0) {
                    tPos[0] = vx; tPos[1] = vy; tPos[2] = vz;
                } else {
                    tPos[0] += (vx - tPos[0]) * weight;
                    tPos[1] += (vy - tPos[1]) * weight;
                    tPos[2] += (vz - tPos[2]) * weight;
                }
            }

            // Rotation (Quat)
            keys = data.rotKeys;
            bIdx = baked.rotIdx;
            if (bIdx != undefined && gIdx < array_length(bIdx)) {
                var idx1 = bIdx[gIdx];
                var n = array_length(keys);
                var tRot = data.targetRot;
                
                if (weight == 1.0) {
                    if (idx1 + 5 >= n || ticks <= keys[idx1]) {
                        tRot[0] = keys[idx1+1]; tRot[1] = keys[idx1+2]; tRot[2] = keys[idx1+3]; tRot[3] = keys[idx1+4];
                    } else {
                        var idx2 = idx1 + 5;
                        var t1 = keys[idx1], t2 = keys[idx2];
                        var f = (ticks - t1) / (t2 - t1);
                        slerpFlat(tRot, 0, keys, idx1 + 1, keys, idx2 + 1, f);
                    }
                } else {
                    var tempQ = global.UE_QUAT_TEMP0;
                    if (idx1 + 5 >= n || ticks <= keys[idx1]) {
                        tempQ[0] = keys[idx1+1]; tempQ[1] = keys[idx1+2]; tempQ[2] = keys[idx1+3]; tempQ[3] = keys[idx1+4];
                    } else {
                        var idx2 = idx1 + 5;
                        var t1 = keys[idx1], t2 = keys[idx2];
                        var f = (ticks - t1) / (t2 - t1);
                        slerpFlat(tempQ, 0, keys, idx1 + 1, keys, idx2 + 1, f);
                    }
                    slerpFlat(tRot, 0, tRot, 0, tempQ, 0, weight);
                }
            }

            // Scale
            keys = data.sclKeys;
            bIdx = baked.sclIdx;
            if (bIdx != undefined && gIdx < array_length(bIdx)) {
                var idx1 = bIdx[gIdx];
                var n = array_length(keys);
                var tScl = data.targetScl;
                
                var vx, vy, vz;
                if (idx1 + 4 >= n || ticks <= keys[idx1]) {
                    vx = keys[idx1+1]; vy = keys[idx1+2]; vz = keys[idx1+3];
                } else {
                    var idx2 = idx1 + 4;
                    var t1 = keys[idx1], t2 = keys[idx2];
                    var f = (ticks - t1) / (t2 - t1);
                    vx = keys[idx1+1] + (keys[idx2+1] - keys[idx1+1]) * f;
                    vy = keys[idx1+2] + (keys[idx2+2] - keys[idx1+2]) * f;
                    vz = keys[idx1+3] + (keys[idx2+3] - keys[idx1+3]) * f;
                }

                if (weight == 1.0) {
                    tScl[0] = vx; tScl[1] = vy; tScl[2] = vz;
                } else {
                    tScl[0] += (vx - tScl[0]) * weight;
                    tScl[1] += (vy - tScl[1]) * weight;
                    tScl[2] += (vz - tScl[2]) * weight;
                }
            }
        }
    }

    /**
     * Blends between two animations and applies the result to a target hierarchy.
     * This is a static convenience method.
     * 
     * @param {UeAnimation} animA The first animation (base)
     * @param {real} timeA Time for the first animation
     * @param {UeAnimation} animB The second animation (to blend in)
     * @param {real} timeB Time for the second animation
     * @param {real} weight Blending factor (0 = only animA, 1 = only animB)
     * @param {UeObject3D} root The root hierarchy
     */
    static blend = function (animA, timeA, animB, timeB, weight, root) {
        gml_pragma("forceinline");
        animA.evaluate(timeA, root, 1.0);
        if (weight > 0) {
            animB.evaluate(timeB, root, weight);
        }
    }
}
