function Camera(data = {}): Object3D(data) constructor { 
    fov  = data[$ "fov"]  ?? 60;
    near = data[$ "near"] ?? 0.1;
    far  = data[$ "far"]  ?? 64000;
    aspect = data[$ "aspect"] ?? view_wport / view_hport;
    view = data[$ "view"] ?? view_current;
    camera = camera_create();
    target = new Vec3(data[$ "xt"] ?? 0, data[$ "yt"] ?? 0, data[$ "zt"] ?? 0);
    autoUse = data[$ "autoUse"] ?? true;
    onUpdate = data[$ "onUpdate"];
    
    // Build the perspective projection
    function use() {
        matProj = matrix_build_projection_perspective_fov(fov, aspect, near, far);
    	camera_set_proj_mat(camera, matProj);
        camera_set_update_script(camera, onUpdate);
        
        view_set_camera(view, camera);
    }
    
    if (autoUse) use();
}