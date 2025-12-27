// Project the raycaster from the camera origin towards the mouse coords
raycaster.setFromCamera(camera);
var intersects = raycaster.intersectObject(axesHelper, false);

hitSphere.visible = false;

if (array_length(intersects) > 0) {
    var hit = intersects[0].point;
    hitSphere.position.copy(hit);
    hitSphere.visible = true;
}
