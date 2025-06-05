function ParallelepipedMesh(data = {}): Mesh(data) constructor {
    var _width  = data[$ "width"]  ?? 20;
    var _height = data[$ "height"] ?? 50;
    var _depth  = data[$ "depth"]  ?? 20;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    var hw = _width  * 0.5;
    var hh = _height * 0.5;
    var hd = _depth  * 0.5;

    var vertices = [];

    // Face definition: [normal_x, normal_y, normal_z, [6 vertices with [x, y, z, u, v]]]
    var faces = [
        [ 0,  0,  1, [ // Front
            [-hw,-hh, hd, 0,1], [-hw, hh, hd, 0,0], [ hw, hh, hd, 1,0],
            [ hw, hh, hd, 1,0], [ hw,-hh, hd, 1,1], [-hw,-hh, hd, 0,1]
        ]],
        [ 0,  0, -1, [ // Back
            [-hw,-hh,-hd, 1,1], [ hw,-hh,-hd, 0,1], [ hw, hh,-hd, 0,0],
            [ hw, hh,-hd, 0,0], [-hw, hh,-hd, 1,0], [-hw,-hh,-hd, 1,1]
        ]],
        [ 0,  1,  0, [ // Top
            [-hw, hh,-hd, 0,1], [ hw, hh,-hd, 1,1], [ hw, hh, hd, 1,0],
            [ hw, hh, hd, 1,0], [-hw, hh, hd, 0,0], [-hw, hh,-hd, 0,1]
        ]],
        [ 0, -1,  0, [ // Bottom
            [-hw,-hh,-hd, 0,0], [-hw,-hh, hd, 0,1], [ hw,-hh, hd, 1,1],
            [ hw,-hh, hd, 1,1], [ hw,-hh,-hd, 1,0], [-hw,-hh,-hd, 0,0]
        ]],
        [ 1,  0,  0, [ // Right
            [ hw,-hh,-hd, 0,1], [ hw,-hh, hd, 1,1], [ hw, hh, hd, 1,0],
            [ hw, hh, hd, 1,0], [ hw, hh,-hd, 0,0], [ hw,-hh,-hd, 0,1]
        ]],
        [-1,  0,  0, [ // Left
            [-hw,-hh,-hd, 1,1], [-hw, hh,-hd, 1,0], [-hw, hh, hd, 0,0],
            [-hw, hh, hd, 0,0], [-hw,-hh, hd, 0,1], [-hw,-hh,-hd, 1,1]
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

    geometry = new Geometry({ vertices }).freeze();
}
