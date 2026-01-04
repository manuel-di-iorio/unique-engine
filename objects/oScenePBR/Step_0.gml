sunLightAngle = (sunLightAngle + .5) % 360;
sunLight.position[VEC3.x] = lengthdir_x(400, sunLightAngle);
sunLight.position[VEC3.y] = lengthdir_y(400, sunLightAngle);

// Update the light matrix and then the helper
sunLight.updateMatrixWorld();
sunLightHelper.update();
