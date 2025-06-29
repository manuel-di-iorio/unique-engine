function UeBoxGeometry(width = 1, height = 1, depth = 1, data = {}): UeBufferGeometry(data) constructor {
    var _width  = width ?? data[$ "width"] ?? 1;
    var _height = height ?? data[$ "height"] ?? 1;
    var _depth  = depth ?? data[$ "depth"]  ?? 1;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    var hw = _width * 0.5;
    var hh = _height * 0.5;
    var hd = _depth * 0.5;

    var faces = [
        [ 0,  1,  0, [ // Front (Y+)
            [-hw,-hd, hh, 0,1], [-hw, hd, hh, 0,0], [ hw, hd, hh, 1,0],
            [ hw, hd, hh, 1,0], [ hw,-hd, hh, 1,1], [-hw,-hd, hh, 0,1]
        ]],
        [ 0, -1,  0, [ // Back (Y-)
            [-hw,-hd,-hh, 1,1], [ hw,-hd,-hh, 0,1], [ hw, hd,-hh, 0,0],
            [ hw, hd,-hh, 0,0], [-hw, hd,-hh, 1,0], [-hw,-hd,-hh, 1,1]
        ]],
        [ 0,  0,  1, [ // Top (Z+)
            [-hw, hd,-hh, 0,1], [ hw, hd,-hh, 1,1], [ hw, hd, hh, 1,0],
            [ hw, hd, hh, 1,0], [-hw, hd, hh, 0,0], [-hw, hd,-hh, 0,1]
        ]],
        [ 0,  0, -1, [ // Bottom (Z-)
            [-hw,-hd,-hh, 0,0], [-hw,-hd, hh, 0,1], [ hw,-hd, hh, 1,1],
            [ hw,-hd, hh, 1,1], [ hw,-hd,-hh, 1,0], [-hw,-hd,-hh, 0,0]
        ]],
        [ 1,  0,  0, [ // Right (X+)
            [ hw,-hd,-hh, 0,1], [ hw,-hd, hh, 1,1], [ hw, hd, hh, 1,0],
            [ hw, hd, hh, 1,0], [ hw, hd,-hh, 0,0], [ hw,-hd,-hh, 0,1]
        ]],
        [-1,  0,  0, [ // Left (X-)
            [-hw,-hd,-hh, 1,1], [-hw, hd,-hh, 1,0], [-hw, hd, hh, 0,0],
            [-hw, hd, hh, 0,0], [-hw,-hd, hh, 0,1], [-hw,-hd,-hh, 1,1]
        ]]
    ];


    for (var f = 0; f < array_length(faces); f++) {
        var nx = faces[f][0];
        var ny = -faces[f][1];
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
