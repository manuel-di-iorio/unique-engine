function UeGridHelper(
    size = 10,
    divisions = 10,
    colorCenterLine = #444444,
    colorGrid = #888888
): UeLineSegments() constructor {
    
    var halfSize = size * 0.5;
    var step = size / divisions;
    var center = floor(divisions * 0.5);

    var positions = [];
    var colors = [];

    for (var i = 0; i <= divisions; i++) {
        var k = -halfSize + i * step;
    
        var isCenter = i == center;
        var lineColor = isCenter ? colorCenterLine : colorGrid;
        var colR = color_get_red(lineColor);
        var colG = color_get_green(lineColor);
        var colB = color_get_blue(lineColor);
    
        // Vertical line (asse Y, da basso a alto)
        array_push(positions, k, -halfSize, 0, k, halfSize, 0);
        array_push(colors, 
            colR, colG, colB, 
            colR, colG, colB
        );
    
        // Orizzontale (asse X)
        array_push(positions, -halfSize, k, 0, halfSize, k, 0);
        array_push(colors,
            colR, colG, colB,
            colR, colG, colB
        );
    }

    geometry = new UeLineSegmentsGeometry();
    geometry.setPositions(positions);
    geometry.setColors(colors);
    
    material.side = cull_noculling;
    
    matrixAutoUpdate = false;
    frustumCulled = false;

}
