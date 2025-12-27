orbit.update();

dirLightAngle = (dirLightAngle + .5) % 360;
dirLight.position[VEC3.x] = lengthdir_x(1000, dirLightAngle);
dirLight.position[VEC3.y] = lengthdir_y(1000, dirLightAngle);