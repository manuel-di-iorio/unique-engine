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
        for (var i = 0, il = array_length(_tracks); i < il; i++) {
            var track = _tracks[i];
            
            // Ensure track metadata and baking are up to date
            track.update(self.duration, 60);
            
            var target = root.getObjectByName(track.nodeName);
            if (target != undefined) {
                var isBone = target[$ "isBone"] ?? false;
                var hasPos = array_length(track.positionKeys) > (isBone ? 0 : 4);
                var hasRot = array_length(track.rotationKeys) > (isBone ? 0 : 5);
                var hasScl = array_length(track.scaleKeys) > (isBone ? 0 : 4);

                array_push(boundTracks, {
                    baked: track._baked,
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
     * @param {real} fps Samples per second to bake
     */
    static update = function (fps = 60) {
        gml_pragma("forceinline");
        var _tracks = self.tracks;
        for (var i = 0, il = array_length(_tracks); i < il; i++) {
            _tracks[i].update(self.duration, fps);
        }
        return self;
    }

    /**
     * Evaluates the animation for a given time and applies it to a target hierarchy.
     * @param {real} time Current time in seconds
     * @param {UeObject3D} root The root of the hierarchy to animate
     */
    static evaluate = function (time, root) {
        gml_pragma("forceinline");
        var ticks = (time * self.ticksPerSecond) % self.duration;
        
        var rootId = root.uuid;
        var boundTracks = self._targetCache[$ rootId];
        
        // If not cached, bind it now (first time)
        if (boundTracks == undefined) {
            self.bind(root);
            boundTracks = self._targetCache[$ rootId];
        }

        var il = array_length(boundTracks);
        if (il == 0) return;

        // Calculate sample index once (all tracks share same duration/samples)
        var firstBaked = boundTracks[0].baked;
        var idx = floor((ticks / firstBaked.duration) * (firstBaked.sampleCount - 1));

        for (var i = 0; i < il; i++) {
            var data = boundTracks[i];
            var baked = data.baked;

            // Direct access to baked data arrays and target arrays
            var bPos = baked.pos;
            if (bPos != undefined) {
                var i3 = idx * 3;
                var tPos = data.targetPos;
                tPos[0] = bPos[i3]; tPos[1] = bPos[i3+1]; tPos[2] = bPos[i3+2];
            }

            var bRot = baked.rot;
            if (bRot != undefined) {
                var i4 = idx * 4;
                var tRot = data.targetRot;
                tRot[0] = bRot[i4]; tRot[1] = bRot[i4+1]; tRot[2] = bRot[i4+2]; tRot[3] = bRot[i4+3];
            }

            var bScl = baked.scl;
            if (bScl != undefined) {
                var i3 = idx * 3;
                var tScl = data.targetScl;
                tScl[0] = bScl[i3]; tScl[1] = bScl[i3+1]; tScl[2] = bScl[i3+2];
            }
        }
    }
}
