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

    /** @private @type {real} Last sum of bone versions to avoid redundant updates */
    self.__lastBonesVersionSum = -1;

    /**
     * Updates all bone matrices to be sent to the shader.
     */
    static update = function() {
        gml_pragma("forceinline");
        var _bones = self.bones;
        var boneCount = array_length(_bones);
        if (boneCount == 0) return;

        // 1. Check if any bone has changed using version sum
        var _versionSum = 0;
        for (var i = 0; i < boneCount; i++) {
            _versionSum += _bones[i].version;
        }
        
        if (_versionSum == self.__lastBonesVersionSum) return;
        self.__lastBonesVersionSum = _versionSum;

        // 2. Resize boneMatrices if needed (16 floats per matrix)
        var _boneMatrices = self.boneMatrices;
        if (array_length(_boneMatrices) != boneCount * 16) {
            _boneMatrices = array_create(boneCount * 16, 0);
            self.boneMatrices = _boneMatrices;
        }

        var _temp = self._tempMatrix;
        for (var i = 0; i < boneCount; i++) {
            var bone = _bones[i];
            
            // Calculate final bone matrix: BoneWorldMatrix * BoneOffsetMatrix
            matrix_multiply(bone.offsetMatrix, bone.matrixWorld, _temp);
            
            // Copy the 16 elements of the calculated matrix into the flattened array
            array_copy(_boneMatrices, i * 16, _temp, 0, 16);
        }
    }
}
