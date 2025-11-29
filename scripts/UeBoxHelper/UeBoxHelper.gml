function UeBoxHelper(object = undefined, color = c_yellow, data = {}): UeLineSegments(undefined, undefined, data) constructor {
    self.object = object;
    self.color = color;
    self.material = new UeLineBasicMaterial({ color });
    self.box = new UeBox3();
    self.needsUpdate = true;
    self.name = data[$ "name"] ?? "UeBoxHelper";
    self.matrixAutoUpdate = data[$ "matrixAutoUpdate"] ?? false;

    function update() {
        gml_pragma("forceinline");
        if (self.object == undefined) return;

        var _computedBox = global.UE_DUMMY_BOX.setFromObject(self.object);
        
        if (self.box.equals(_computedBox) && self.geometry.vb != undefined) return;
        self.box.copy(_computedBox);

        var _min = _computedBox.sizeMin;
        var _max = _computedBox.sizeMax;
        
        // Dispose the old box and create a new one
        if (geometry != undefined) {
            geometry.dispose();
        } 
        
        self.geometry.vertices = [
            // Back face
            { x: _min.x, y: _min.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 0, v: 0, color: c_white, alpha: 1 }, // 0 → 1
            { x: _max.x, y: _min.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 1, v: 0, color: c_white, alpha: 1 },
            
            { x: _max.x, y: _min.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 1, v: 0, color: c_white, alpha: 1 }, // 1 → 2
            { x: _max.x, y: _max.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 1, v: 1, color: c_white, alpha: 1 },
            
            { x: _max.x, y: _max.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 1, v: 1, color: c_white, alpha: 1 }, // 2 → 3
            { x: _min.x, y: _max.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 0, v: 1, color: c_white, alpha: 1 },
            
            { x: _min.x, y: _max.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 0, v: 1, color: c_white, alpha: 1 }, // 3 → 0
            { x: _min.x, y: _min.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 0, v: 0, color: c_white, alpha: 1 },
        
            // Front face
            { x: _min.x, y: _min.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 0, v: 0, color: c_white, alpha: 1 }, // 4 → 5
            { x: _max.x, y: _min.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 1, v: 0, color: c_white, alpha: 1 },
        
            { x: _max.x, y: _min.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 1, v: 0, color: c_white, alpha: 1 }, // 5 → 6
            { x: _max.x, y: _max.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 1, v: 1, color: c_white, alpha: 1 },
        
            { x: _max.x, y: _max.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 1, v: 1, color: c_white, alpha: 1 }, // 6 → 7
            { x: _min.x, y: _max.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 0, v: 1, color: c_white, alpha: 1 },
        
            { x: _min.x, y: _max.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 0, v: 1, color: c_white, alpha: 1 }, // 7 → 4
            { x: _min.x, y: _min.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 0, v: 0, color: c_white, alpha: 1 },
        
            // Side edges
            { x: _min.x, y: _min.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 0, v: 0, color: c_white, alpha: 1 }, // 0 → 4
            { x: _min.x, y: _min.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 0, v: 0, color: c_white, alpha: 1 },
        
            { x: _max.x, y: _min.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 1, v: 0, color: c_white, alpha: 1 }, // 1 → 5
            { x: _max.x, y: _min.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 1, v: 0, color: c_white, alpha: 1 },
        
            { x: _max.x, y: _max.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 1, v: 1, color: c_white, alpha: 1 }, // 2 → 6
            { x: _max.x, y: _max.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 1, v: 1, color: c_white, alpha: 1 },
        
            { x: _min.x, y: _max.y, z: _min.z, nx: 0, ny: 0, nz: 0, u: 0, v: 1, color: c_white, alpha: 1 }, // 3 → 7
            { x: _min.x, y: _max.y, z: _max.z, nx: 0, ny: 0, nz: 0, u: 0, v: 1, color: c_white, alpha: 1 },
        ];

        self.geometry.build();
        self.needsUpdate = false;        
    }
    
    function setFromObject(object) {
        gml_pragma("forceinline");
        self.object = object;
        self.needsUpdate = true;
        self.update();
    }

    function dispose() {
        gml_pragma("forceinline");
        self.geometry.dispose();
        self.box.makeEmpty();
        self.object = undefined;
        self.needsUpdate = false;
    }
    
    self.update();
}
