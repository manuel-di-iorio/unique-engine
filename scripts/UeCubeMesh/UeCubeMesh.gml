function CubeMesh(data = {}): Mesh(data) constructor {
    var _width  = data[$ "width"]  ?? 50;
    var _height = data[$ "height"] ?? 50;
    var _depth  = data[$ "depth"]  ?? 50;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    var hw = _width  * 0.5;
    var hh = _height * 0.5;
    var hd = _depth  * 0.5;

    var faces = [
        // Front
        [ [-hw,-hh, hd], [0,0,1], [0,1] ],
        [ [-hw, hh, hd], [0,0,1], [0,0] ],
        [ [ hw, hh, hd], [0,0,1], [1,0] ],
        [ [ hw, hh, hd], [0,0,1], [1,0] ],
        [ [ hw,-hh, hd], [0,0,1], [1,1] ],
        [ [-hw,-hh, hd], [0,0,1], [0,1] ],

        // Back
        [ [-hw,-hh,-hd], [0,0,-1], [1,1] ],
        [ [ hw,-hh,-hd], [0,0,-1], [0,1] ],
        [ [ hw, hh,-hd], [0,0,-1], [0,0] ],
        [ [ hw, hh,-hd], [0,0,-1], [0,0] ],
        [ [-hw, hh,-hd], [0,0,-1], [1,0] ],
        [ [-hw,-hh,-hd], [0,0,-1], [1,1] ],

        // Top
        [ [-hw, hh,-hd], [0,1,0], [0,1] ],
        [ [ hw, hh,-hd], [0,1,0], [1,1] ],
        [ [ hw, hh, hd], [0,1,0], [1,0] ],
        [ [ hw, hh, hd], [0,1,0], [1,0] ],
        [ [-hw, hh, hd], [0,1,0], [0,0] ],
        [ [-hw, hh,-hd], [0,1,0], [0,1] ],

        // Bottom
        [ [-hw,-hh,-hd], [0,-1,0], [0,0] ],
        [ [-hw,-hh, hd], [0,-1,0], [0,1] ],
        [ [ hw,-hh, hd], [0,-1,0], [1,1] ],
        [ [ hw,-hh, hd], [0,-1,0], [1,1] ],
        [ [ hw,-hh,-hd], [0,-1,0], [1,0] ],
        [ [-hw,-hh,-hd], [0,-1,0], [0,0] ],

        // Right
        [ [ hw,-hh,-hd], [1,0,0], [0,1] ],
        [ [ hw,-hh, hd], [1,0,0], [1,1] ],
        [ [ hw, hh, hd], [1,0,0], [1,0] ],
        [ [ hw, hh, hd], [1,0,0], [1,0] ],
        [ [ hw, hh,-hd], [1,0,0], [0,0] ],
        [ [ hw,-hh,-hd], [1,0,0], [0,1] ],

        // Left
        [ [-hw,-hh,-hd], [-1,0,0], [1,1] ],
        [ [-hw, hh,-hd], [-1,0,0], [1,0] ],
        [ [-hw, hh, hd], [-1,0,0], [0,0] ],
        [ [-hw, hh, hd], [-1,0,0], [0,0] ],
        [ [-hw,-hh, hd], [-1,0,0], [0,1] ],
        [ [-hw,-hh,-hd], [-1,0,0], [1,1] ]
    ];

    var vertices = [];

    for (var i = 0; i < array_length(faces); i++) {
        var p  = faces[i][0];
        var n  = faces[i][1];
        var uv = faces[i][2];

        array_push(vertices, {
            x: p[0],
            y: p[1],
            z: p[2],
            nx: n[0],
            ny: n[1],
            nz: n[2],
            u: uv[0],
            v: uv[1],
            color: _color,
            alpha: _alpha
        });
    }

    geometry = new BufferGeometry({ vertices }).freeze();
}
