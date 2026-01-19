renderer = new UeRenderer();
camera = new UePerspectiveCamera({ x: 150, y: -200, z: 200 }).use();
controls = new UeOrbitControls(camera, { zt: 100 });
scene = new UeScene();

// Light
hemiLight = new UeHemisphereLight(c_gray, c_ltgray);
dirLight = new UeDirectionalLight(c_ltgray, 1, { x: 150, y: -200, z: 200 }); 
scene.add(hemiLight, dirLight);

// Import models
assimpLoader = new UeAssimpLoader({ matrixAutoUpdate: false });

modelFox = assimpLoader.load("Fox/Fox.gltf");
modelFoxRoot = modelFox.root;
modelFoxRoot.translateX(-450);
modelFoxRoot.rotateX(90);
modelFoxRoot.setScale(2, 2, 2);
matFox = modelFox.materials[$ "fox_material"];
matFox.setUniform("ueFlatShading", true);
scene.add(modelFoxRoot);

modelRobot = assimpLoader.load("Robot/BrainStem.gltf");
modelRobotRoot = modelRobot.root;
modelRobotRoot.translateX(-250);
modelRobotRoot.rotateX(90);
modelRobotRoot.setScale(100, 100, 100);
scene.add(modelRobotRoot);

modelCube = assimpLoader.load("AnimatedCube/AnimatedCube.gltf");
modelCubeRoot = modelCube.root;
modelCubeRoot.matrixAutoUpdate = true;
modelCubeRoot.translateX(-50);
modelCubeRoot.translateZ(50);
modelCubeRoot.rotateX(90);
modelCubeRoot.setScale(40, 40, 40);
scene.add(modelCubeRoot);

modelBoxAnimated = assimpLoader.load("BoxAnimated/BoxAnimated.gltf");
modelBoxAnimatedRoot = modelBoxAnimated.root;
modelBoxAnimatedRoot.traverse(function(node) {
  node.matrixAutoUpdate = true;
});
modelBoxAnimatedRoot.translateX(200);
modelBoxAnimatedRoot.translateZ(50);
modelBoxAnimatedRoot.rotateZ(180);
modelBoxAnimatedRoot.rotateX(90);
modelBoxAnimatedRoot.setScale(100, 100, 100);
scene.add(modelBoxAnimatedRoot);

modelCesiumMan = assimpLoader.load("CesiumMan/CesiumMan.gltf");
modelCesiumManRoot = modelCesiumMan.root;
modelCesiumManRoot.translateX(400);
modelCesiumManRoot.rotateX(90);
modelCesiumManRoot.setScale(100, 100, 100);
scene.add(modelCesiumManRoot);

modelRiggedSimple = assimpLoader.load("RiggedSimple/RiggedSimple.gltf");
modelRiggedSimpleRoot = modelRiggedSimple.root;
modelRiggedSimpleRoot.translateX(570);
modelRiggedSimpleRoot.translateZ(100);
modelRiggedSimpleRoot.rotateX(90);
modelRiggedSimpleRoot.setScale(30, 30, 30);
scene.add(modelRiggedSimpleRoot);


// Init the animations
currentTime = 0;

animFoxRun = modelFox.animations[$ "Run"];
animRobot = modelRobot.animations[$ "Animation0"];
animCube = modelCube.animations[$ "animation_AnimatedCube"];
animModelBoxAnimated = modelBoxAnimated.animations[$ "Animation0"];
animCesiumMan = modelCesiumMan.animations[$ "Animation0"];
animRiggedSimple = modelRiggedSimple.animations[$ "Animation0"];

// Add the skeleton helpers
skeletonHelperFox = new UeSkeletonHelper(modelFoxRoot);
scene.add(skeletonHelperFox);

skeletonHelperRobot = new UeSkeletonHelper(modelRobotRoot);
scene.add(skeletonHelperRobot);

skeletonHelperCesiumMan = new UeSkeletonHelper(modelCesiumManRoot);
scene.add(skeletonHelperCesiumMan);

skeletonHelperRiggedSimple = new UeSkeletonHelper(modelRiggedSimpleRoot);
scene.add(skeletonHelperRiggedSimple);

scene.forceUpdate();
