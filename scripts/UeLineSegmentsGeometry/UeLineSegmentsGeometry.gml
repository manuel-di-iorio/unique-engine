function UeLineSegmentsGeometry(data = {}): UeGeometry(data) constructor {
    self.format = global.UE_VFORMAT_PC;

    // Set default color and alpha
    self.__defColor = data[$ "color"] ?? c_white;
    self.__defAlpha = data[$ "alpha"] ?? 1;

    /// Populates this geometry using any mesh (will extract every pair of vertices)
    function fromMesh(mesh) {
        gml_pragma("forceinline");
        var geo = mesh.geometry;
        
        self.position = variable_clone(geo.position);
        self.color = geo.color ? variable_clone(geo.color) : undefined;
        self.index = geo.index ? variable_clone(geo.index) : undefined;

        build();
        return self;
    }
    
    // Set a list of segment positions (flat array: [x1,y1,z1,x2,y2,z2,...])
    function setPositions(arr, _build = true) {
        gml_pragma("forceinline");
        self.position = arr;
        
        var count = array_length(arr) / 3;
        var colLen = count * 2;
        
        // Only initialize colors if they don't exist or size is wrong
        // We don't overwrite if they are already the correct size (might be set by setColors)
        if (self.color == undefined || array_length(self.color) != colLen) {
            var colArr = array_create(colLen);
            var _defCol = self.__defColor;
            var _defAlpha = self.__defAlpha;
            for (var i = 0; i < count; i++) {
                var i2 = i * 2;
                colArr[i2] = _defCol;
                colArr[i2 + 1] = _defAlpha;
            }
            self.color = colArr;
        }

        if (_build) build();
        return self;
    }

    // Set per-vertex colors: flat array [r1,g1,b1,r2,g2,b2,...]
    function setColors(arr, _build = true) {
        gml_pragma("forceinline");
        var count = min(array_length(self.position) / 3, array_length(arr) / 3);
        var colLen = count * 2;
        
        // Reuse existing array if possible to avoid allocation
        if (self.color == undefined || array_length(self.color) != colLen) {
            self.color = array_create(colLen);
        }
        
        var colArr = self.color;
        var _defAlpha = self.__defAlpha;
        for (var i = 0; i < count; i++) {
            var i3 = i * 3;
            var i2 = i * 2;
            colArr[i2] = make_color_rgb(arr[i3], arr[i3 + 1], arr[i3 + 2]);
            colArr[i2 + 1] = _defAlpha;
        }
        
        if (_build) build();
        return self;
    }

    /**
     * Sets raw colors directly (flat array [color, alpha, color, alpha, ...])
     * This avoids RGB -> GM color conversion and array allocations if the array is reused.
     */
    function setRawColors(arr, _build = true) {
        gml_pragma("forceinline");
        self.color = arr;
        if (_build) build();
        return self;
    }

    /**
     * Set both positions and colors at once to avoid double build calls.
     */
    function setPositionsAndColors(posArr, colArr, _build = true) {
        gml_pragma("forceinline");
        self.position = posArr;
        
        var count = min(array_length(posArr) / 3, array_length(colArr) / 3);
        var colLen = count * 2;
        
        if (self.color == undefined || array_length(self.color) != colLen) {
            self.color = array_create(colLen);
        }
        
        var _color = self.color;
        var _defAlpha = self.__defAlpha;
        
        for (var i = 0; i < count; i++) {
            var i3 = i * 3;
            var i2 = i * 2;
            _color[i2] = make_color_rgb(colArr[i3], colArr[i3 + 1], colArr[i3 + 2]);
            _color[i2 + 1] = _defAlpha;
        }
        
        if (_build) build();
        return self;
    }
}
