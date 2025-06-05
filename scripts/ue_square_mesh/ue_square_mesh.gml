function SquareMesh(data = {}): Mesh(data) constructor {
    var _width  = data[$ "width"]  ?? 100;
    var _depth  = data[$ "depth"]  ?? 100;
    var _rows   = data[$ "rows"]   ?? 10; 
    var _cols   = data[$ "cols"]   ?? 10;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    var dx = _width / _cols;
    var dz = _depth / _rows;

    var vertices = [];

    for (var z = 0; z < _rows; z++) {
        for (var xx = 0; xx < _cols; xx++) {
            var x0 = xx * dx - _width * 0.5;
            var z0 = z * dz - _depth * 0.5;
            var x1 = (xx + 1) * dx - _width * 0.5;
            var z1 = (z + 1) * dz - _depth * 0.5;

            var tri = [
                [x0, 0, z0], [x1, 0, z0], [x1, 0, z1],
                [x1, 0, z1], [x0, 0, z1], [x0, 0, z0]
            ];

            for (var i = 0; i < 6; i++) {
                var p = tri[i];
                var u = (p[0] + _width * 0.5) / _width;
                var v = (p[2] + _depth * 0.5) / _depth;

                array_push(vertices, {
                    x: p[0],
                    y: p[1],
                    z: p[2],
                    nx: 0,
                    ny: 1,
                    nz: 0,
                    u: u,
                    v: v,
                    color: _color,
                    alpha: _alpha,
                    custom: {}
                });
            }
        }
    }

    geometry = new Geometry({ vertices }).freeze();
}
