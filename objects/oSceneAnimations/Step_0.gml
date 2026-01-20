controls.update();

// Skeletons update
skeletonHelperFox.update();
skeletonHelperRobot.update();
skeletonHelperCesiumMan.update();
skeletonHelperRiggedSimple.update();

// Evaluate the animation and apply transforms to the model hierarchy
currentTime += delta_time / 1000000;

animFoxRun.evaluate(currentTime, modelFoxRoot);
animRobot.evaluate(currentTime, modelRobotRoot);
animCube.evaluate(currentTime, modelCubeRoot);
animModelBoxAnimated.evaluate(currentTime, modelBoxAnimatedRoot);
animCesiumMan.evaluate(currentTime, modelCesiumManRoot);
animRiggedSimple.evaluate(currentTime, modelRiggedSimpleRoot);  
animMech.evaluate(currentTime, modelMechRoot);  
