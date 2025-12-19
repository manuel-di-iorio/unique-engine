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

        var n0 = new UeVector3(slope, y0, z0).normalize();
        var n1 = new UeVector3(slope, y1, z1).normalize();

        // Vertex 1
        array_push(_pos, -halfHeight, y1, z1);
        array_push(_norm, n1.x, n1.y, n1.z);
        array_push(_uvs, 1, 0);
        array_push(_col, color, alpha);

        // Vertex 0
        array_push(_pos, -halfHeight, y0, z0);
        array_push(_norm, n0.x, n0.y, n0.z);
        array_push(_uvs, 0, 0);
        array_push(_col, color, alpha);

        // Tip
        array_push(_pos, tipX, tipY, tipZ);
        array_push(_norm, 1, 0, 0);
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

        // Center
        array_push(_pos, -halfHeight, 0, 0);
        array_push(_norm, -1, 0, 0);
        array_push(_uvs, 0.5, 0.5);
        array_push(_col, color, alpha);

        // Vertex 0
        array_push(_pos, -halfHeight, y0, z0);
        array_push(_norm, -1, 0, 0);
        array_push(_uvs, 0, 0);
        array_push(_col, color, alpha);

        // Vertex 1
        array_push(_pos, -halfHeight, y1, z1);
        array_push(_norm, -1, 0, 0);
        array_push(_uvs, 1, 0);
        array_push(_col, color, alpha);
    }

    self.position = _pos;
    self.normal = _norm;
    self.uv = _uvs;
    self.color = _col;

    build();
}
