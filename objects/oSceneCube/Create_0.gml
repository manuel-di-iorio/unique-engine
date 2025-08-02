renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 50, y: -100, z: 50 });
camera.matrixAutoUpdate = false;

cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: c_fuchsia, canFreeze: false });
cubeMesh = new UeStaticMesh(cubeGeometry);

ambientLight = new UeAmbientLight(c_dkgray);
dirLight = new UeDirectionalLight(75, 60, { color: c_ltgray });

scene.add(cubeMesh, ambientLight, dirLight);