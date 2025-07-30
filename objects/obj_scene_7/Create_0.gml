renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 400, y: -200, z: 200 });
orbitControls = new UeOrbitControls(camera, { zt: 150 });

// Lighting
var ambientLight = new UeAmbientLight(c_dkgray);
var sunLight = new UeDirectionalLight(150, 50, 50, { color: #FFFFC8 });

modelLoaded = false;
scene.add(ambientLight, sunLight);