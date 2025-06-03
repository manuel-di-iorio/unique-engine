function TreeTopMesh(data = {}): Mesh(data) constructor {
    var _radius = data[$ "radius"] ?? 40;
    var _lats   = data[$ "lats"] ?? 8;
    var _lons   = data[$ "lons"] ?? 12;

    var vertices = [];
    var normals  = [];
    var uvs      = [];
    var colors   = [];

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

            // First triangle
            array_push(vertices, p1[0]*_radius, p1[1]*_radius, p1[2]*_radius);
            array_push(vertices, p2[0]*_radius, p2[1]*_radius, p2[2]*_radius);
            array_push(vertices, p3[0]*_radius, p3[1]*_radius, p3[2]*_radius);

            // Second triangle
            array_push(vertices, p3[0]*_radius, p3[1]*_radius, p3[2]*_radius);
            array_push(vertices, p4[0]*_radius, p4[1]*_radius, p4[2]*_radius);
            array_push(vertices, p1[0]*_radius, p1[1]*_radius, p1[2]*_radius);

            // Normals (unit vectors from center)
            for (var i = 0; i < 6; i++) {
                var px = [p1, p2, p3, p3, p4, p1][i];
                array_push(normals, px[0], px[1], px[2]);
                array_push(uvs, 0.5, 0.5); // optional: spherical UV mapping
                //array_push(colors, 0.1, 0.6, 0.1, 1); // green
            }
        }
    }

    geometry = new Geometry({ vertices, normals, uvs, color: c_green }).freeze();
}
