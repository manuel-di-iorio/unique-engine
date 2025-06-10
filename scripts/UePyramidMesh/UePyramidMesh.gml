function PyramidMesh(data = {}): Mesh(data) constructor {
    var _base   = data[$ "base"]   ?? 100;
    var _height = data[$ "height"] ?? 100;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    var h = _height;
    var b = _base * 0.5;

    var vertices = [];

    // Base points
    var v0 = [-b, -b, 0]; // bottom-left
    var v1 = [ b, -b, 0]; // bottom-right
    var v2 = [ b,  b, 0]; // top-right
    var v3 = [-b,  b, 0]; // top-left

    var top = [0, 0, h];

    // Invertito ordine per winding CCW guardando dal basso (normale verso -Z)
    var baseTris = [
        [v2, v1, v0], // triangle 1
        [v0, v3, v2]  // triangle 2
    ];

    var uvBase = [
        [1, 1], [1, 0], [0, 0],
        [0, 0], [0, 1], [1, 1]
    ];

    // Base (normali = -Z)
    for (var i = 0, len = array_length(baseTris); i < len; i++) {
        var tri = baseTris[i];
        for (var j = 0; j < 3; j++) {
            var p = tri[j];
            var uv = uvBase[i * 3 + j];
            array_push(vertices, {
                x: p[0],
                y: p[1],
                z: p[2],
                nx: 0,
                ny: 0,
                nz: -1,
                u: uv[0],
                v: uv[1],
                color: _color,
                alpha: _alpha,
                custom: {}
            });
        }
    }

    // Side triangles con ordine invertito per winding CCW (normale verso l'esterno)
    var sideTris = [
        [v1, v0, top],
        [v2, v1, top],
        [v3, v2, top],
        [v0, v3, top]
    ];

    var uvSide = [
        [1, 0], [0, 0], [0.5, 1]
    ];

    for (var i = 0, len = array_length(sideTris); i < len; i++) {
        var tri = sideTris[i];
        var a = tri[0], b = tri[1], c = tri[2];
        var ab = new Vec3(b[0] - a[0], b[1] - a[1], b[2] - a[2]);
        var ac = new Vec3(c[0] - a[0], c[1] - a[1], c[2] - a[2]);
        var normal = ac.cross(ab).normalize();

        for (var j = 0; j < 3; j++) {
            var p = tri[j];
            var uv = uvSide[j];
            array_push(vertices, {
                x: p[0],
                y: p[1],
                z: p[2],
                nx: normal.x,
                ny: normal.y,
                nz: normal.z,
                u: uv[0],
                v: uv[1],
                color: _color,
                alpha: _alpha,
                custom: {}
            });
        }
    }

    geometry = new BufferGeometry({ vertices }).freeze();
}
