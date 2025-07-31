renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 100, y: 50, z: 50 });
camera.matrixAutoUpdate = false;

cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: c_blue, canFreeze: false });
cubeMesh = new UeMesh(cubeGeometry);
cubeMesh.matrixAutoUpdate = false;

ambientLight = new UeAmbientLight();
dirLight = new UeDirectionalLight(-100, 50, -70);

scene.add(cubeMesh, ambientLight, dirLight);