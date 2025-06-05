function scrUpdateCamera() {
    var camera = o_test.camera;
    var position = camera.position;
    var target = camera.target;
    
    camera_set_view_mat(camera.camera, matrix_build_lookat(
        position.x, position.y, position.z,  // From
        target.x, target.y, target.z, // To
        0, 0, -1 // Up
    ));
}