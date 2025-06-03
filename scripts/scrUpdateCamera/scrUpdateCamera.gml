function scrUpdateCamera() {
    var active_camera = o_test.camera;
    var position = active_camera.position;
    var target = active_camera.target;
    
    camera_set_view_mat(active_camera.camera, matrix_build_lookat(
        position.x, position.y, position.z,  // From
        target.x, target.y, target.z, // To
        0, 0, -1 // Up
    ));
}