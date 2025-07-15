function UeLineGeometry(data = {}): UeBufferGeometry(data) constructor {
    color = data[$ "color"] ?? c_white;          // Default line color
    alpha = data[$ "alpha"] ?? 1;                // Default line alpha

    /// Populates the geometry with 3D positions. Array must be multiple of 3 (x,y,z)
    function setPositions(array) {
        vertices = [];
        for (var i = 0; i < array_length(array); i += 3) {
            array_push(vertices, {
                x: array[i],
                y: array[i + 1],
                z: array[i + 2],
                nx: 0, ny: 0, nz: 0,
                u: 0, v: 0,
                color,
                alpha
            });
        }
        build();
        return self;
    }

    /// Populates the geometry with RGB colors. One color per vertex (r,g,b)
    function setColors(colors) {
        var count = min(array_length(vertices), array_length(colors) / 3);
        for (var i = 0; i < count; i++) {
            var r = colors[i * 3];
            var g = colors[i * 3 + 1];
            var b = colors[i * 3 + 2];
            vertices[i].color = make_color_rgb(r, g, b);
        }
        build();
        return self;
    }

    /// Populates the geometry from a list of UeVector3 or UeVector2 points
    function setFromPoints(points) {
        vertices = [];
        for (var i = 0; i < array_length(points); i++) {
            var p = points[i];
            array_push(vertices, {
                x: p.x,
                y: p.y,
                z: p[$ "z"] ?? 0,
                nx: 0, ny: 0, nz: 0,
                u: 0, v: 0,
                color,
                alpha
            });
        }
        build();
        return self;
    }

    /// Extracts vertices from a UeLine instance (assumes no index buffer)
    function fromLine(line) {
        if (!line.isLine) return self;

        var srcVerts = line.geometry.vertices;
        vertices = [];

        for (var i = 0; i < array_length(srcVerts); i++) {
            var v = srcVerts[i];
            array_push(vertices, {
                x: v.x,
                y: v.y,
                z: v.z,
                nx: v.nx ?? 0,
                ny: v.ny ?? 0,
                nz: v.nz ?? 0,
                u: v.u ?? 0,
                v: v.v ?? 0,
                color: v.color ?? color,
                alpha: v.alpha ?? alpha
            });
        }
        build();
        return self;
    }
}
