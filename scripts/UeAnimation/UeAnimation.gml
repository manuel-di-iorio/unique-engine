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
        
        for (var i = 0, il = array_length(self.tracks); i < il; i++) {
            var track = self.tracks[i];
            var target = root.getObjectByName(track.nodeName);
            if (target != undefined) {
                array_push(boundTracks, {
                    track: track,
                    target: target,
                    isBone: target[$ "isBone"] ?? false
                });
            }
        }
        
        self._targetCache[$ rootId] = boundTracks;
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

        for (var i = 0, il = array_length(boundTracks); i < il; i++) {
            var data = boundTracks[i];
            var track = data.track;
            var target = data.target;

            track.interpolate(ticks);

            if (data.isBone) {
                if (track.__position != undefined) vec3_copy(target.position, track.__position);
                if (track.__rotation != undefined) quat_copy(target.rotation, track.__rotation);
                if (track.__scale != undefined) vec3_copy(target.scale, track.__scale);
            } else {
                // For standard objects, only apply if keys exist to avoid overwriting user settings
                // AND if there's more than 1 key (length > 4 for pos/scale, > 5 for rotation)
                if (track.__position != undefined && array_length(track.positionKeys) > 4) vec3_copy(target.position, track.__position);
                if (track.__rotation != undefined && array_length(track.rotationKeys) > 5) quat_copy(target.rotation, track.__rotation);
                if (track.__scale != undefined && array_length(track.scaleKeys) > 4) vec3_copy(target.scale, track.__scale);
            }
        }
    }
}
