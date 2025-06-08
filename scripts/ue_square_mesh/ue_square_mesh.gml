function SquareMesh(data = {}): Mesh(data) constructor {
    var _width  = data[$ "width"]  ?? 100;
    var _height  = data[$ "height"]  ?? 100;
    var _rows   = data[$ "rows"]   ?? 10; 
    var _cols   = data[$ "cols"]   ?? 10;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    var dx = _width / _cols;
    var dz = _height / _rows;

    var vertices = [];

    for (var yy = 0; yy < _rows; yy++) {
        for (var xx = 0; xx < _cols; xx++) {
            var x0 = xx * dx - _width * 0.5;
            var y0 = yy * dz - _height * 0.5;
            var x1 = (xx + 1) * dx - _width * 0.5;
            var y1 = (yy + 1) * dz - _height * 0.5;
    
            var tri = [
                [x0, y0, 0], [x1, y1, 0], [x1, y0, 0],
                [x1, y1, 0], [x0, y0, 0], [x0, y1, 0]
            ];
    
            for (var i = 0; i < 6; i++) {
                var p = tri[i];
                var u = (p[0] + _width * 0.5) / _width;
                var v = (p[1] + _height * 0.5) / _height;
    
                array_push(vertices, {
                    x: p[0],
                    y: p[1],
                    z: 0,
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
