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

    // Optimized arrays for updates
    self.__positions = [];
    self.__colors = [];
    self.__needsUpdate = true;

    // Create geometry and material
    var geometry = new UeLineSegmentsGeometry();
    var material = new UeLineBasicMaterial({ color: c_white });

    material.transparent = true;
    material.depthTest = false;
    material.forceSinglePass = true;
    material.side = cull_noculling;

    self.lineSegments = new UeLineSegments(geometry, material);
    self.add(self.lineSegments);

    // The helper itself doesn't need to update its matrix every frame
    // as it builds geometry in world space.
    self.matrixAutoUpdate = false;

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
        
        if (!self.visible) return self;
        
        var boneCount = array_length(self.bones);
        if (boneCount == 0) return self;

        var posIdx = 0;
        var colIdx = 0;

        for (var i = 0; i < boneCount; i++) {
            var bone = self.bones[i];

            if (bone.parent != undefined && bone.parent[$ "isBone"]) {
                var parent = bone.parent;

                // Get world positions directly from matrices (faster than getWorldPosition)
                var bMat = bone.matrixWorld;
                var pMat = parent.matrixWorld;

                // Add segment from parent to bone
                self.__positions[posIdx++] = pMat[12];
                self.__positions[posIdx++] = pMat[13];
                self.__positions[posIdx++] = pMat[14];
                
                self.__positions[posIdx++] = bMat[12];
                self.__positions[posIdx++] = bMat[13];
                self.__positions[posIdx++] = bMat[14];

                // Add colors for the segment
                self.__colors[colIdx++] = self.color1[0];
                self.__colors[colIdx++] = self.color1[1];
                self.__colors[colIdx++] = self.color1[2];
                
                self.__colors[colIdx++] = self.color2[0];
                self.__colors[colIdx++] = self.color2[1];
                self.__colors[colIdx++] = self.color2[2];
            }
        }

        if (posIdx > 0) {
            // Trim arrays if they were larger (though usually they stay same size)
            if (array_length(self.__positions) != posIdx) {
                array_resize(self.__positions, posIdx);
                array_resize(self.__colors, colIdx);
            }
            
            self.lineSegments.geometry.setPositions(self.__positions);
            self.lineSegments.geometry.setColors(self.__colors);
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
