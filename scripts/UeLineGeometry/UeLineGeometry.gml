function UeLineGeometry(data = {}): UeGeometry(data) constructor {
    self.__color = data[$ "color"] ?? c_white;          // Default line color
    self.__alpha = data[$ "alpha"] ?? 1;                // Default line alpha
    self.format = global.UE_VFORMAT_PC;

    /// Populates the geometry with 3D positions. Array must be multiple of 3 (x,y,z)
    function setPositions(array) {
        gml_pragma("forceinline");
        self.position = array;
        
        // Initialize other attributes if needed
        var count = array_length(array) / 3;
        
        var col = array_create(count * 2);
        for (var i = 0; i < count; i++) {
            col[i * 2] = self.__color;
            col[i * 2 + 1] = self.__alpha;
        }
        self.color = col;
        
        build();
        return self;
    }

    /// Populates the geometry with RGB colors. One color per vertex (r,g,b)
    function setColors(colors) {
        gml_pragma("forceinline");
        var count = array_length(colors) / 3;
        var col = array_create(count * 2);
        for (var i = 0; i < count; i++) {
            col[i * 2] = make_color_rgb(colors[i * 3], colors[i * 3 + 1], colors[i * 3 + 2]);
            col[i * 2 + 1] = self.__alpha;
        }
        self.color = col;
        build();
        return self;
    }

    /// Populates the geometry from a list of UeVector3 or UeVector2 points
    function setFromPoints(points) {
        gml_pragma("forceinline");
        var num = array_length(points);
        var pos = array_create(num * 3);
        var col = array_create(num * 2);
        
        for (var i = 0; i < num; i++) {
            var p = points[i];
            pos[i * 3] = p.x;
            pos[i * 3 + 1] = p.y;
            pos[i * 3 + 2] = p[$ "z"] ?? 0;
            
            col[i * 2] = self.__color;
            col[i * 2 + 1] = self.__alpha;
        }
        
        self.position = pos;
        self.color = col;
        
        build();
        return self;
    }

    /// Extracts vertices from a UeLine instance (assumes no index buffer)
    function fromLine(line) {
        gml_pragma("forceinline");
        if (!line.isLine) return self;

        self.position = variable_clone(line.geometry.position);
        self.color = line.geometry.color ? variable_clone(line.geometry.color) : undefined;
        self.index = line.geometry.index ? variable_clone(line.geometry.index) : undefined;
        
        build();
        return self;
    }
}
