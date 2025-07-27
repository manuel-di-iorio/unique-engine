// Project the raycaster from the camera origin towards the mouse coords
raycaster.setFromCamera(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), camera);
var intersects = raycaster.intersectObject(axesHelper, false);

hitSphere.visible = false;

if (array_length(intersects) > 0) {
    var hit = intersects[0].point;
    hitSphere.position.copy(hit);
    hitSphere.updateMatrix();
    hitSphere.visible = true;
}