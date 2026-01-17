renderer = new UeRenderer();
camera = new UePerspectiveCamera({ x: 100, y: -100, z: 100 }).use();
controls = new UeOrbitControls(camera);
scene = new UeScene();

// Light
hemiLight = new UeHemisphereLight(c_gray, c_dkgray);
dirLight = new UeDirectionalLight(#FFFF00, 1, { x: -100, y: 50, z: 80 }); 
scene.add(hemiLight, dirLight);

// Terrain
terrainGeometry = new UePlaneGeometry(1000, 1000, { color: #222222 });
terrainMesh = new UeStaticMesh(terrainGeometry);
scene.add(terrainMesh);

// Import models
assimpLoader = new UeAssimpLoader();
animatedTriangle = assimpLoader.load("AnimatedTriangle.gltf");

anim0 = animatedTriangle.animations[0]
currentTime = 0;

scene.add(animatedTriangle.model);

