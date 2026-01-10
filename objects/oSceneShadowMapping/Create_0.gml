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

var _matRoom = new UeMeshStandardMaterial({ side: cull_clockwise });
var terrain = new UeStaticMesh(new UePlaneGeometry(500, 500), undefined, { z: -25, receiveShadow: true });
// var cubeRoom = new UeStaticMesh(new UeBoxGeometry(500, 500, 500), _matRoom, { receiveShadow: true });

var ambientLight = new UeAmbientLight(c_dkgray);

// dirLight = new UeDirectionalLight(c_ltgray, .9, { 
//   z: 300, 
//   castShadow: true,
//   shadow: {
//     left: -200,
//     right: 200,
//     top: -200,
//     bottom: 200
//   }
// });
// dirLight.shadow.camera.updateProjectionMatrix();
// dirShadowMapViewer = new UeShadowMapViewer(dirLight, { width: 180, height: 180 });
// dirLightHelper = new UeDirectionalLightHelper(dirLight, 20);
// dirLightAngle = 0;

pointLight = new UePointLight(c_yellow, .5, 0, 0, { castShadow: true });
pointLightHelper = new UePointLightHelper(pointLight, 5);
pointShadowMapViewer = new UeShadowMapViewer(pointLight, { x: 200, width: 180, height: 180 });
pointLightPos = 0;

// Shadow Camera Helpers
// shadowCameraHelpers = [];
// for (var i = 0; i < 6; i++) {
//     var _col = c_white;
//     if (i == 0) _col = c_maroon;    // +X
//     if (i == 1) _col = c_maroon; // -X
//     if (i == 2) _col = c_blue;   // +Y
//     if (i == 3) _col = c_blue;  // -Y
//     if (i == 4) _col = c_green;   // +Z
//     if (i == 5) _col = c_green;   // -Z
//     var _helper = new UeCameraHelper(pointLight.shadow.cameras[i], _col);
//     array_push(shadowCameraHelpers, _helper);
//     scene.add(_helper);
// }

scene.add(cubeMesh, cubeMesh2, cubeMesh3, /*ambientLight, dirLight, dirLightHelper,*/ pointLight, pointLightHelper, terrain)//cubeRoom);
scene.updateWorldMatrix(false, true);

scene.add(new UeAxesHelper(50))
