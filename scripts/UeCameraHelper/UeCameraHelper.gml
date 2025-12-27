function UeCameraHelper(camera, color = c_yellow): UeLineSegments() constructor {
    self.camera = camera;
    self.color = color;
    self.pointMap = {};
    
    material.transparent = true;
    material.depthTest = false;
    material.forceSinglePass = true;
    material.side = cull_noculling;

    mat4_copy(matrixWorld, self.camera.matrixWorld);
    var mRot = global.UE_MAT4_TEMP0;
    mat4_make_rotation_z(mRot, 180);
    mat4_multiply(matrixWorld, mRot);
    mat4_make_rotation_y(mRot, 180);
    mat4_multiply(matrixWorld, mRot);
    matrixAutoUpdate = false;
    
    geometry = new UeLineSegmentsGeometry({ color });
    
    // Build
    var ndcPoints = [
        [-1, -1, 1], [1, -1, 1], [1, 1, 1], [-1, 1, 1]  // far plane
    ];
    
    var segments = [];

    var rotFix = global.UE_DUMMY_MATRIX4;
    rotFix.makeRotationFromEuler(90, 180, 180);

    var farPoints = [];

    for (var i = 0; i < 4; i++) {
        var ndcPoint = ndcPoints[i];
        var v = vec3_create(ndcPoint[0], ndcPoint[1], ndcPoint[2]);
        vec3_unproject(v, camera);
        vec3_apply_matrix4(v, rotFix);
        array_push(farPoints, v);
    }

    var camPos = camera.position;

    // From camera position to far plane corners
    for (var i = 0; i < 4; i++) {
        var p = farPoints[i];
        array_push(segments, camPos[0], camPos[1], camPos[2],  p[0], p[1], p[2]);
    }

    // Far plane square
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
