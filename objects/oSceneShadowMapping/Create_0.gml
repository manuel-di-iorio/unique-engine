renderer = new UeRenderer({ 
  shadowMap: { enabled: true }
});
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 50, y: -100, z: 50 }).use();
orbit = new UeOrbitControls(camera);

var cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: #44EE88 });

var cubeMesh = new UeStaticMesh(cubeGeometry, undefined, { castShadow: true, receiveShadow: true, x: -100, y: 30 });
var cubeMesh2 = new UeStaticMesh(cubeGeometry, undefined, { castShadow: true, receiveShadow: true, x: 40, y: 80 });
var cubeMesh3 = new UeStaticMesh(cubeGeometry, undefined, { castShadow: true, receiveShadow: true, x: 10, y: -140 });

var _matRoom = new UeMeshStandardMaterial();
var terrain = new UeStaticMesh(new UePlaneGeometry(500, 500), undefined, { z: -25, receiveShadow: true, castShadow: true });

var ambientLight = new UeAmbientLight(c_dkgray);

dirLight = new UeDirectionalLight(c_ltgray, .8, { 
 z: 300, 
 castShadow: true,
 shadow: {
   left: -200,
   right: 200,
   top: -200,
   bottom: 200
 }
});
dirLight.shadow.camera.updateProjectionMatrix();
dirShadowMapViewer = new UeShadowMapViewer(dirLight, { width: 180, height: 180 });
dirLightHelper = new UeDirectionalLightHelper(dirLight, 20);
dirLightAngle = 0;

pointLight = new UePointLight(c_yellow, 50, 300, 1, { castShadow: true });
pointLightHelper = new UePointLightHelper(pointLight, 5);
pointShadowMapViewer = new UeShadowMapViewer(pointLight, { width: 180, height: 180 });

spotLight = new UeSpotLight(c_orange, 50000, 400, 30, 1, 2, { x: 90, y: 170, z: 50, zt: -25, castShadow: true });
spotLightHelper = new UeSpotLightHelper(spotLight);
spotShadowMapViewer = new UeShadowMapViewer(spotLight, { width: 180, height: 180 });

scene.add(cubeMesh, cubeMesh2, cubeMesh3, ambientLight, dirLight, dirLightHelper, pointLight, pointLightHelper, spotLight, spotLightHelper, terrain);
scene.updateWorldMatrix(false, true);
