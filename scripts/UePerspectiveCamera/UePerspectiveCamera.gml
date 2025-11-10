function UePerspectiveCamera(data = {}): UeObject3D(data) constructor { 
    isCamera = true; // @todo May create a new UeCamera class
    isPerspectiveCamera = true;
    type = "Camera";
    fov  = data[$ "fov"]  ?? 60;
    near = data[$ "near"] ?? .1;
    far  = data[$ "far"]  ?? 2000;
    view = data[$ "view"] ?? 0;
    aspect = data[$ "aspect"] ?? view_wport[view] / view_hport[view];
    camera = camera_create();
    setPosition(data[$ "x"] ?? 0, data[$ "y"] ?? -100, data[$ "z"] ?? 0);
    target = new UeVector3(data[$ "xt"] ?? 0, data[$ "yt"] ?? 1, data[$ "zt"] ?? 0);
    upX = global.UE_OBJECT3D_DEFAULT_UP.x;
    upY = global.UE_OBJECT3D_DEFAULT_UP.y;
    upZ = global.UE_OBJECT3D_DEFAULT_UP.z;
    
    // Matrixes
    matrixWorldInverse = new UeMatrix4();
    projectionMatrix = new UeMatrix4();
    projectionMatrixInverse = new UeMatrix4();
    
    function updateProjectionMatrix() {
        gml_pragma("forceinline");
        matrix_build_projection_perspective_fov(fov, aspect, near, far, global.UE_DUMMY_ARRAY16);
        projectionMatrix.fromArray(global.UE_DUMMY_ARRAY16);
        projectionMatrixInverse.copy(projectionMatrix).invert();
    	camera_set_proj_mat(camera, projectionMatrix.data);
    }
    
    function updateMatrixWorld() {
        gml_pragma("forceinline");
        matrix_build_lookat(
            position.x, position.y, position.z,  // From
            target.x, target.y, target.z, // To
            upX, upY, upZ, // Up
            global.UE_DUMMY_ARRAY16
        )
        matrixWorldInverse.fromArray(global.UE_DUMMY_ARRAY16);
        matrixWorld.copy(matrixWorldInverse).invert();
        camera_set_view_mat(camera, global.UE_DUMMY_ARRAY16);
    }
    
    // Build the perspective projection
    function dispose() {
        gml_pragma("forceinline");
        camera_destroy(camera);
        camera = undefined;
        return self;
    }
    
    updateProjectionMatrix();
    updateMatrixWorld();
    view_set_camera(view, camera);
    view_set_visible(view, true); 
}
