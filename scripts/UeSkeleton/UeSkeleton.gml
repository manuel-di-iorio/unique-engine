/**
 * UeSkeleton
 * Manages a collection of bones for skeletal animation.
 * @param {Array<UeBone>} bones Array of bones
 */
function UeSkeleton(bones = []) constructor {
    self.type = "Skeleton";
    self.isSkeleton = true;
    
    /** @type {Array<UeBone>} List of bones in this skeleton */
    self.bones = bones;
    
    /** @type {Array<real>} Flattened array of matrices for all bones (WorldMatrix * OffsetMatrix) */
    self.boneMatrices = [];
    
    /** @type {UeBone} The root bone of the hierarchy */
    self.rootBone = (array_length(bones) > 0) ? bones[0] : undefined;

    /** @private @type {Array<real>} Internal temporary matrix to avoid allocations during update */
    self._tempMatrix = matrix_build_identity();

    /**
     * Updates all bone matrices to be sent to the shader.
     */
    static update = function() {
        gml_pragma("forceinline");
        var boneCount = array_length(self.bones);
        
        // Resize boneMatrices if needed (16 floats per matrix)
        if (array_length(self.boneMatrices) != boneCount * 16) {
            self.boneMatrices = array_create(boneCount * 16, 0);
        }

        for (var i = 0; i < boneCount; i++) {
            var bone = self.bones[i];
            
            // Calculate final bone matrix: BoneWorldMatrix * BoneOffsetMatrix
            matrix_multiply(bone.offsetMatrix, bone.matrixWorld, self._tempMatrix);
            
            // Copy the 16 elements of the calculated matrix into the flattened array
            array_copy(self.boneMatrices, i * 16, self._tempMatrix, 0, 16);
        }
    }
}
