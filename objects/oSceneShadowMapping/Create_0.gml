renderer = new UeRenderer({ 
    shadowMap: {
        enabled: true,
    }
});
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 50, y: -100, z: 50 });
orbit = new UeOrbitControls(camera);

cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: #44EE88 });
cubeMesh = new UeMesh(cubeGeometry, new UeMeshStandardMaterial(), { castShadow: true, receiveShadow: true });

terrain = new UeMesh(new UePlaneGeometry(500, 500), new UeMeshStandardMaterial(), { z: -25, receiveShadow: true });

ambientLight = new UeAmbientLight(c_dkgray);
dirLightHoriz = 100;
dirLight = new UeDirectionalLight(dirLightHoriz, 30, { color: c_ltgray, castShadow: true });

scene.add(cubeMesh, ambientLight, dirLight, terrain);
scene.updateWorldMatrix(false, true);

shadowMapViewer = new UeShadowMapViewer(dirLight);
