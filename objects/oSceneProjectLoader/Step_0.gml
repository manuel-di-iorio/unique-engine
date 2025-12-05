orbit.update();

dirLightAngle = (dirLightAngle + .5) % 360;
dirLight.position.x = treePos.x + lengthdir_x(1000, dirLightAngle);
dirLight.position.y = treePos.y + lengthdir_y(1000, dirLightAngle);
