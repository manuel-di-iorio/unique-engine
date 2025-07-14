renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera();

cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: c_blue, canFreeze: false });
cubeMesh = new UeMesh(cubeGeometry);

ambientLight = new UeAmbientLight();
dirLight = new UeDirectionalLight(-100, 50, -70);

scene.add(cubeMesh, ambientLight, dirLight);