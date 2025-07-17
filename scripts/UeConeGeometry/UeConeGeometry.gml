function UeConeGeometry(
    radius = 1,
    height = 1,
    radialSegments = 32,
    data = {}
) : UeBufferGeometry(data) constructor {
    var color = data[$ "color"] ?? c_white;
    var alpha = data[$ "alpha"] ?? 1;
    var halfHeight = height * 0.5;
    var angleStep = 2 * pi / radialSegments;

    // Punta del cono verso Z+
    var tip = { x: 0, y: 0, z: halfHeight };

    var slope = radius / height;
    vertices = [];

    // Lati del cono
    for (var i = 0; i < radialSegments; i++) {
        var a = i * angleStep;
        var b = ((i + 1) % radialSegments) * angleStep;

        var x0 = cos(a) * radius;
        var y0 = sin(a) * radius;
        var x1 = cos(b) * radius;
        var y1 = sin(b) * radius;

        // Base in z = -halfHeight
        var normal0 = new UeVector3(x0, y0, slope).normalize();
        var normal1 = new UeVector3(x1, y1, slope).normalize();

        var v0 = { x: x0, y: y0, z: -halfHeight, nx: normal0.x, ny: normal0.y, nz: normal0.z, u: 0, v: 0, color, alpha };
        var v1 = { x: x1, y: y1, z: -halfHeight, nx: normal1.x, ny: normal1.y, nz: normal1.z, u: 1, v: 0, color, alpha };
        var vtip = { x: tip.x, y: tip.y, z: tip.z, nx: 0, ny: 0, nz: 1, u: 0.5, v: 1, color, alpha };

        array_push(vertices, v1, v0, vtip);
    }

    // Base del cono (in z = -halfHeight)
    for (var i = 0; i < radialSegments; i++) {
        var a = i * angleStep;
        var b = ((i + 1) % radialSegments) * angleStep;

        var x0 = cos(a) * radius;
        var y0 = sin(a) * radius;
        var x1 = cos(b) * radius;
        var y1 = sin(b) * radius;

        var center = { x: 0, y: 0, z: -halfHeight, nx: 0, ny: 0, nz: -1, u: 0.5, v: 0.5, color, alpha };
        var v0 = { x: x0, y: y0, z: -halfHeight, nx: 0, ny: 0, nz: -1, u: 0, v: 0, color, alpha };
        var v1 = { x: x1, y: y1, z: -halfHeight, nx: 0, ny: 0, nz: -1, u: 1, v: 0, color, alpha };

        array_push(vertices, center, v0, v1); // CCW
    }

    build();
}
