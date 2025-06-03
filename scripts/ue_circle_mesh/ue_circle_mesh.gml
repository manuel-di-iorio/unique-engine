function CircleMesh(data = {}): Mesh(data) constructor {
    var _radius   = data[$ "radius"]   ?? 100;
    var _segments = data[$ "segments"] ?? 32;
    var _color    = data[$ "color"]    ?? c_white;

    var vertices = [];
    var normals  = [];
    var uvs      = [];

    for (var i = 0; i < _segments; i++) {
        var angle0 = (i     / _segments) * pi * 2;
        var angle1 = ((i+1) / _segments) * pi * 2;

        var x0 = cos(angle0) * _radius;
        var z0 = sin(angle0) * _radius;

        var x1 = cos(angle1) * _radius;
        var z1 = sin(angle1) * _radius;

        // Center point (0, 0, 0)
        array_push(vertices, 0, 0, 0);
        array_push(normals, 0, 1, 0);
        array_push(uvs, 0.5, 0.5);

        // First edge point
        array_push(vertices, x0, z0, 0);
        array_push(normals, 0, 1, 0);
        array_push(uvs, (x0 / (_radius * 2)) + 0.5, (z0 / (_radius * 2)) + 0.5);

        // Second edge point
        array_push(vertices, x1, z1, 0);
        array_push(normals, 0, 1, 0);
        array_push(uvs, (x1 / (_radius * 2)) + 0.5, (z1 / (_radius * 2)) + 0.5);
    }

    geometry = new Geometry({
        vertices,
        normals,
        uvs,
        color: _color
    }).freeze();
}
