function UeTransform(data = {}) constructor {
    // Local transform components
    position = data[$ "position"] ?? new UeVector3(data[$ "x"] ?? 0, data[$ "y"] ?? 0, data[$ "z"] ?? 0);
    rotation = data[$ "rotation"] ?? new UeQuaternion(data[$ "rx"] ?? 0, data[$ "ry"] ?? 0, data[$ "rz"] ?? 0);
    scale    = data[$ "scale"]    ?? new UeVector3(data[$ "sx"] ?? 1, data[$ "sy"] ?? 1, data[$ "sz"] ?? 1);
    up       = global.UE_OBJECT3D_DEFAULT_UP.clone(); // @MissingDoc

    // Transformation matrices
    matrix = new UeMatrix4();
    matrixWorld = new UeMatrix4();

    // Parent (optional)
    parent = data[$ "parent"] ?? undefined;

    // Matrix update flags
    matrixAutoUpdate = global.UE_OBJECT3D_DEFAULT_MATRIX_AUTO_UPDATE; // Automatically update local matrix @MissingDoc
    matrixWorldAutoUpdate = global.UE_OBJECT3D_DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // Automatically update world matrix @MissingDoc
    matrixWorldNeedsUpdate = false;      // Tells to update the world matrix for this frame
    
    // Internals
    __frustumSphere = undefined;
    
    /// Rebuild local matrix from position/rotation/scale
    function updateMatrix() {
        matrix.compose(position, rotation, scale);
        matrixWorldNeedsUpdate = true;
        return self;
    }

    // Update local matrix and matrix world, also on children
    // @MissingDoc
    function updateMatrixWorld(force = false, frustum = undefined) {
        if (matrixAutoUpdate) {
            updateMatrix();
        }
        
        if (matrixWorldNeedsUpdate || force) {
            if (parent == undefined) {
                matrixWorld.copy(matrix);
            } else {
                matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
            }
            
            matrixWorldNeedsUpdate = false; 
			force = true;
            
            // Update the object's frustum bounding sphere
            var boundingSphere = self[$ "geometry"] != undefined ? geometry.boundingSphere : undefined;
            if (boundingSphere != undefined) {
                if (__frustumSphere == undefined) __frustumSphere = new UeSphere();
                __frustumSphere.copy(boundingSphere).applyMatrix4(matrixWorld);
            }
        } 
        
        for (var i = 0, len = array_length(children); i < len; i++) {
            children[i].updateMatrixWorld(force, frustum);
        }
        
        return self;
    }
    
    // @MissingDoc
    function forceUpdate() {
        matrix.compose(position, rotation, scale);
        
        if (parent == undefined) {
            matrixWorld.copy(matrix);
        } else {
            matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
        }
        
        
        // Update the object's frustum bounding sphere
        var boundingSphere = self[$ "geometry"] != undefined ? geometry.boundingSphere : undefined;
        if (boundingSphere != undefined) {
            if (__frustumSphere == undefined) __frustumSphere = new UeSphere();
            __frustumSphere.copy(boundingSphere).applyMatrix4(matrixWorld);
            
                
                var rotMatrix = matrixWorld.clone().setPositionXYZ(0, 0, 0);
                rotation.setFromRotationMatrix(rotMatrix);
                rotation.rotateX(90); 
        }
        
        for (var i = 0, len = array_length(children); i < len; i++) {
            children[i].updateMatrixWorld(force, frustum);
        }
    }
    
    /**
     * Update the matrixWorld of parents/children
     * 
     * This method computes the `matrixWorld` property, which represents the object's transform 
     * in world space, by combining its local `matrix` with the parent's `matrixWorld`.
     * 
     * Notes:
     *  - `matrixWorldNeedsUpdate` is reset to false after the update.
     *  - This method should be called if the object or its hierarchy has changed (e.g., after transformations or re-parenting).
     */
    function updateWorldMatrix(updateParents = false, updateChildren = false) {
        if (updateParents && parent != undefined) {
            parent.updateWorldMatrix(true, false);
        }
        
        if (matrixAutoUpdate) updateMatrix();
    
        if (matrixWorldAutoUpdate) {
            if (parent == undefined) {
                matrixWorld.copy(matrix);
            } else {
                matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
            } 
        }

        if (updateChildren) {
            for (var i = 0, len = array_length(children); i < len; i++) {
                var child = children[i];
                child.updateWorldMatrix(false, true);
            }
        }
    
        return self;
    }

    // --- Translation methods ---
    
    function setPosition(x, y, z) {
        position.set(x, y, z);
        return self;    
    }
    
    // Translate an object by distance along an axis in object space. The axis is assumed to be normalized.
    // @untested @MissingDoc
    function translateOnAxis(axis, distance) {
        var v = axis.clone().applyQuaternion(rotation);
        position.add(v.multiplyScalar(distance));
        return self;
    }
    
    function translate(x, y, z) {
        position.add(new UeVector3(x, y, z));
        return self;    
    }
    
    function translateX(value) {
        position.x += value;
        return self;
    }

    function translateY(value) {
        position.y += value;
        return self;
    }

    function translateZ(value) {
        position.z += value;
        return self;
    }

    // --- Rotation methods ---
    function lookAtVec(target) {
        var m = global.UE_DUMMY_MATRIX4;
        m.lookAt(position, target, up);
        rotation.setFromRotationMatrix(m);
        return self;     
    }
    
    function lookAt(x, y, z) {
        return lookAtVec(new UeVector3(x, y, z));
    }
    
    function setRotation(x, y, z) {
        rotation.setFromEuler(x, y, z);
        return self;
    }
    
    // Calls setFromRotationMatrix(m) on the rotation's quaternion
    // Assumes the upper 3x3 of m is a pure rotation matrix (i.e. unscaled).
    // @untested @MissingDoc
    function setRotationFromMatrix(mat) {
        rotation.setFromRotationMatrix(mat);
        return self;
    }
    
    // Copy the given quaternion into the rotation.
    // @untested @MissingDoc
    function setRotationFromQuaternion(quat) {
        rotation.copy(quat);
        return self;
    }
    
    function rotate(x, y, z) {
        rotation.multiply(new UeQuaternion(x, y, z));
        return self;
    }
    
    // Rotates the object around x axis in local space. value in degrees
    function rotateX(value) {
        rotation.rotateX(value);
        return self;
    }

    // Rotates the object around y axis in local space. value in degrees
    function rotateY(value) {
        rotation.rotateY(value);
        return self;
    }

    // Rotates the object around z axis in local space. value in degrees
    function rotateZ(value) {
        rotation.rotateZ(value);
        return self;
    }
    
    // Rotate an object along an axis in object space. The axis is assumed to be normalized
    // @untested @MissingDoc
    function rotateOnAxis(axis, angle) {
        var q = new UeQuaternion();
        q.setFromAxisAngle(axis, angle);
        rotation.multiply(q);
        return self;
    }
    
    // Rotate an object along an axis in world space. The axis is assumed to be normalized.
    // Assumes no rotated parent.
    // @untested @MissingDoc
    function rotateOnWorldAxis(axis, angle) {
        var q = new UeQuaternion();
        q.setFromAxisAngle(axis, angle);
        rotation.premultiply(q);
        return self;
    }

    // --- Scaling methods ---
    function setScale(x, y, z) {
        scale.set(x, y, z);
        return self;
    }
    
    function scaleX(value) {
        scale.x += value;
        return self;
    }

    function scaleY(value) {
        scale.y += value;
        return self;
    }

    function scaleZ(value) {
        scale.z += value;
        return self;
    }
    
    // Applies the matrix transform to the object and updates the object's position, rotation and scale.
    // @untested @MissingDoc
    function applyMatrix4(mat4) {
        matrix.multiply(mat4);
        matrix.decompose(position, rotation, scale);
        return self;
    }
    
    // Applies the rotation represented by the quaternion to the object.
    // @untested @MissingDoc
    function applyQuaternion(quat) {
        rotation.multiply(quat);
        return self;
    }
    
    // Returns a vector representing the position of the object in world space.
    // @untested @MissingDoc
    function getWorldPosition(target) {
        return target.setFromMatrixPosition(matrixWorld);
    }
    
    // Returns a quaternion representing the rotation of the object in world space.
    // @untested @MissingDoc
    function getWorldQuaternion(target) {
        matrixWorld.decompose(global.UE_DUMMY_VECTOR3, target, global.UE_DUMMY_VECTOR3);
        return target;
    }
    
    // Returns a vector of the scaling factors applied to the object for each axis in world space.
    // @untested @MissingDoc
    function getWorldScale(target) {
        matrixWorld.decompose(global.UE_DUMMY_VECTOR3, global.UE_DUMMY_QUATERNION, target);
        return target;
    }
    
    // Returns a vector representing the direction of object's positive Y axis in world space.
    // @untested @MissingDoc
    function getWorldDirection(target) {
        var v = new UeVector3(0, 1, 0);
        v.transformDirection(matrixWorld);
        return target.copy(v);
    }
    
    // @todo
    // Converts the vector from this object's local space to world space.
    function localToWorld(vec) {
        return vec.applyMatrix4(matrixWorld);
    }
    
    // @todo
    // Converts the vector from world space to this object's local space.
    function worldToLocal(vec) {
        return vec.applyMatrix4(matrixWorld.clone().invert());
    }
}
