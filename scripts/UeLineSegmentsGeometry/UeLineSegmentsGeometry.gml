function UeLineSegmentsGeometry(data = {}): UeBufferGeometry(data) constructor {
    // Set default color and alpha
    color = data[$ "color"] ?? c_white;
    alpha = data[$ "alpha"] ?? 1;

    /// Populates this geometry using any mesh (will extract every pair of vertices)
    function fromMesh(mesh) {
        gml_pragma("forceinline");
        var sourceVerts = mesh.geometry.vertices;
        vertices = [];

        var len = array_length(sourceVerts);
        for (var i = 0; i < len - 1; i += 2) {
            array_push(vertices,
                sourceVerts[i],
                sourceVerts[i + 1]
            );
        }

        build();
        return self;
    }
    
    // Set a list of segment positions (flat array: [x1,y1,z1,x2,y2,z2,...])
    function setPositions(arr) {
        gml_pragma("forceinline");
        vertices = [];

        var len = array_length(arr);
        for (var i = 0; i < len; i += 6) {
            array_push(vertices,
                { x: arr[i + 0], y: arr[i + 1], z: arr[i + 2], nx: 0, ny: 0, nz: 0, u: 0, v: 0, color, alpha },
                { x: arr[i + 3], y: arr[i + 4], z: arr[i + 5], nx: 0, ny: 0, nz: 0, u: 0, v: 0, color, alpha }
            );
        }

        build(); // Rebuild vertex buffer
        return self;
    }

    // Set per-vertex colors: every 6 values represent RGB for the segment
    function setColors(arr) {
        var len = min(array_length(vertices), array_length(arr) / 6 * 2);
        var j = 0;
        for (var i = 0; i < len; i += 2) {
            vertices[i].color = make_color_rgb(arr[j + 0], arr[j + 1], arr[j + 2]);
            vertices[i + 1].color = make_color_rgb(arr[j + 3], arr[j + 4], arr[j + 5]);
            j += 6;
        }

        build();
        return self;
    }
}
