function UeConeGeometry(
    radius = 1,
    height = 1,
    radialSegments = 32,
    data = {}
) : UeGeometry(data) constructor {
    var color = data[$ "color"] ?? c_white;
    var alpha = data[$ "alpha"] ?? 1;
    var halfHeight = height * 0.5;
    var angleStep = 2 * pi / radialSegments;

    // Punta del cono verso X+
    var tip = { x: halfHeight, y: 0, z: 0 };

    var slope = radius / height;
    vertices = [];

    // Lati del cono
    for (var i = 0; i < radialSegments; i++) {
        var a = i * angleStep;
        var b = ((i + 1) % radialSegments) * angleStep;

        var y0 = cos(a) * radius;
        var z0 = sin(a) * radius;
        var y1 = cos(b) * radius;
        var z1 = sin(b) * radius;

        // Base in x = -halfHeight
        var normal0 = new UeVector3(slope, y0, z0).normalize();
        var normal1 = new UeVector3(slope, y1, z1).normalize();

        var v0 = { x: -halfHeight, y: y0, z: z0, nx: normal0.x, ny: normal0.y, nz: normal0.z, u: 0, v: 0, color, alpha };
        var v1 = { x: -halfHeight, y: y1, z: z1, nx: normal1.x, ny: normal1.y, nz: normal1.z, u: 1, v: 0, color, alpha };
        var vtip = { x: tip.x, y: tip.y, z: tip.z, nx: 1, ny: 0, nz: 0, u: 0.5, v: 1, color, alpha };

        // CCW
        array_push(vertices, v1, v0, vtip);
    }

    // Base del cono (in x = -halfHeight)
    for (var i = 0; i < radialSegments; i++) {
        var a = i * angleStep;
        var b = ((i + 1) % radialSegments) * angleStep;

        var y0 = cos(a) * radius;
        var z0 = sin(a) * radius;
        var y1 = cos(b) * radius;
        var z1 = sin(b) * radius;

        var center = { x: -halfHeight, y: 0, z: 0, nx: -1, ny: 0, nz: 0, u: 0.5, v: 0.5, color, alpha };
        var v0 = { x: -halfHeight, y: y0, z: z0, nx: -1, ny: 0, nz: 0, u: 0, v: 0, color, alpha };
        var v1 = { x: -halfHeight, y: y1, z: z1, nx: -1, ny: 0, nz: 0, u: 1, v: 0, color, alpha };

        // CCW guardando da +X verso -X
        array_push(vertices, center, v0, v1);
    }

    build();
}
