function UeBoxHelper(object = undefined, color = c_yellow, data = {}): UeLineSegments(undefined, undefined, data) constructor {
    self.object = object;
    self.color = color;
    self.material = new UeLineBasicMaterial({ color });
    
    update = function() {
        gml_pragma("forceinline");
        var box = new UeBox3().setFromObject(self.object);
        var _min = box.sizeMin;
        var _max = box.sizeMax;
        
        // Dispose the old box and create a new one
        if (geometry != undefined) {
            geometry.dispose();
        } 

        var _width = _max.x - _min.x;
        var _height = _max.y - _min.y;
        var _depth = _max.z - _min.z;
        
        geometry.vertices = [
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

        geometry.build();
        
        // Copy the object transform into the bounding box    
        rotation.copy(object.rotation);
        scale.copy(object.scale);
        position.copy(object.position);
        
    }
    
    function setFromObject(object) {
        gml_pragma("forceinline");
        self.object = object;
        update();
    }
    
    if (object != undefined) update();
}