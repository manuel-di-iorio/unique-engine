// Project the raycaster from the camera origin towards the mouse coords
raycaster.setFromCamera(camera);
var intersects = raycaster.intersectObjects(meshGroup.children, false);

// Hide the previously selected bbox
if (intersectedBox != undefined) {
    intersectedBox.visible = false;
}
//
// Show only the bbox of the closest intersected object
if (array_length(intersects)) {
    intersectedBox = intersects[0].object[$ "bbox"];
    intersectedBox.visible = true;
}

// Update the orbit controls (at the end of the step event to avoid stale matrixes)
orbitControls.update();