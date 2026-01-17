/**
 * UeBone
 * Represents a bone in a skeleton. Inherits from UeObject3D so it can be part of the scene graph.
 * @param {struct} data Initialization data
 */
function UeBone(data = {}): UeObject3D(data) constructor {
    self.type = "Bone";
    self.isBone = true;
    
    /** @type {Array<real>} Matrix that transforms from mesh space to bone local space (Inverse Bind Pose) */
    self.offsetMatrix = data[$ "offsetMatrix"] ?? matrix_build_identity();
    
    /** @type {real} Unique index of the bone within the skeleton */
    self.index = data[$ "index"] ?? -1;
}