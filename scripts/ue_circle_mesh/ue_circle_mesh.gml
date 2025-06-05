function CircleMesh(data = {}): Mesh(data) constructor {
    var _radius   = data[$ "radius"]   ?? 100;
    var _segments = data[$ "segments"] ?? 32;
    var _color    = data[$ "color"]    ?? c_white;
    var _alpha    = data[$ "alpha"]    ?? 1;

    var vertices = [];

    for (var i = 0; i < _segments; i++) {
        var angle0 = (i     / _segments) * pi * 2;
        var angle1 = ((i+1) / _segments) * pi * 2;

        var x0 = cos(angle0) * _radius;
        var z0 = sin(angle0) * _radius;

        var x1 = cos(angle1) * _radius;
        var z1 = sin(angle1) * _radius;

        // Vertex: center
        array_push(vertices, {
            x: 0,
            y: 0,
            z: 0,
            nx: 0,
            ny: 1,
            nz: 0,
            u: 0.5,
            v: 0.5,
            color: _color,
            alpha: _alpha,
            custom: {}
        });

        // Vertex: edge 1
        array_push(vertices, {
            x: x0,
            y: z0,
            z: 0,
            nx: 0,
            ny: 1,
            nz: 0,
            u: (x0 / (_radius * 2)) + 0.5,
            v: (z0 / (_radius * 2)) + 0.5,
            color: _color,
            alpha: _alpha,
            custom: {}
        });

        // Vertex: edge 2
        array_push(vertices, {
            x: x1,
            y: z1,
            z: 0,
            nx: 0,
            ny: 1,
            nz: 0,
            u: (x1 / (_radius * 2)) + 0.5,
            v: (z1 / (_radius * 2)) + 0.5,
            color: _color,
            alpha: _alpha,
            custom: {}
        });
    }

    geometry = new Geometry({ vertices }).freeze();
}
