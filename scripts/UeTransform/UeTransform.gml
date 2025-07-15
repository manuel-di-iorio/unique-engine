function UeTransform(data = {}) constructor {
    // Local transform components
    position = data[$ "position"] ?? new UeVector3(data[$ "x"] ?? 0, data[$ "y"] ?? 0, data[$ "z"] ?? 0);
    rotation = data[$ "rotation"] ?? new UeQuaternion(data[$ "rx"] ?? 0, data[$ "ry"] ?? 0, data[$ "rz"] ?? 0);
    scale    = data[$ "scale"]    ?? new UeVector3(data[$ "sx"] ?? 1, data[$ "sy"] ?? 1, data[$ "sz"] ?? 1);
    //up       = new UeVector3(0, 1, 0);
    up       = new UeVector3(0, 0, -1);

    // Transformation matrices
    matrix = new UeMatrix4();
    matrixWorld = new UeMatrix4();

    // Parent (optional)
    parent = data[$ "parent"] ?? undefined;

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
        matrix.compose(position, rotation, scale);
        matrixWorldNeedsUpdate = true;
        return self;
    }

    /// Update world matrix
    function updateMatrixWorld() {
        matrixWorldNeedsUpdate = false;
           
        // Start with local matrix
        if (parent != undefined && parent.matrixWorld != undefined) {
            matrixWorld = parent.matrixWorld.clone();
            matrixWorld.multiply(matrix);
        } else {
            matrixWorld = matrix.clone();
        }
        
        return self;
    }
    
    /// Update the matrixWorld of parents/children
    /// @todo Needs tests
    function updateWorldMatrix(updateParents = false, updateChildren = false) {
        if (updateParents && parent != undefined) {
            parent.updateWorldMatrix(true, false);
        }
    
        if (matrixNeedsUpdate) {
            updateMatrix();
        }
    
        if (parent != undefined && parent.matrixWorld != undefined) {
            matrixWorld = parent.matrixWorld.clone();
            matrixWorld.multiply(matrix);
        } else {
            matrixWorld = matrix.clone();
        }
    
        matrixWorldNeedsUpdate = false;
    
        if (updateChildren) {
            for (var i = 0, len = array_length(children); i < len; i++) {
                var child = children[i];
                child.matrixWorldNeedsUpdate = true;
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
