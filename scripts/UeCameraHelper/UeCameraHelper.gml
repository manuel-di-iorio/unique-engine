function UeCameraHelper(camera, color = c_yellow): UeLineSegments() constructor {
    self.camera = camera;
    self.color = color;
    self.pointMap = {};
    
    material.transparent = true;
    material.depthTest = false;
    material.forceSinglePass = true;
    material.side = cull_noculling;

    // The helper should follow the camera's world matrix
    mat4_copy(matrixWorld, self.camera.matrixWorld);
    matrixAutoUpdate = false;
    
    geometry = new UeLineSegmentsGeometry({ color });
    
    // Build local geometry
    var ndcPoints = [
        [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]  // far plane corners in NDC
    ];
    
    var segments = [];
    var farPoints = [];

    for (var i = 0; i < 4; i++) {
        var v = vec3_create(ndcPoints[i][0], ndcPoints[i][1], ndcPoints[i][2]);
        // Unproject from NDC to local view space using only projectionMatrixInverse
        vec3_apply_matrix4(v, camera.projectionMatrixInverse);
        array_push(farPoints, v);
    }

    // From local origin (0,0,0) to far plane corners
    for (var i = 0; i < 4; i++) {
        var p = farPoints[i];
        array_push(segments, 0, 0, 0,  p[0], p[1], p[2]);
    }

    // Far plane edges
    for (var i = 0; i < 4; i++) {
        var a = farPoints[i];
        var b = farPoints[(i + 1) % 4];
        array_push(segments, a[0], a[1], a[2],  b[0], b[1], b[2]);
    }
    
    geometry.setPositions(segments);

    // -- Methods --
    function update() {
        gml_pragma("forceinline");
        mat4_copy(matrixWorld, self.camera.matrixWorld);
        return self;
    }
    
    function setColors(color = c_yellow) {
        gml_pragma("forceinline");
        geometry.setColors(color);
        return self;
    }
}
