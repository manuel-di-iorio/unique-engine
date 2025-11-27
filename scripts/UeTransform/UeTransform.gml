function UeTransform(_data = undefined) constructor {
    var data = _data ?? {};
    
    // Local transform components
    position = data[$ "position"] ?? new UeVector3(data[$ "x"] ?? 0, data[$ "y"] ?? 0, data[$ "z"] ?? 0);
    rotation = data[$ "rotation"] ?? new UeQuaternion(data[$ "rx"] ?? 0, data[$ "ry"] ?? 0, data[$ "rz"] ?? 0);
    scale    = data[$ "scale"]    ?? new UeVector3(data[$ "sx"] ?? 1, data[$ "sy"] ?? 1, data[$ "sz"] ?? 1);
    up       = global.UE_OBJECT3D_DEFAULT_UP.clone();

    // Transformation matrices
    matrix = new UeMatrix4();
    matrixWorld = new UeMatrix4();

    // Parent (optional)
    parent = data[$ "parent"] ?? undefined;

    // Matrix update flags
    matrixAutoUpdate = global.UE_OBJECT3D_DEFAULT_MATRIX_AUTO_UPDATE; // Automatically update local matrix
    matrixWorldAutoUpdate = global.UE_OBJECT3D_DEFAULT_MATRIX_WORLD_AUTO_UPDATE; // Automatically update world matrix
    matrixWorldNeedsUpdate = false;      // Tells to update the world matrix for this frame
    
    // Internals
    __intersectionSphere = new UeSphere();
    
    /// Rebuild local matrix from position/rotation/scale
    function updateMatrix() {
        gml_pragma("forceinline");
        matrix.compose(position, rotation, scale);
        matrixWorldNeedsUpdate = true;
        return self;
    }

    // Update local matrix and matrix world, also on children
     function updateMatrixWorld(force = false) {
        gml_pragma("forceinline");
        if (matrixAutoUpdate) {
            updateMatrix();
        }
        
        if (matrixWorldNeedsUpdate || force) {
            if (parent == undefined) {
                matrixWorld.copy(matrix);
            } else {
                var _parentMatrixWorld = parent[$ "matrixWorld"];
                if (_parentMatrixWorld != undefined) {
                    matrixWorld.multiplyMatrices(parent.matrixWorld, matrix);
                }
            }
            
            matrixWorldNeedsUpdate = false; 
			force = true;
        } 
        
        // For frustum culling, update the intersection sphere (if available) to world space
        if (self[$ "isMesh"]) {
            var geometry = self[$ "geometry"];
            if (geometry != undefined) {
                var boundingSphere = geometry[$ "boundingSphere"];
                if (boundingSphere != undefined) {
                    __intersectionSphere.copy(boundingSphere).applyMatrix4(matrixWorld);
                }
            }
        }
        
        for (var i = 0, len = array_length(children); i < len; i++) {
            children[i].updateMatrixWorld(force);
        }
        
        return self;
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
        gml_pragma("forceinline");
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
        gml_pragma("forceinline");
        position.set(x, y, z);
        return self;    
    }
    
    // Translate an object by distance along an axis in object space. The axis is assumed to be normalized.
    function translateOnAxis(axis, distance) {
        gml_pragma("forceinline");
        var v = axis.clone().applyQuaternion(rotation);
        position.add(v.multiplyScalar(distance));
        return self;
    }
    
    function translate(x, y, z) {
        gml_pragma("forceinline");
        position.add(new UeVector3(x, y, z));
        return self;    
    }
    
    function translateX(value) {
        gml_pragma("forceinline");
        position.x += value;
        return self;
    }

    function translateY(value) {
        position.y += value;
        return self;
    }

    function translateZ(value) {
        gml_pragma("forceinline");
        position.z += value;
        return self;
    }

    // --- Rotation methods ---
    function lookAtVec(target) {
        gml_pragma("forceinline");
        var m = global.UE_DUMMY_MATRIX4;
        m.lookAt(position, target, up);
        rotation.setFromRotationMatrix(m);
        return self;     
    }
    
    function lookAt(x, y, z) {
        gml_pragma("forceinline");
        return lookAtVec(new UeVector3(x, y, z));
    }
    
    function setRotation(x, y, z) {
        gml_pragma("forceinline");
        rotation.setFromEuler(x, y, z);
        return self;
    }
    
    // Calls setFromRotationMatrix(m) on the rotation's quaternion
    // Assumes the upper 3x3 of m is a pure rotation matrix (i.e. unscaled).
    function setRotationFromMatrix(mat) {
        gml_pragma("forceinline");
        rotation.setFromRotationMatrix(mat);
        return self;
    }
    
    // Copy the given quaternion into the rotation.
    function setRotationFromQuaternion(quat) {
        gml_pragma("forceinline");
        rotation.copy(quat);
        return self;
    }
    
    function rotate(x, y, z) {
        gml_pragma("forceinline");
        rotation.multiply(new UeQuaternion(x, y, z));
        return self;
    }
    
    // Rotates the object around x axis in local space. value in degrees
    function rotateX(value) {
        gml_pragma("forceinline");
        rotation.rotateX(value);
        return self;
    }

    // Rotates the object around y axis in local space. value in degrees
    function rotateY(value) {
        gml_pragma("forceinline");
        rotation.rotateY(value);
        return self;
    }

    // Rotates the object around z axis in local space. value in degrees
    function rotateZ(value) {
        gml_pragma("forceinline");
        rotation.rotateZ(value);
        return self;
    }
    
    // Rotate an object along an axis in object space. The axis is assumed to be normalized
    function rotateOnAxis(axis, angle) {
        gml_pragma("forceinline");
        var q = new UeQuaternion();
        q.setFromAxisAngle(axis, angle);
        rotation.multiply(q);
        return self;
    }
    
    // Rotate an object along an axis in world space. The axis is assumed to be normalized.
    // Assumes no rotated parent.
    function rotateOnWorldAxis(axis, angle) {
        gml_pragma("forceinline");
        var q = new UeQuaternion();
        q.setFromAxisAngle(axis, angle);
        rotation.premultiply(q);
        return self;
    }

    // --- Scaling methods ---
    function setScale(x, y, z) {
        gml_pragma("forceinline");
        scale.set(x, y, z);
        return self;
    }
    
    function scaleX(value) {
        gml_pragma("forceinline");
        scale.x += value;
        return self;
    }

    function scaleY(value) {
        gml_pragma("forceinline");
        scale.y += value;
        return self;
    }

    function scaleZ(value) {
        gml_pragma("forceinline");
        scale.z += value;
        return self;
    }
    
    // Applies the matrix transform to the object and updates the object's position, rotation and scale.
    function applyMatrix4(mat4) {
        gml_pragma("forceinline");
        matrix.multiply(mat4);
        matrix.decompose(position, rotation, scale);
        return self;
    }
    
    // Applies the rotation represented by the quaternion to the object.
    function applyQuaternion(quat) {
        gml_pragma("forceinline");
        rotation.multiply(quat);
        return self;
    }
    
    // Returns a vector representing the position of the object in world space.
    function getWorldPosition(target) {
        return target.setFromMatrixPosition(matrixWorld);
    }
    
    // Returns a quaternion representing the rotation of the object in world space.
    function getWorldQuaternion(target) {
        gml_pragma("forceinline");
        matrixWorld.decompose(global.UE_DUMMY_VECTOR3, target, global.UE_DUMMY_VECTOR3);
        return target;
    }
    
    // Returns a vector of the scaling factors applied to the object for each axis in world space.
    function getWorldScale(target) {
        gml_pragma("forceinline");
        matrixWorld.decompose(global.UE_DUMMY_VECTOR3, global.UE_DUMMY_QUATERNION, target);
        return target;
    }
    
    // Returns a vector representing the direction of object's positive Y axis in world space.
    function getWorldDirection(target = undefined) {
        gml_pragma("forceinline");
        if (target == undefined) target = new UeVector3();
        return target.copy(up.clone().transformDirection(matrixWorld));
    }
    
    // Converts the vector from this object's local space to world space.
    function localToWorld(vec) {
        gml_pragma("forceinline");
        return vec.applyMatrix4(matrixWorld);
    }
    
    // Converts the vector from world space to this object's local space.
    function worldToLocal(vec) {
        gml_pragma("forceinline");
        return vec.applyMatrix4(matrixWorld.clone().invert());
    }
}
