function UeSphereGeometry(_radius = 40, data = {}): UeBufferGeometry(data) constructor {
    var _lats   = data[$ "lats"]   ?? 20;
    var _lons   = data[$ "lons"]   ?? 20;
    var _color  = data[$ "color"]  ?? c_white;
    var _alpha  = data[$ "alpha"]  ?? 1;

    for (var lat = 0; lat < _lats; lat++) {
        var theta1 = pi * (lat / _lats);
        var theta2 = pi * ((lat + 1) / _lats);

        var y1 = cos(theta1);
        var y2 = cos(theta2);

        var r1 = sin(theta1);
        var r2 = sin(theta2);

        for (var lon = 0; lon < _lons; lon++) {
            var phi1 = 2 * pi * (lon / _lons);
            var phi2 = 2 * pi * ((lon + 1) / _lons);

            var x1 = cos(phi1);
            var z1 = sin(phi1);
            var x2 = cos(phi2);
            var z2 = sin(phi2);

            var p1 = [x1 * r1, y1, z1 * r1];
            var p2 = [x2 * r1, y1, z2 * r1];
            var p3 = [x2 * r2, y2, z2 * r2];
            var p4 = [x1 * r2, y2, z1 * r2];

            var points = [p1, p3, p2, p3, p1, p4];

            for (var i = 0; i < 6; i++) {
                var p = points[i];

                var nx = p[0];
                var ny = p[1];
                var nz = p[2];

                // Spherical UV mapping
                var u = 0.5 + arctan2(p[2], p[0]) / (2 * pi);
                var v = 0.5 - dsin(p[1]) / pi;

                array_push(vertices, {
                    x: p[0] * _radius,
                    y: p[1] * _radius,
                    z: p[2] * _radius,
                    nx: nx,
                    ny: ny,
                    nz: nz,
                    u: u,
                    v: v,
                    color: _color,
                    alpha: _alpha,
                    custom: {}
                });
            }
        }
    }
    
    build();
}
