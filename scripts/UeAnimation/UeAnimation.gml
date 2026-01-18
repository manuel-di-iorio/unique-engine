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
     * Evaluates the animation for a given time and applies it to a target hierarchy.
     * @param {real} time Current time in seconds
     * @param {UeObject3D} root The root of the hierarchy to animate
     */
    static evaluate = function (time, root) {
        gml_pragma("forceinline");
        var ticks = (time * self.ticksPerSecond) % self.duration;

        for (var i = 0, il = array_length(self.tracks); i < il; i++) {
            var track = self.tracks[i];

            var target = root.getObjectByName(track.nodeName);
            if (target != undefined) {
                track.interpolate(ticks);

                if (track.__position != undefined) vec3_copy(target.position, track.__position);
                if (track.__rotation != undefined) quat_copy(target.rotation, track.__rotation);
                if (track.__scale != undefined) vec3_copy(target.scale, track.__scale);

                // target.updateMatrix();
                target.updateMatrixWorld(true);
            }
        }
    }
}
