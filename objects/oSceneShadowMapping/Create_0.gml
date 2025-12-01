renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 50, y: -100, z: 50 });
orbit = new UeOrbitControls(camera);

cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: #44EE88 });
cubeMesh = new UeStaticMesh(cubeGeometry, new UeMeshStandardMaterial());

ambientLight = new UeAmbientLight(c_dkgray);
lightHoriz = 100;
dirLight = new UeDirectionalLight(lightHoriz, 60, { color: c_ltgray });

scene.add(cubeMesh, ambientLight, dirLight);