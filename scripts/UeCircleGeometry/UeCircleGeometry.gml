function UeCircleGeometry(radius = 1, data = {}): UeBufferGeometry(data) constructor {
    var _segments = max(3, data[$ "segments"] ?? 32);
    var _color    = data[$ "color"] ?? c_white;
    var _alpha    = data[$ "alpha"] ?? 1;

    for (var i = 0; i < _segments; i++) {
        var angle0 = (i     / _segments) * pi * 2;
        var angle1 = ((i+1) / _segments) * pi * 2;

        var x0 = cos(angle0) * radius;
        var z0 = sin(angle0) * radius;

        var x1 = cos(angle1) * radius;
        var z1 = sin(angle1) * radius;

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
        
        // Vertex: edge 2
        array_push(vertices, {
            x: x1,
            y: z1,
            z: 0,
            nx: 0,
            ny: 1,
            nz: 0,
            u: (x1 / (radius * 2)) + 0.5,
            v: (z1 / (radius * 2)) + 0.5,
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
            u: (x0 / (radius * 2)) + 0.5,
            v: (z0 / (radius * 2)) + 0.5,
            color: _color,
            alpha: _alpha,
            custom: {}
        });
    }

    build();
}
