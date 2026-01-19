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

    var _pos = [], _norm = [], _tang = [], _uvs = [], _colArr = [];

    // Base triangles
    var baseTris = [ [v2, v1, v0], [v0, v3, v2] ];
    var uvBase = [ [1, 1], [1, 0], [0, 0],  [0, 0], [0, 1], [1, 1] ];

    for (var i = 0; i < 2; i++) {
        var tri = baseTris[i];
        for (var j = 0; j < 3; j++) {
            var p = tri[j], uv = uvBase[i * 3 + j];
            array_push(_pos, p[0], p[1], p[2]);
            array_push(_norm, 0, 0, -1);
            array_push(_tang, 1, 0, 0, -1.0);
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
        
        var ab = global.UE_VEC3_TEMP0;
        var ac = global.UE_VEC3_TEMP1;
        vec3_sub_vectors(ab, b, a);
        vec3_sub_vectors(ac, c, a);
        var n = global.UE_VEC3_TEMP2;
        vec3_cross_vectors(n, ac, ab);
        vec3_normalize(n);

        // Calculate tangent for this side face
        // Tangent is along (a-b) direction which is horizontal
        var tx = a[0] - b[0];
        var ty = a[1] - b[1];
        var tz = a[2] - b[2];
        var tLen = sqrt(tx*tx + ty*ty + tz*tz);
        if (tLen > 0) { tx /= tLen; ty /= tLen; tz /= tLen; }
        else { tx = 1; ty = 0; tz = 0; }

        for (var j = 0; j < 3; j++) {
            var p = tri[j], uv = uvSide[j];
            array_push(_pos, p[0], p[1], p[2]);
            array_push(_norm, n[0], n[1], n[2]);
            array_push(_tang, tx, ty, tz, 1.0);
            array_push(_uvs, uv[0], uv[1]);
            array_push(_colArr, _color, _alpha);
        }
    }
    
    self.position = _pos;
    self.normal = _norm;
    self.tangent = _tang;
    self.uv = _uvs;
    self.color = _colArr;

    // Bone data (empty for static geometry)
    var vcount = array_length(_pos) / 3;
    self.boneIndices = array_create(vcount * 4, 0);
    self.boneWeights = array_create(vcount * 4, 0);

    build();
}
