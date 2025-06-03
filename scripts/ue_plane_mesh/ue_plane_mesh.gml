function PlaneMesh(data = {}): Mesh(data) constructor {
    var _width  = data[$ "width"] ?? 100;
    var _depth  = data[$ "depth"] ?? 100;
    var _rows   = data[$ "rows"] ?? 10; 
    var _cols   = data[$ "cols"]   ?? 10;
    var _color  = data[$ "color"] ?? c_white;

    var vertices = [];
    var normals  = [];
    var uvs      = [];

    var dx = _width / _cols;
    var dz = _depth / _rows;

    for (var z = 0; z < _rows; z++) {
        for (var xx = 0; xx < _cols; xx++) {
            var x0 = xx * dx - _width * 0.5;
            var z0 = z * dz - _depth * 0.5;
            var x1 = (xx + 1) * dx - _width * 0.5;
            var z1 = (z + 1) * dz - _depth * 0.5;

            // Triangle 1
            array_push(vertices, x0, z0, 0);
            array_push(vertices, x1, z0, 0);
            array_push(vertices, x1, z1, 0);

            // Triangle 2
            array_push(vertices, x1, z1, 0);
            array_push(vertices, x0, z1, 0);
            array_push(vertices, x0, z0, 0);

            for (var i = 0; i < 6; i++) {
                array_push(normals, 0, 1, 0);
                array_push(uvs, 0, 0);
            }
        }
    }

    geometry = new Geometry({ vertices, normals, uvs, color: _color }).freeze();
}