orbit.update();
dirLightHoriz = (dirLightHoriz + 1) % 360;
dirLight.setDirection(dirLightHoriz, 60);