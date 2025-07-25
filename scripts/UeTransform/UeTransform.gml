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
    matrixNeedsUpdate = false;           // Force update the local matrix for this frame
    matrixWorldNeedsUpdate = false;      // Force update the world matrix for this frame
    
    // Internals
    __frustumSphere = undefined;
    
    /// Rebuild local matrix from position/rotation/scale
    function updateMatrix() {
        matrix.compose(position, rotation, scale);
        matrixNeedsUpdate = false;
        matrixWorldNeedsUpdate = true;
        return self;
    }

    // Update local matrix and matrix world, also on children
    // @MissingDoc
    function updateMatrixWorld(frustum, force = false) {
        if (matrixAutoUpdate && matrixNeedsUpdate) {
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
            //var boundingSphere = geometry != undefined ? geometry[$ "boundingSphere"] : undefined
            //if (boundingSphere != undefined) {
                //__frustumSphere = new UeSphere();
                //__frustumSphere.copy(boundingSphere).applyMatrix4(matrixWorld); 
            //}
        }
        
        
        for (var i = 0, len = array_length(children); i < len; i++) {
            children[i].updateMatrixWorld(frustum, force);
        }
        
        return self;
    }
    
    // Optimized in VM:
    //function updateMatrixWorld(frustum, force = false) {
        //if (matrixAutoUpdate && matrixNeedsUpdate) {
            //// matrix.compose(position, quaternion, scale)
            //var x0 = position.x, y0 = position.y, z = position.z;
            //var qx = rotation.x, qy = rotation.y, qz = rotation.z, qw = rotation.w;
            //var sx = scale.x, sy = scale.y, sz = scale.z;
            //
            //var x2 = qx + qx, y2 = qy + qy, z2 = qz + qz;
            //var xx = qx * x2, xy = qx * y2, xz = qx * z2;
            //var yy = qy * y2, yz = qy * z2, zz = qz * z2;
            //var wx = qw * x2, wy = qw * y2, wz = qw * z2;
            //
            //var te = matrix.data;
            //
            //te[0] = (1 - (yy + zz)) * sx;
            //te[1] = (xy + wz) * sx;
            //te[2] = (xz - wy) * sx;
            //te[3] = 0;
            //
            //te[4] = (xy - wz) * sy;
            //te[5] = (1 - (xx + zz)) * sy;
            //te[6] = (yz + wx) * sy;
            //te[7] = 0;
            //
            //te[8] = (xz + wy) * sz;
            //te[9] = (yz - wx) * sz;
            //te[10] = (1 - (xx + yy)) * sz;
            //te[11] = 0;
            //
            //te[12] = x0;
            //te[13] = y0;
            //te[14] = z;
            //te[15] = 1;
            //
            //matrixNeedsUpdate = false;
        //}
        //
        //if (matrixWorldNeedsUpdate || force) {
            //// Calcolo inline della matrixWorld
            //if (parent == undefined) {
                //// Matrix copy
                //var m = matrix.data;
                //var mw = matrixWorld.data;
                //mw[0] = m[0]; mw[1] = m[1]; mw[2] = m[2]; mw[3] = m[3];
                //mw[4] = m[4]; mw[5] = m[5]; mw[6] = m[6]; mw[7] = m[7];
                //mw[8] = m[8]; mw[9] = m[9]; mw[10] = m[10]; mw[11] = m[11];
                //mw[12] = m[12]; mw[13] = m[13]; mw[14] = m[14]; mw[15] = m[15];
            //} else {
                //// multiplyMatrices()
                //var pm = parent.matrixWorld.data;
                //var m = matrix.data;
                //var mw = matrixWorld.data;
                //
                //// Unroll della moltiplicazione 4x4
                //mw[0] = pm[0]*m[0] + pm[4]*m[1] + pm[8]*m[2] + pm[12]*m[3];
                //mw[1] = pm[1]*m[0] + pm[5]*m[1] + pm[9]*m[2] + pm[13]*m[3];
                //mw[2] = pm[2]*m[0] + pm[6]*m[1] + pm[10]*m[2] + pm[14]*m[3];
                //mw[3] = pm[3]*m[0] + pm[7]*m[1] + pm[11]*m[2] + pm[15]*m[3];
                //
                //mw[4] = pm[0]*m[4] + pm[4]*m[5] + pm[8]*m[6] + pm[12]*m[7];
                //mw[5] = pm[1]*m[4] + pm[5]*m[5] + pm[9]*m[6] + pm[13]*m[7];
                //mw[6] = pm[2]*m[4] + pm[6]*m[5] + pm[10]*m[6] + pm[14]*m[7];
                //mw[7] = pm[3]*m[4] + pm[7]*m[5] + pm[11]*m[6] + pm[15]*m[7];
                //
                //mw[8] = pm[0]*m[8] + pm[4]*m[9] + pm[8]*m[10] + pm[12]*m[11];
                //mw[9] = pm[1]*m[8] + pm[5]*m[9] + pm[9]*m[10] + pm[13]*m[11];
                //mw[10] = pm[2]*m[8] + pm[6]*m[9] + pm[10]*m[10] + pm[14]*m[11];
                //mw[11] = pm[3]*m[8] + pm[7]*m[9] + pm[11]*m[10] + pm[15]*m[11];
                //
                //mw[12] = pm[0]*m[12] + pm[4]*m[13] + pm[8]*m[14] + pm[12]*m[15];
                //mw[13] = pm[1]*m[12] + pm[5]*m[13] + pm[9]*m[14] + pm[13]*m[15];
                //mw[14] = pm[2]*m[12] + pm[6]*m[13] + pm[10]*m[14] + pm[14]*m[15];
                //mw[15] = pm[3]*m[12] + pm[7]*m[13] + pm[11]*m[14] + pm[15]*m[15];
            //}
            //
            //matrixWorldNeedsUpdate = false;
            //force = true;
            //
            //// Calcolo bounding sphere inline se presente
            //if (geometry != undefined) {
                //var boundingSphere = geometry[$ "boundingSphere"];
                //if (boundingSphere != undefined) {
                    //// Inline sphere transformation invece di copy + applyMatrix4
                    //var bs = boundingSphere;
                    //var mw = matrixWorld.data;
                    //
                    //// Trasforma il centro della sfera
                    //var cx = bs.center.x;
                    //var cy = bs.center.y; 
                    //var cz = bs.center.z;
                    //
                    //__frustumSphere = global.UE_DUMMY_SPHERE;
                    //__frustumSphere.center.x = mw[0]*cx + mw[4]*cy + mw[8]*cz + mw[12];
                    //__frustumSphere.center.y = mw[1]*cx + mw[5]*cy + mw[9]*cz + mw[13];
                    //__frustumSphere.center.z = mw[2]*cx + mw[6]*cy + mw[10]*cz + mw[14];
                    //
                    //// Calcola il nuovo raggio considerando lo scale
                    //var sx = sqrt(mw[0]*mw[0] + mw[1]*mw[1] + mw[2]*mw[2]);
                    //var sy = sqrt(mw[4]*mw[4] + mw[5]*mw[5] + mw[6]*mw[6]);
                    //var sz = sqrt(mw[8]*mw[8] + mw[9]*mw[9] + mw[10]*mw[10]);
                    //var maxScale = max(sx, max(sy, sz));
                    //
                    //__frustumSphere.radius = bs.radius * maxScale;
                //}
            //}
        //}
        //
        //// Ricorsione sui children (questa rimane uguale)
        //var len = array_length(children);
        //for (var i = 0; i < len; i++) {
            //children[i].updateMatrixWorld(frustum, force);
        //}
        //
        //return self;
    //}
    
    /**
     * Update the matrixWorld of parents/children
     * 
     * This method computes the `matrixWorld` property, which represents the object's transform 
     * in world space, by combining its local `matrix` with the parent's `matrixWorld`.
     * 
     * Notes:
     *  - If `matrixNeedsUpdate` is true, `updateMatrix()` will be called before computing `matrixWorld`.
     *  - `matrixWorldNeedsUpdate` is reset to false after the update.
     *  - This method should be called if the object or its hierarchy has changed (e.g., after transformations or re-parenting).
     */
    /// @untested
    function updateWorldMatrix(updateParents = false, updateChildren = false) {
        if (updateParents && parent != undefined) {
            parent.updateWorldMatrix(true, false);
        }
        
        if (matrixAutoUpdate && matrixNeedsUpdate) updateMatrix();
    
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
        matrixNeedsUpdate = true;
        return self;    
    }
    
    // Translate an object by distance along an axis in object space. The axis is assumed to be normalized.
    // @untested @MissingDoc
    function translateOnAxis(axis, distance) {
        var v = axis.clone().applyQuaternion(rotation);
        position.add(v.multiplyScalar(distance));
        matrixNeedsUpdate = true;
        return self;
    }
    
    function translate(x, y, z) {
        position.add(new UeVector3(x, y, z));
        matrixNeedsUpdate = true;
        return self;    
    }
    
    function translateX(value) {
        position.x += value;
        matrixNeedsUpdate = true;
        return self;
    }

    function translateY(value) {
        position.y += value;
        matrixNeedsUpdate = true;
        return self;
    }

    function translateZ(value) {
        position.z += value;
        matrixNeedsUpdate = true;
        return self;
    }

    // --- Rotation methods ---
    function lookAtVec(target) {
        var m = new UeMatrix4();
        m.lookAt(position, target, up);
        rotation.setFromRotationMatrix(m);
        matrixNeedsUpdate = true;
        return self;     
    }
    
    function lookAt(x, y, z) {
        return lookAtVec(new UeVector3(x, y, z));
    }
    
    function setRotation(x, y, z) {
        rotation.setFromEuler(x, y, z);
        matrixNeedsUpdate = true;
        return self;
    }
    
    // Calls setFromRotationMatrix(m) on the rotation's quaternion
    // Assumes the upper 3x3 of m is a pure rotation matrix (i.e. unscaled).
    // @untested @MissingDoc
    function setRotationFromMatrix(mat) {
        rotation.setFromRotationMatrix(mat);
        matrixNeedsUpdate = true;
        return self;
    }
    
    // Copy the given quaternion into the rotation.
    // @untested @MissingDoc
    function setRotationFromQuaternion(quat) {
        rotation.copy(quat);
        matrixNeedsUpdate = true;
        return self;
    }
    
    function rotate(x, y, z) {
        rotation.multiply(new UeQuaternion(x, y, z));
        matrixNeedsUpdate = true;
        return self;
    }
    
    // Rotates the object around x axis in local space. value in degrees
    function rotateX(value) {
        rotation.rotateX(value);
        matrixNeedsUpdate = true;
        return self;
    }

    // Rotates the object around y axis in local space. value in degrees
    function rotateY(value) {
        rotation.rotateY(value);
        matrixWorldNeedsUpdate = true;
        return self;
    }

    // Rotates the object around z axis in local space. value in degrees
    function rotateZ(value) {
        rotation.rotateZ(value);
        matrixNeedsUpdate = true;
        return self;
    }
    
    // Rotate an object along an axis in object space. The axis is assumed to be normalized
    // @untested @MissingDoc
    function rotateOnAxis(axis, angle) {
        var q = new UeQuaternion();
        q.setFromAxisAngle(axis, angle);
        rotation.multiply(q);
        matrixNeedsUpdate = true;
        return self;
    }
    
    // Rotate an object along an axis in world space. The axis is assumed to be normalized.
    // Assumes no rotated parent.
    // @untested @MissingDoc
    function rotateOnWorldAxis(axis, angle) {
        var q = new UeQuaternion();
        q.setFromAxisAngle(axis, angle);
        rotation.premultiply(q);
        matrixNeedsUpdate = true;
        return self;
    }

    // --- Scaling methods ---
    function setScale(x, y, z) {
        scale.set(x, y, z);
        matrixNeedsUpdate = true;
        return self;
    }
    
    function scaleX(value) {
        scale.x += value;
        matrixNeedsUpdate = true;
        return self;
    }

    function scaleY(value) {
        scale.y += value;
        matrixNeedsUpdate = true;
        return self;
    }

    function scaleZ(value) {
        scale.z += value;
        matrixNeedsUpdate = true;
        return self;
    }
    
    // Applies the matrix transform to the object and updates the object's position, rotation and scale.
    // @untested @MissingDoc
    function applyMatrix4(mat4) {
        matrix.multiply(mat4);
        matrix.decompose(position, rotation, scale);
        matrixNeedsUpdate = true;
        return self;
    }
    
    // Applies the rotation represented by the quaternion to the object.
    // @untested @MissingDoc
    function applyQuaternion(quat) {
        rotation.multiply(quat);
        matrixNeedsUpdate = true;
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
    
    // Returns a vector representing the direction of object's positive z(Z or Y?)-axis in world space.
    // @untested @MissingDoc
    // 0,0,1 (forward?) è corretto o sarebbe meglio 0,1,0 in base alla proiezione 0,0,-1? da testare.
    function getWorldDirection(target) {
        var v = new UeVector3(0, 0, 1);
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

    // Initial matrix build
    updateMatrix();
}
