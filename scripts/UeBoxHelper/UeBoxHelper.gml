function UeBoxHelper(object = undefined, color = c_yellow, data = {}): UeLineSegments(undefined, undefined, data) constructor {
    self.object = object;
    self.color = color;
    self.material = new UeLineBasicMaterial({ color });
    self.box = box3_create();
    self.needsUpdate = true;
    self.name = data[$ "name"] ?? "UeBoxHelper";
    self.matrixAutoUpdate = data[$ "matrixAutoUpdate"] ?? false;

    function update() {
      gml_pragma("forceinline");
      if (self.object == undefined) return;

      var _computedBox = box3_set_from_object(global.UE_BOX3_TEMP0, self.object);
      
      if (box3_equals(self.box, _computedBox) && self.geometry.vb != undefined) return;
      box3_copy(self.box, _computedBox);

      var minX = _computedBox[0], minY = _computedBox[1], minZ = _computedBox[2];
      var maxX = _computedBox[3], maxY = _computedBox[4], maxZ = _computedBox[5];
      
      // Dispose the old geometry and create a new one if needed
      if (geometry != undefined) {
          geometry.dispose();
      } 
      
      self.geometry.position = [
        // Back face  
        minX, minY, minZ,  maxX, minY, minZ,
        maxX, minY, minZ,  maxX, maxY, minZ,
        maxX, maxY, minZ,  minX, maxY, minZ,
        minX, maxY, minZ,  minX, minY, minZ,
        
        // Front face
        minX, minY, maxZ,  maxX, minY, maxZ,
        maxX, minY, maxZ,  maxX, maxY, maxZ,
        maxX, maxY, maxZ,  minX, maxY, maxZ,
        minX, maxY, maxZ,  minX, minY, maxZ,
        
        // Side edges
        minX, minY, minZ,  minX, minY, maxZ,
        maxX, minY, minZ,  maxX, minY, maxZ,
        maxX, maxY, minZ,  maxX, maxY, maxZ,
        minX, maxY, minZ,  minX, maxY, maxZ
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
        box3_make_empty(self.box);
        self.object = undefined;
        self.needsUpdate = false;
    }
    
    self.update();
}
