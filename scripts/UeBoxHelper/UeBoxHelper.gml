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
        
        // Dispose the old geometry and create a new one if needed
        if (geometry != undefined) {
            geometry.dispose();
        } 
        
        self.geometry.position = [
            // Back face
            _min.x, _min.y, _min.z,  _max.x, _min.y, _min.z,
            _max.x, _min.y, _min.z,  _max.x, _max.y, _min.z,
            _max.x, _max.y, _min.z,  _min.x, _max.y, _min.z,
            _min.x, _max.y, _min.z,  _min.x, _min.y, _min.z,
        
            // Front face
            _min.x, _min.y, _max.z,  _max.x, _min.y, _max.z,
            _max.x, _min.y, _max.z,  _max.x, _max.y, _max.z,
            _max.x, _max.y, _max.z,  _min.x, _max.y, _max.z,
            _min.x, _max.y, _max.z,  _min.x, _min.y, _max.z,
        
            // Side edges
            _min.x, _min.y, _min.z,  _min.x, _min.y, _max.z,
            _max.x, _min.y, _min.z,  _max.x, _min.y, _max.z,
            _max.x, _max.y, _min.z,  _max.x, _max.y, _max.z,
            _min.x, _max.y, _min.z,  _min.x, _max.y, _max.z
        ];

        // Initialize other attributes with default values
        var count = array_length(self.geometry.position) / 3;
        self.geometry.normal = array_create(count * 3, 0);
        self.geometry.uv = array_create(count * 2, 0);
        
        var colArr = array_create(count * 2);
        for (var i = 0; i < count; i++) {
            colArr[i * 2] = c_white;
            colArr[i * 2 + 1] = 1;
        }
        self.geometry.color = colArr;

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
