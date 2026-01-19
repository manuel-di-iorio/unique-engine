function UeCircleGeometry(radius = 1, data = {}): UeGeometry(data) constructor {
    var _segments = max(3, data[$ "segments"] ?? 32);
    var _color    = data[$ "color"] ?? c_white;
    var _alpha    = data[$ "alpha"] ?? 1;

    var _pos = [];
    var _norm = [];
    var _tang = [];
    var _uvs = [];
    var _col = [];

    for (var i = 0; i < _segments; i++) {
        var angle0 = (i     / _segments) * pi * 2;
        var angle1 = ((i+1) / _segments) * pi * 2;

        var x0 = cos(angle0) * radius;
        var z0 = sin(angle0) * radius;

        var x1 = cos(angle1) * radius;
        var z1 = sin(angle1) * radius;

        var tx = 1, ty = 0, tz = 0, w = 1.0;

        // Center
        array_push(_pos, 0, 0, 0);
        array_push(_norm, 0, 0, 1);
        array_push(_uvs, 0.5, 0.5);
        array_push(_tang, tx, ty, tz, w);
        array_push(_col, _color, _alpha);
        
        // Edge 2
        array_push(_pos, x1, z1, 0);
        array_push(_norm, 0, 0, 1);
        array_push(_uvs, (x1 / (radius * 2)) + 0.5, (z1 / (radius * 2)) + 0.5);
        array_push(_tang, tx, ty, tz, w);
        array_push(_col, _color, _alpha);

        // Edge 1
        array_push(_pos, x0, z0, 0);
        array_push(_norm, 0, 0, 1);
        array_push(_uvs, (x0 / (radius * 2)) + 0.5, (z0 / (radius * 2)) + 0.5);
        array_push(_tang, tx, ty, tz, w);
        array_push(_col, _color, _alpha);
    }

    self.position = _pos;
    self.normal = _norm;
    self.tangent = _tang;
    self.uv = _uvs;
    self.color = _col;

    // Bone data (empty for static geometry)
    var vcount = array_length(_pos) / 3;
    self.boneIndices = array_create(vcount * 4, 0);
    self.boneWeights = array_create(vcount * 4, 0);

    build();
}
