// Project the raycaster from the camera origin towards the mouse coords
raycaster.setFromCamera(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), camera);
var intersects = raycaster.intersectObjects(scene.children, false);

// Update the arrow helper origin/direction based on the camera
rayArrowHelper.position.copy(camera.position);
rayArrowHelper.matrixNeedsUpdate = true;
rayArrowHelper.setDirection(raycasterRay.direction);

// Hide all the bboxs
scene.traverse(function(mesh) {
    var bbox = mesh[$ "bbox"];
    if (bbox != undefined) bbox.visible = false;
});

// Show only the bbox of the intersected objects
for (var i=0, num = array_length(intersects); i < num; i++) {
    var intersect = intersects[i];
    var bbox = intersect.object[$ "bbox"];
    if (bbox != undefined) bbox.visible = true;
}