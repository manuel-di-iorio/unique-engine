function UeAxesHelper(size = 1): UeLineSegments() constructor {
    var colorX = c_red;
    var colorY = c_lime;
    var colorZ = c_blue;
    
    material.transparent = true;
    material.depthTest = false;
    material.forceSinglePass = true;
    material.side = cull_noculling;
    matrixAutoUpdate = false;

    // Line segment positions for axes: [x1, y1, z1, x2, y2, z2]
    var positions = [
        0, 0, 0, -size, 0, 0,   // X axis
        0, 0, 0, 0, -size, 0,   // Y axis
        0, 0, 0, 0, 0, size    // Z axis
    ];

    // Colors: RGB triplets for each point (2 points per axis)
    var colors = [
        255, 0, 0,  255, 0, 0,   // X: red
        0, 0, 255,  0, 0, 255,   // Y: blue
        0, 255, 0,  0, 255, 0    // Z: green
    ];

    var geom = new UeLineSegmentsGeometry();
    geom.setPositions(positions);
    geom.setColors(colors);
    self.geometry = geom;

    /// Sets custom axis colors
    function setColors(xAxisColor, yAxisColor, zAxisColor) {
        gml_pragma("forceinline");
        var xr = color_get_red(xAxisColor), xg = color_get_green(xAxisColor), xb = color_get_blue(xAxisColor);
        var yr = color_get_red(yAxisColor), yg = color_get_green(yAxisColor), yb = color_get_blue(yAxisColor);
        var zr = color_get_red(zAxisColor), zg = color_get_green(zAxisColor), zb = color_get_blue(zAxisColor);
        
        self.geometry.setColors([
            xr, xg, xb,
            xr, xg, xb, 
            yr,yg,yb,
            yr,yg,yb, 
            zr,zg,zb,
            zr,zg,zb, 
        ]);
        return self;
    }

    /// Disposes the geometry
    function dispose() {
        gml_pragma("forceinline");
        self.geometry.dispose();
        return self;
    }
}
