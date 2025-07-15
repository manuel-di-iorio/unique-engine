function UeConeGeometry(radius = 1, height = 1, radialSegments = 32, data = {}) : UeBufferGeometry(data) constructor {
    var color = data[$ "color"] ?? c_white;
    var alpha = data[$ "alpha"] ?? 1;
    var halfHeight = height * 0.5;
    var angleStep = 2 * pi / radialSegments;

    vertices = [];

    // Tip of the cone (aligned with -Z)
    var tip = { x: 0, y: 0, z: -halfHeight };

    // Side triangles (rotated -90° on X)
    for (var i = 0; i < radialSegments; i++) {
        var a = i * angleStep;
        var b = (i + 1) % radialSegments * angleStep;

        var x0 = cos(a) * radius;
        var y0 = sin(a) * radius;

        var x1 = cos(b) * radius;
        var y1 = sin(b) * radius;

        // Base vertices (before rotation → apply -90° X)
        var v0 = { x: x0, y: 0, z: y0 + halfHeight, nx: 0, ny: 0, nz: 0, u: 0, v: 0, color, alpha };
        var v1 = { x: x1, y: 0, z: y1 + halfHeight, nx: 0, ny: 0, nz: 0, u: 1, v: 0, color, alpha };
        var vtip = { x: tip.x, y: tip.y, z: tip.z, nx: 0, ny: 0, nz: 0, u: 0.5, v: 1, color, alpha };

        array_push(vertices, v0, v1, vtip);
    }

    // Bottom circle (rotated -90° on X)
    for (var i = 0; i < radialSegments; i++) {
        var a = i * angleStep;
        var b = (i + 1) % radialSegments * angleStep;

        var x0 = cos(a) * radius;
        var y0 = sin(a) * radius;

        var x1 = cos(b) * radius;
        var y1 = sin(b) * radius;

        var center = { x: 0, y: 0, z: halfHeight, nx: 0, ny: 0, nz: 1, u: 0.5, v: 0.5, color, alpha };
        var v0 = { x: x0, y: 0, z: y0 + halfHeight, nx: 0, ny: 0, nz: 1, u: 0, v: 0, color, alpha };
        var v1 = { x: x1, y: 0, z: y1 + halfHeight, nx: 0, ny: 0, nz: 1, u: 1, v: 0, color, alpha };

        array_push(vertices, center, v0, v1);
    }

    build();
}
