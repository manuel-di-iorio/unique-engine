function UeCameraHelper(camera, color = c_yellow): UeLineSegments() constructor {
    self.camera = camera;
    self.color = color;
    self.pointMap = {};
    
    material.transparent = true;
    material.depthTest = false;
    material.forceSinglePass = true;
    material.side = cull_noculling;

    matrixWorld.copy(self.camera.matrixWorld)
        .multiply(global.UE_DUMMY_MATRIX4.makeRotationZ(180))
        .multiply(global.UE_DUMMY_MATRIX4.makeRotationY(180));
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
        var v = new UeVector3().set(ndcPoint[0], ndcPoint[1], ndcPoint[2])
            .unproject(camera)
            .applyMatrix4(rotFix);
        array_push(farPoints, v);
    }

    var camPos = camera.position;

    // From camera position to far plane corners
    for (var i = 0; i < 4; i++) {
        var p = farPoints[i];
        array_push(segments, camPos.x, camPos.x, camPos.z,  p.x, p.y, p.z);
    }

    // Far plane square
    for (var i = 0; i < 4; i++) {
        var a = farPoints[i];
        var b = farPoints[(i + 1) % 4];
        array_push(segments, a.x, a.y, a.z,  b.x, b.y, b.z);
    }
    
    geometry.setPositions(segments);

    // -- Methods --
    function update() {
        gml_pragma("forceinline");
        matrixWorld.copy(self.camera.matrixWorld);
        return self;
    }
    
    function setColors(color = c_yellow) {
        gml_pragma("forceinline");
        geometry.setColors(color);
        return self;
    }
}
