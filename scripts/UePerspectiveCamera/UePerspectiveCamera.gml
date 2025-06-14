function UePerspectiveCamera(data = {}): UeObject3D(data) constructor { 
    isCamera = true;
    fov  = data[$ "fov"]  ?? 60;
    near = data[$ "near"] ?? 0.1;
    far  = data[$ "far"]  ?? 32000;
    aspect = data[$ "aspect"] ?? view_wport / view_hport;
    view = data[$ "view"] ?? view_current;
    camera = camera_create();
    position.set(data[$ "x"] ?? 100, data[$ "y"] ?? 50, data[$ "z"] ?? 50);
    target = new UeVector3(data[$ "xt"] ?? 0, data[$ "yt"] ?? 0, data[$ "zt"] ?? 0);
    autoUse = data[$ "autoUse"] ?? true;
    antialias = data[$ "antialias"] ?? 4;
    vsync = data[$ "vsync"] ?? true; 
    
    onUpdate = data[$ "onUpdate"] ?? function() {
        var camera = o_test.camera;
        var position = camera.position;
        var target = camera.target;
        
        camera_set_view_mat(camera.camera, matrix_build_lookat(
            position.x, position.y, position.z,  // From
            target.x, target.y, target.z, // To
            0, 0, -1 // Up
        ));
    };
    
    // Build the perspective projection
    function use() {
        matProj = matrix_build_projection_perspective_fov(fov, aspect, near, far);
    	camera_set_proj_mat(camera, matProj);
        camera_set_update_script(camera, onUpdate);
        
        view_set_visible(view, true);
        view_set_camera(view, camera);
        
        // Set the antialias and vsync props
        if (antialias > 0) display_reset(antialias, vsync);
    }
    
    if (autoUse) use();
}