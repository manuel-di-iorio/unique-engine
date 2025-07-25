function UePerspectiveCamera(data = {}): UeObject3D(data) constructor { 
    isCamera = true; // @todo May create a new UeCamera class?
    isPerspectiveCamera = true;
    type = "Camera";
    fov  = data[$ "fov"]  ?? 60;
    near = data[$ "near"] ?? 0.1;
    far  = data[$ "far"]  ?? 3200;
    aspect = data[$ "aspect"] ?? view_wport / view_hport;
    view = data[$ "view"] ?? view_current;
    camera = camera_create();
    setPosition(data[$ "x"] ?? 0, data[$ "y"] ?? -100, data[$ "z"] ?? 0);
    target = new UeVector3(data[$ "xt"] ?? 0, data[$ "yt"] ?? 0, data[$ "zt"] ?? 0);
    autoUse = data[$ "autoUse"] ?? true;
    antialias = data[$ "antialias"] ?? 4;
    vsync = data[$ "vsync"] ?? true;
    upX = global.UE_OBJECT3D_DEFAULT_UP.x;
    upY = global.UE_OBJECT3D_DEFAULT_UP.y;
    upZ = global.UE_OBJECT3D_DEFAULT_UP.z;
    
    // Matrixes
    matrixWorldInverse = new UeMatrix4();
    projectionMatrix = new UeMatrix4();
    projectionMatrixInverse = new UeMatrix4();
    
    // @MissingDoc
    function updateProjectionMatrix() {
        projectionMatrix.fromArray(matrix_build_projection_perspective_fov(fov, aspect, near, far));
        projectionMatrixInverse.copy(projectionMatrix).invert();
    	camera_set_proj_mat(camera, projectionMatrix.data);
    }
    
    // @MissingDoc
    function updateMatrixWorld() {
        var lookAt = matrix_build_lookat(
            position.x, position.y, position.z,  // From
            target.x, target.y, target.z, // To
            upX, upY, upZ // Up
        )
        matrixWorldInverse.fromArray(lookAt);
        matrixWorld.copy(matrixWorldInverse).invert();
        camera_set_view_mat(camera, lookAt);
    }
    
    // Build the perspective projection
    function use() {
        updateProjectionMatrix();
        updateMatrixWorld();
        view_set_visible(view, true);
        view_set_camera(view, camera);
        
        // Set the antialias and vsync props
        if (antialias > 0) display_reset(antialias, vsync);
    }
    
    function dispose() {
        camera_destroy(camera);
        camera = undefined;
        return self;
    }
    
    if (autoUse) use();
}