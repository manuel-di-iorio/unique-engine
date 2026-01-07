renderer = new UeRenderer({ 
  shadowMap: { enabled: true }
});
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 50, y: -100, z: 50 }).use();
orbit = new UeOrbitControls(camera);

cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: #44EE88 });
var _mat = new UeMeshStandardMaterial();
cubeMesh = new UeMesh(cubeGeometry, _mat, { castShadow: true, receiveShadow: true, x: -100, y: 30 });
cubeMesh2 = new UeMesh(cubeGeometry, _mat, { castShadow: true, receiveShadow: true, x: 40, y: 80 });
cubeMesh3 = new UeMesh(cubeGeometry, _mat, { castShadow: true, receiveShadow: true, x: 10, y: -140 });

terrain = new UeMesh(new UePlaneGeometry(500, 500), _mat, { z: -25, receiveShadow: true });

ambientLight = new UeAmbientLight(c_gray);
dirLight = new UeDirectionalLight(c_ltgray, .9, { z: 300, castShadow: true });
dirLight.shadow.camera.left = -200;
dirLight.shadow.camera.right = 200;
dirLight.shadow.camera.top = -200;
dirLight.shadow.camera.bottom = 200;
dirLight.shadow.camera.updateProjectionMatrix();
dirLightAngle = 0;

scene.add(cubeMesh, cubeMesh2, cubeMesh3, ambientLight, dirLight, terrain);
scene.updateWorldMatrix(false, true);

shadowMapViewer = new UeShadowMapViewer(dirLight);
