function UeBoxGeometry(width = 1, height = 1, depth = 1, data = {}): UeBufferGeometry(data) constructor {
    var _width  = width ?? 1;
    var _height = height ?? 1;
    var _depth  = depth ?? 1;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    var hw = _width * 0.5;
    var hh = _depth * 0.5;
    var hd = _height * 0.5;

    var faces = [
        [ 0,  0,  1, [ // Front (Z+) - X and Y vary, Z is constant at +hh
            [-hw,-hd, hh, 0,1], [-hw, hd, hh, 0,0], [ hw, hd, hh, 1,0],
            [ hw, hd, hh, 1,0], [ hw,-hd, hh, 1,1], [-hw,-hd, hh, 0,1]
        ]],
        [ 0,  0, -1, [ // Back (Z-) - X and Y vary, Z is constant at -hh
            [-hw,-hd,-hh, 1,1], [ hw,-hd,-hh, 0,1], [ hw, hd,-hh, 0,0],
            [ hw, hd,-hh, 0,0], [-hw, hd,-hh, 1,0], [-hw,-hd,-hh, 1,1]
        ]],
        [ 0,  1,  0, [ // Top (Y+) - X and Z vary, Y is constant at +hd
            [-hw, hd,-hh, 0,1], [ hw, hd,-hh, 1,1], [ hw, hd, hh, 1,0],
            [ hw, hd, hh, 1,0], [-hw, hd, hh, 0,0], [-hw, hd,-hh, 0,1]
        ]],
        [ 0, -1,  0, [ // Bottom (Y-) - X and Z vary, Y is constant at -hd
            [-hw,-hd,-hh, 0,0], [-hw,-hd, hh, 0,1], [ hw,-hd, hh, 1,1],
            [ hw,-hd, hh, 1,1], [ hw,-hd,-hh, 1,0], [-hw,-hd,-hh, 0,0]
        ]],
        [ 1,  0,  0, [ // Right (X+) - Y and Z vary, X is constant at +hw
            [ hw,-hd,-hh, 0,1], [ hw,-hd, hh, 1,1], [ hw, hd, hh, 1,0],
            [ hw, hd, hh, 1,0], [ hw, hd,-hh, 0,0], [ hw,-hd,-hh, 0,1]
        ]],
        [-1,  0,  0, [ // Left (X-) - Y and Z vary, X is constant at -hw
            [-hw,-hd,-hh, 1,1], [-hw, hd,-hh, 1,0], [-hw, hd, hh, 0,0],
            [-hw, hd, hh, 0,0], [-hw,-hd, hh, 0,1], [-hw,-hd,-hh, 1,1]
        ]]
    ];


    for (var f = 0; f < array_length(faces); f++) {
        var nx = faces[f][0];
        var ny = faces[f][1];
        var nz = faces[f][2];
        var verts = faces[f][3];
    
        for (var i = 0; i < array_length(verts); i++) {
            var v = verts[i];
            array_push(vertices, {
                x: v[0],
                y: v[1],
                z: v[2],
                nx: nx,
                ny: ny,
                nz: nz,
                u: v[3],
                v: v[4],
                color: _color,
                alpha: _alpha
            });
        }
    }
    
    build();
}
