function UeConeGeometry(radius = 1, height = 1, radialSegments = 32, data = {}) : UeGeometry(data) constructor {
    var color = data[$ "color"] ?? c_white;
    var alpha = data[$ "alpha"] ?? 1;
    var halfHeight = height * 0.5;
    var angleStep = 2 * pi / radialSegments;

    // Tip of the cone towards X+
    var tipX = halfHeight, tipY = 0, tipZ = 0;

    var slope = radius / height;
    
    var _pos = [];
    var _norm = [];
    var _tang = [];
    var _uvs = [];
    var _col = [];

    // Sides
    for (var i = 0; i < radialSegments; i++) {
        var a = i * angleStep;
        var b = ((i + 1) % radialSegments) * angleStep;

        var y0 = cos(a) * radius;
        var z0 = sin(a) * radius;
        var y1 = cos(b) * radius;
        var z1 = sin(b) * radius;

        var n0 = vec3_set(global.UE_VEC3_TEMP0, slope, y0, z0);
        vec3_normalize(n0);
        var n1 = vec3_set(global.UE_VEC3_TEMP1, slope, y1, z1);
        vec3_normalize(n1);

        // Tangent calculation for sides
        var t0x = 0, t0y = sin(a), t0z = -cos(a);
        var t1x = 0, t1y = sin(b), t1z = -cos(b);
        var w = -1.0;

        // Vertex 1
        array_push(_pos, -halfHeight, y1, z1);
        array_push(_norm, n1[0], n1[1], n1[2]);
        array_push(_tang, t1x, t1y, t1z, w);
        array_push(_uvs, 1, 0);
        array_push(_col, color, alpha);

        // Vertex 0
        array_push(_pos, -halfHeight, y0, z0);
        array_push(_norm, n0[0], n0[1], n0[2]);
        array_push(_tang, t0x, t0y, t0z, w);
        array_push(_uvs, 0, 0);
        array_push(_col, color, alpha);

        // Tip
        array_push(_pos, tipX, tipY, tipZ);
        array_push(_norm, 1, 0, 0);
        array_push(_tang, 0, 1, 0, w);
        array_push(_uvs, 0.5, 1);
        array_push(_col, color, alpha);
    }

    // Base
    for (var i = 0; i < radialSegments; i++) {
        var a = i * angleStep;
        var b = ((i + 1) % radialSegments) * angleStep;

        var y0 = cos(a) * radius;
        var z0 = sin(a) * radius;
        var y1 = cos(b) * radius;
        var z1 = sin(b) * radius;

        var tx = 0, ty = 1, tz = 0, w = -1.0;

        // Center
        array_push(_pos, -halfHeight, 0, 0);
        array_push(_norm, -1, 0, 0);
        array_push(_tang, tx, ty, tz, w);
        array_push(_uvs, 0.5, 0.5);
        array_push(_col, color, alpha);

        // Vertex 0
        array_push(_pos, -halfHeight, y0, z0);
        array_push(_norm, -1, 0, 0);
        array_push(_tang, tx, ty, tz, w);
        array_push(_uvs, 0, 0);
        array_push(_col, color, alpha);

        // Vertex 1
        array_push(_pos, -halfHeight, y1, z1);
        array_push(_norm, -1, 0, 0);
        array_push(_tang, tx, ty, tz, w);
        array_push(_uvs, 1, 0);
        array_push(_col, color, alpha);
    }

    self.position = _pos;
    self.normal = _norm;
    self.tangent = _tang;
    self.uv = _uvs;
    self.color = _col;

    build();
}
