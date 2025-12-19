function UeLineSegmentsGeometry(data = {}): UeGeometry(data) constructor {
    // Set default color and alpha
    self.__defColor = data[$ "color"] ?? c_white;
    self.__defAlpha = data[$ "alpha"] ?? 1;

    /// Populates this geometry using any mesh (will extract every pair of vertices)
    function fromMesh(mesh) {
        gml_pragma("forceinline");
        var geo = mesh.geometry;
        
        self.position = variable_clone(geo.position);
        self.normal = geo.normal ? variable_clone(geo.normal) : undefined;
        self.uv = geo.uv ? variable_clone(geo.uv) : undefined;
        self.color = geo.color ? variable_clone(geo.color) : undefined;
        self.index = geo.index ? variable_clone(geo.index) : undefined;

        build();
        return self;
    }
    
    // Set a list of segment positions (flat array: [x1,y1,z1,x2,y2,z2,...])
    function setPositions(arr) {
        gml_pragma("forceinline");
        self.position = arr;
        
        var count = array_length(arr) / 3;
        self.normal = array_create(count * 3, 0);
        self.uv = array_create(count * 2, 0);
        
        var colArr = array_create(count * 2);
        for (var i = 0; i < count; i++) {
            colArr[i * 2] = self.__defColor;
            colArr[i * 2 + 1] = self.__defAlpha;
        }
        self.color = colArr;

        build();
        return self;
    }

    // Set per-vertex colors: flat array [r1,g1,b1,r2,g2,b2,...]
    function setColors(arr) {
        var count = min(array_length(self.position) / 3, array_length(arr) / 3);
        var colArr = array_create(count * 2);
        for (var i = 0; i < count; i++) {
            colArr[i * 2] = make_color_rgb(arr[i * 3], arr[i * 3 + 1], arr[i * 3 + 2]);
            colArr[i * 2 + 1] = self.__defAlpha;
        }
        self.color = colArr;
        build();
        return self;
    }
}
