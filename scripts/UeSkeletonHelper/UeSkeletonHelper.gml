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

    // Colors for the helper lines
    self.color1 = data[$ "color1"] ?? c_blue;
    self.color2 = data[$ "color2"] ?? c_lime;

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
    self.__colorsDirty = true;
    self.__lastBonesVersionSum = -1;

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
        if (self.color1 != color1 || self.color2 != color2) {
            self.color1 = color1;
            self.color2 = color2;
            self.__colorsDirty = true;
        }
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

        // 1. Check if anything actually changed
        var _versionSum = 0;
        for (var i = 0; i < boneCount; i++) {
            _versionSum += self.bones[i].version;
        }

        if (_versionSum == self.__lastBonesVersionSum && !self.__colorsDirty) {
            return self;
        }
        
        var _posDirty = (_versionSum != self.__lastBonesVersionSum);
        self.__lastBonesVersionSum = _versionSum;

        // 2. Pre-resize arrays if needed to avoid dynamic allocations in the loop
        var segmentCount = 0;
        for (var i = 0; i < boneCount; i++) {
            if (self.bones[i].parent != undefined && self.bones[i].parent[$ "isBone"]) {
                segmentCount++;
            }
        }
        
        var posLen = segmentCount * 6; // 2 vertices * 3 coords
        var colLen = segmentCount * 4; // 2 vertices * (color + alpha)
        
        if (array_length(self.__positions) != posLen) array_resize(self.__positions, posLen);
        if (array_length(self.__colors) != colLen) array_resize(self.__colors, colLen);

        var posIdx = 0;
        var colIdx = 0;
        
        var c1 = self.color1;
        var c2 = self.color2;

        for (var i = 0; i < boneCount; i++) {
            var bone = self.bones[i];

            if (bone.parent != undefined && bone.parent[$ "isBone"]) {
                var parent = bone.parent;

                if (_posDirty) {
                    var bMat = bone.matrixWorld;
                    var pMat = parent.matrixWorld;

                    // Add segment from parent to bone
                    self.__positions[posIdx]     = pMat[12];
                    self.__positions[posIdx + 1] = pMat[13];
                    self.__positions[posIdx + 2] = pMat[14];
                    
                    self.__positions[posIdx + 3] = bMat[12];
                    self.__positions[posIdx + 4] = bMat[13];
                    self.__positions[posIdx + 5] = bMat[14];
                }
                posIdx += 6;

                if (self.__colorsDirty) {
                    // Add raw colors for the segment [color, alpha]
                    self.__colors[colIdx]     = c1;
                    self.__colors[colIdx + 1] = 1.0;
                    
                    self.__colors[colIdx + 2] = c2;
                    self.__colors[colIdx + 3] = 1.0;
                }
                colIdx += 4;
            }
        }

        if (posIdx > 0) {
            // Update geometry attributes separately as requested
            // This avoids double build if only one changes, or double array work
            var _geo = self.lineSegments.geometry;
            
            if (_posDirty && self.__colorsDirty) {
                // If both changed, we can use the batch update to call build() only once
                _geo.setPositions(self.__positions, false);
                _geo.setRawColors(self.__colors, true);
            } else if (_posDirty) {
                _geo.setPositions(self.__positions, true);
            } else if (self.__colorsDirty) {
                _geo.setRawColors(self.__colors, true);
            }
        }

        self.__colorsDirty = false;
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
