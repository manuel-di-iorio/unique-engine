controls.update();

skeletonHelperFox.update();
skeletonHelperRobot.update();
skeletonHelperCesiumMan.update();
skeletonHelperRiggedSimple.update();

// Update the animation time using delta_time (converted to seconds)
currentTime += delta_time / 1000000;

// Evaluate the animation and apply transforms to the model hierarchy
animFoxRun.evaluate(currentTime, modelFoxRoot);
animRobot.evaluate(currentTime, modelRobotRoot);
animCube.evaluate(currentTime, modelCubeRoot);
animModelBoxAnimated.evaluate(currentTime, modelBoxAnimatedRoot);
animCesiumMan.evaluate(currentTime, modelCesiumManRoot);
animRiggedSimple.evaluate(currentTime, modelRiggedSimpleRoot);  
