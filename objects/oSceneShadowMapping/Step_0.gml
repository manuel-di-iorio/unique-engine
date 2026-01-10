orbit.update();

// Point light movement
var moveSpeed = 2;

// Get camera direction (forward) projected on XY plane
var camPos = camera.position;
var camTarget = orbit.target; // Using orbit target since it's an orbit camera
var camDirX = camTarget[VEC3.x] - camPos[VEC3.x];
var camDirY = camTarget[VEC3.y] - camPos[VEC3.y];
var len = point_distance(0, 0, camDirX, camDirY);

if (len > 0) {
    var fwdX = camDirX / len;
    var fwdY = camDirY / len;
    var rgtX = fwdY;  // Perpendicular (Right)
    var rgtY = -fwdX;

    if (keyboard_check(ord("J"))) {
        pointLight.position[VEC3.x] -= rgtX * moveSpeed;
        pointLight.position[VEC3.y] -= rgtY * moveSpeed;
    }
    if (keyboard_check(ord("L"))) {
        pointLight.position[VEC3.x] += rgtX * moveSpeed;
        pointLight.position[VEC3.y] += rgtY * moveSpeed;
    }
    if (keyboard_check(ord("I"))) {
        pointLight.position[VEC3.x] += fwdX * moveSpeed;
        pointLight.position[VEC3.y] += fwdY * moveSpeed;
    }
    if (keyboard_check(ord("K"))) {
        pointLight.position[VEC3.x] -= fwdX * moveSpeed;
        pointLight.position[VEC3.y] -= fwdY * moveSpeed;
    }
}

if (keyboard_check(ord("U"))) pointLight.position[VEC3.z] += moveSpeed;
if (keyboard_check(ord("O"))) pointLight.position[VEC3.z] -= moveSpeed;

orbit.update();
pointLightHelper.update();

// Directional
 dirLightAngle = (dirLightAngle + .5) % 360;
 dirLight.position[VEC3.x] = lengthdir_x(1000, dirLightAngle);
 dirLight.position[VEC3.y] = lengthdir_y(1000, dirLightAngle);
 dirLightHelper.update();
