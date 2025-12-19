function UePyramidGeometry(data = {}): UeGeometry(data) constructor {
    var _base   = data[$ "base"]   ?? 100;
    var _height = data[$ "height"] ?? 100;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    var h = _height;
    var base = _base * 0.5;

    // Corner points
    var v0 = [-base, -base, 0];
    var v1 = [ base, -base, 0];
    var v2 = [ base,  base, 0];
    var v3 = [-base,  base, 0];
    var top = [0, 0, h];

    var _pos = [], _norm = [], _uvs = [], _colArr = [];

    // Base triangles
    var baseTris = [ [v2, v1, v0], [v0, v3, v2] ];
    var uvBase = [ [1, 1], [1, 0], [0, 0],  [0, 0], [0, 1], [1, 1] ];

    for (var i = 0; i < 2; i++) {
        var tri = baseTris[i];
        for (var j = 0; j < 3; j++) {
            var p = tri[j], uv = uvBase[i * 3 + j];
            array_push(_pos, p[0], p[1], p[2]);
            array_push(_norm, 0, 0, -1);
            array_push(_uvs, uv[0], uv[1]);
            array_push(_colArr, _color, _alpha);
        }
    }

    // Side triangles
    var sideTris = [ [v1, v0, top], [v2, v1, top], [v3, v2, top], [v0, v3, top] ];
    var uvSide = [ [1, 0], [0, 0], [0.5, 1] ];

    for (var i = 0; i < 4; i++) {
        var tri = sideTris[i];
        var a = tri[0], b = tri[1], c = tri[2];
        var ab = new UeVector3(b[0] - a[0], b[1] - a[1], b[2] - a[2]);
        var ac = new UeVector3(c[0] - a[0], c[1] - a[1], c[2] - a[2]);
        var n = ac.cross(ab).normalize();

        for (var j = 0; j < 3; j++) {
            var p = tri[j], uv = uvSide[j];
            array_push(_pos, p[0], p[1], p[2]);
            array_push(_norm, n.x, n.y, n.z);
            array_push(_uvs, uv[0], uv[1]);
            array_push(_colArr, _color, _alpha);
        }
    }
    
    self.position = _pos;
    self.normal = _norm;
    self.uv = _uvs;
    self.color = _colArr;
    build();
}
