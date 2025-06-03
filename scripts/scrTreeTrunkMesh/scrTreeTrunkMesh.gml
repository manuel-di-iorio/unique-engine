function TreeTrunkMesh(data = {}): Mesh(data) constructor {
    var _width  = data[$ "width"]  ?? 20;
    var _height = data[$ "height"] ?? 50;
    var _depth  = data[$ "depth"]  ?? 20;

    var hw = _width / 2;
    var hh = _height / 2;
    var hd = _depth / 2;

    var vertices = [
        // Front
        -hw, -hh,  hd,  -hw,  hh,  hd,   hw,  hh,  hd,
         hw,  hh,  hd,   hw, -hh,  hd,  -hw, -hh,  hd,

        // Back
        -hw, -hh, -hd,   hw, -hh, -hd,   hw,  hh, -hd,
         hw,  hh, -hd,  -hw,  hh, -hd,  -hw, -hh, -hd,

        // Top
        -hw,  hh, -hd,   hw,  hh, -hd,   hw,  hh,  hd,
         hw,  hh,  hd,  -hw,  hh,  hd,  -hw,  hh, -hd,

        // Bottom
        -hw, -hh, -hd,  -hw, -hh,  hd,   hw, -hh,  hd,
         hw, -hh,  hd,   hw, -hh, -hd,  -hw, -hh, -hd,

        // Right
         hw, -hh, -hd,   hw, -hh,  hd,   hw,  hh,  hd,
         hw,  hh,  hd,   hw,  hh, -hd,   hw, -hh, -hd,

        // Left
        -hw, -hh, -hd,  -hw,  hh, -hd,  -hw,  hh,  hd,
        -hw,  hh,  hd,  -hw, -hh,  hd,  -hw, -hh, -hd,
    ];

    var normals = [];
    var uvs = [];
    var colors = [];

    for (var i = 0; i < 6; i++) {
        var nx = 0, ny = 0, nz = 0;
        switch (i) {
            case 0: nz = 1; break;
            case 1: nz = -1; break;
            case 2: ny = 1; break;
            case 3: ny = -1; break;
            case 4: nx = 1; break;
            case 5: nx = -1; break;
        }
        for (var j = 0; j < 6; j++) {
            array_push(normals, nx, ny, nz);
        }
        array_push(uvs, 0,1,  0,0,  1,0,  1,0,  1,1,  0,1);
        for (var j = 0; j < 6; j++) {
            //array_push(colors, 0.55, 0.27, 0.07, 1); // brown
        }
    }

    geometry = new Geometry({ vertices, normals, uvs, color: c_maroon }).freeze();
}