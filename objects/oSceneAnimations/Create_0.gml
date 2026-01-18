renderer = new UeRenderer();
camera = new UePerspectiveCamera({ x: 150, y: -200, z: 200 }).use();
controls = new UeOrbitControls(camera, { zt: 100 });
scene = new UeScene();

// Light
ambientLight = new UeAmbientLight(c_gray);
dirLight = new UeDirectionalLight(c_ltgray, 1, { x: 150, y: -200, z: 200 }); 
scene.add(ambientLight, dirLight);

// Terrain
terrainGeometry = new UePlaneGeometry(1000, 1000, { color: #222222 });
terrainMesh = new UeStaticMesh(terrainGeometry);
scene.add(terrainMesh);

// Import models
assimpLoader = new UeAssimpLoader();
//animatedTriangle = assimpLoader.load("AnimatedTriangle.gltf");
model = assimpLoader.load("BrainStem.gltf");
modelRoot = model.root;
//log(model.root.bones)

modelRoot.setScale(100, 100, 100);
modelRoot.rotateX(90); 

scene.add(modelRoot);

// Init the animation
anim0 = model.animations[$ "Animation0"];
currentTime = 0;

// Add the skeleton helper
skeletonHelper = new UeSkeletonHelper(modelRoot);
scene.add(skeletonHelper);
