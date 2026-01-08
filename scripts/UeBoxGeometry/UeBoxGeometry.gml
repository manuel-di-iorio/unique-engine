function UeBoxGeometry(width = 1, height = 1, depth = 1, data = {}): UeGeometry(data) constructor {
    var _width  = width ?? 1;
    var _height = height ?? 1;
    var _depth  = depth ?? 1;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    var hw = _width * 0.5;
    var hh = _depth * 0.5;
    var hd = _height * 0.5;

    // Direct flat arrays for attributes
    var _position = [];
    var _normal = [];
    var _uv = [];
    var _colorArray = [];
    var _tangent = [];

    var faces = [
        [ 0,  0,  1,  1,  0,  0,  0, -1,  0, [ // Front (Z+)
            [-hw,-hd, hh, 0,1], [-hw, hd, hh, 0,0], [ hw, hd, hh, 1,0],
            [ hw, hd, hh, 1,0], [ hw,-hd, hh, 1,1], [-hw,-hd, hh, 0,1]
        ]],
        [ 0,  0, -1, -1,  0,  0,  0, -1,  0, [ // Back (Z-)
            [-hw,-hd,-hh, 1,1], [ hw,-hd,-hh, 0,1], [ hw, hd,-hh, 0,0],
            [ hw, hd,-hh, 0,0], [-hw, hd,-hh, 1,0], [-hw,-hd,-hh, 1,1]
        ]],
        [ 0,  1,  0,  1,  0,  0,  0,  0,  1, [ // Top (Y+)
            [-hw, hd,-hh, 0,1], [ hw, hd,-hh, 1,1], [ hw, hd, hh, 1,0],
            [ hw, hd, hh, 1,0], [-hw, hd, hh, 0,0], [-hw, hd,-hh, 0,1]
        ]],
        [ 0, -1,  0,  1,  0,  0,  0,  0, -1, [ // Bottom (Y-)
            [-hw,-hd,-hh, 0,0], [-hw,-hd, hh, 0,1], [ hw,-hd, hh, 1,1],
            [ hw,-hd, hh, 1,1], [ hw,-hd,-hh, 1,0], [-hw,-hd,-hh, 0,0]
        ]],
        [ 1,  0,  0,  0,  0,  1,  0, -1,  0, [ // Right (X+)
            [ hw,-hd,-hh, 0,1], [ hw,-hd, hh, 1,1], [ hw, hd, hh, 1,0],
            [ hw, hd, hh, 1,0], [ hw, hd,-hh, 0,0], [ hw,-hd,-hh, 0,1]
        ]],
        [-1,  0,  0,  0,  0, -1,  0, -1,  0, [ // Left (X-)
            [-hw,-hd,-hh, 1,1], [-hw, hd,-hh, 1,0], [-hw, hd, hh, 0,0],
            [-hw, hd, hh, 0,0], [-hw,-hd, hh, 0,1], [-hw,-hd,-hh, 1,1]
        ]]
    ];

    for (var f = 0; f < array_length(faces); f++) {
        var nx = faces[f][0];
        var ny = faces[f][1];
        var nz = faces[f][2];
        var tx = faces[f][3];
        var ty = faces[f][4];
        var tz = faces[f][5];
        var bx = faces[f][6];
        var by = faces[f][7];
        var bz = faces[f][8];
        var verts = faces[f][9];

        // Calculate handedness (w)
        // w = (dot(cross(N, T), B) < 0) ? -1.0 : 1.0
        var cx = ny * tz - nz * ty;
        var cy = nz * tx - nx * tz;
        var cz = nx * ty - ny * tx;
        var dot = cx * bx + cy * by + cz * bz;
        var w = (dot < 0) ? -1.0 : 1.0;
    
        for (var i = 0; i < array_length(verts); i++) {
            var v = verts[i];
            array_push(_position, v[0], v[1], v[2]);
            array_push(_normal, nx, ny, nz);
            array_push(_uv, v[3], v[4]);
            array_push(_tangent, tx, ty, tz, w);
            array_push(_colorArray, _color, _alpha);
            
        }
    }
    
    self.position = _position;
    self.normal = _normal;
    self.uv = _uv;
    self.color = _colorArray;
    self.tangent = _tangent;
    
    build();
}
