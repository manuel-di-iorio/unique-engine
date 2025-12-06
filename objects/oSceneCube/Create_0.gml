renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 50, y: -100, z: 50 }).use();
camera.matrixAutoUpdate = false;

cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: c_fuchsia });
cubeMesh = new UeStaticMesh(cubeGeometry, new UeMeshStandardMaterial());

ambientLight = new UeAmbientLight(c_dkgray);
dirLight = new UeDirectionalLight(c_ltgray, 1, { x: 150, y: 80, z: 90 }); 

scene.add(cubeMesh, ambientLight, dirLight);