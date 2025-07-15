raycaster.setFromCamera(device_mouse_x_to_gui(0), device_mouse_x_to_gui(0), camera);
var intersects = raycaster.intersectObjects(scene.children, false);
if (array_length(intersects)) {
    
}