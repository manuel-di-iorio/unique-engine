function UeTransform(_data = {}) constructor {
    // Local transform components
    position = _data[$ "position"] ?? new UeVector3(_data[$ "x"] ?? 0, _data[$ "y"] ?? 0, _data[$ "z"] ?? 0);
    rotation = _data[$ "rotation"] ?? new UeQuaternion(_data[$ "rx"] ?? 0, _data[$ "ry"] ?? 0, _data[$ "rz"] ?? 0);
    scale    = _data[$ "scale"]    ?? new UeVector3(_data[$ "sx"] ?? 1, _data[$ "sy"] ?? 1, _data[$ "sz"] ?? 1);
    up       = new UeVector3(0, 1, 0);

    // Transformation matrices
    matrix = undefined;
    matrixWorld = undefined;

    // Parent (optional)
    parent = _data[$ "parent"] ?? undefined;

    // Matrix update flags
    matrixAutoUpdate = true;             // Automatically update local matrix
    matrixWorldAutoUpdate = true;        // Automatically update world matrix
    matrixNeedsUpdate = false;           // Force update the local matrix for this frame
    matrixWorldNeedsUpdate = false;      // Force update the world matrix for this frame

    function update() {
        var forceUpdateChildren = false;
        if (matrixAutoUpdate && matrixNeedsUpdate) {
            forceUpdateChildren = true;
            updateMatrix();
        }
        
        if (matrixWorldAutoUpdate && matrixWorldNeedsUpdate) {
            forceUpdateChildren = true;
            updateMatrixWorld();
        }
        
        for (var i = 0, len = array_length(children); i < len; i++) {
            var child = children[i];
            if (forceUpdateChildren) child.matrixWorldNeedsUpdate = true;
            child.update();
        }
    };
    
    /// Rebuild local matrix from position/rotation/scale
    function updateMatrix() {
        matrixNeedsUpdate = false;
        matrix = new UeMatrix4().buildByTransform(self);
        matrixWorldNeedsUpdate = true;
        return self;
    }

    /// Update world matrix
    function updateMatrixWorld() {
        matrixWorldNeedsUpdate = false;
           
        // Start with local matrix
        if (parent != undefined && parent.matrixWorld != undefined) {
            matrixWorld = parent.matrixWorld.clone();
            matrixWorld.multiply(matrix.data);
        } else {
            matrixWorld = matrix.clone()
        }
        
        return self;
    }
    
    /// Update the matrixWorld of the children
    function updateWorldMatrix(updateParents = false, updateChildren = false) {
        // @todo
        if (updateParents) {
            show_debug_log("updateParents argument not supported yet")
        }
        
        if (updateChildren) {
            for (var i = 0, len = array_length(children); i < len; i++) {
                children[i].updateMatrixWorld();
            }
        }
    }

    // --- Translation methods ---
    function move(x, y, z) {
        position.set(x, y, z);
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
        var forward = target.sub(position).normalize();
        var right = self.up.cross(forward).normalize();
        var up = forward.cross(right);

        var m = new Mat4([
            right.x, up.x, forward.x, 0,
            right.y, up.y, forward.y, 0,
            right.z, up.z, forward.z, 0,
            0,       0,    0,         1
        ]);
    
        rotation.setFromRotationMatrix(m);
    
        matrixNeedsUpdate = true;
        return self;     
    }
    
    function lookAt(x, y, z) {
        return lookAtVec(new UeVector3(x, y, z));
    }
    
    function rotate(x, y, z) {
        rotation.multiply(new UeQuaternion(x, y, z));
        matrixNeedsUpdate = true;
        return self;
    }
    
    function rotateX(value) {
        rotation.rotateX(value);
        matrixNeedsUpdate = true;
        return self;
    }

    function rotateY(value) {
        rotation.rotateY(value);
        matrixWorldNeedsUpdate = true;
        return self;
    }

    function rotateZ(value) {
        rotation.rotateZ(value);
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

    // Initial matrix build
    updateMatrix();
}
