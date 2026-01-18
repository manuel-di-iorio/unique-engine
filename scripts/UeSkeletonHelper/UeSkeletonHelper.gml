/**
 * UeSkeletonHelper
 * A helper object to assist with visualizing a Skeleton.
 * @param {UeObject3D} object The object to visualize (usually a SkinnedMesh or Bone hierarchy)
 * @param {struct} data Optional initialization data
 */
function UeSkeletonHelper(object, data = {}): UeObject3D(data) constructor {
    self.root = object;
    self.bones = [];
    self.isSkeletonHelper = true;
    self.type = "SkeletonHelper";

    // Colors as [r, g, b] in 0-255 range
    self.color1 = [0, 0, 255]; // Default Blue
    self.color2 = [0, 255, 0]; // Default Green

    /**
     * Internal helper to find all bones in the hierarchy.
     */
    function _getBones(object, bones) {
        if (object[$ "isBone"]) {
            array_push(bones, object);
        }
        for (var i = 0, l = array_length(object.children); i < l; i++) {
            self._getBones(object.children[i], bones);
        }
    };

    self._getBones(self.root, self.bones);

    // Create geometry and material
    var geometry = new UeLineSegmentsGeometry();
    var material = new UeLineBasicMaterial({ color: c_white });

    material.transparent = true;
    material.depthTest = false;
    material.forceSinglePass = true;
    material.side = cull_noculling;

    self.lineSegments = new UeLineSegments(geometry, material);
    self.add(self.lineSegments);

    /**
     * Defines the colors of the helper.
     * @param {constant.color} color1 The first line color for each bone.
     * @param {constant.color} color2 The second line color for each bone.
     * @returns {UeSkeletonHelper}
     */
    function setColors(color1, color2) {
        self.color1 = [color_get_red(color1), color_get_green(color1), color_get_blue(color1)];
        self.color2 = [color_get_red(color2), color_get_green(color2), color_get_blue(color2)];
        return self;
    }

    /**
     * Updates the helper lines to match the bone positions.
     * @returns {UeSkeletonHelper}
     */
    function update() {
        gml_pragma("forceinline");
        var positions = [];
        var colors = [];

        var bonePos = global.UE_VEC3_TEMP1;
        var parentPos = global.UE_VEC3_TEMP2;

        var boneCount = array_length(self.bones);
        for (var i = 0; i < boneCount; i++) {
            var bone = self.bones[i];

            if (bone.parent != undefined && bone.parent[$ "isBone"]) {
                var parent = bone.parent;

                // Get world positions
                bone.getWorldPosition(bonePos);
                parent.getWorldPosition(parentPos);

                // Add segment from parent to bone
                array_push(positions, parentPos[0], parentPos[1], parentPos[2]);
                array_push(positions, bonePos[0], bonePos[1], bonePos[2]);

                // Add colors for the segment
                array_push(colors, self.color1[0], self.color1[1], self.color1[2]);
                array_push(colors, self.color2[0], self.color2[1], self.color2[2]);
            }
        }

        if (array_length(positions) > 0) {
            self.lineSegments.geometry.setPositions(positions);
            self.lineSegments.geometry.setColors(colors);
        }

        return self;
    }

    /**
     * Dispose of GPU resources.
     * @returns {UeSkeletonHelper}
     */
    function dispose() {
        gml_pragma("forceinline");
        self.lineSegments.geometry.dispose();
        self.lineSegments.material.dispose();
        return self;
    }

    // Initial update
    self.update();
}
