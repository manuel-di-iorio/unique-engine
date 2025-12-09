renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 50, y: -100, z: 50 }).use();
camera.matrixAutoUpdate = false;

composer = new UeEffectComposer(renderer);
var renderPass = new UeRenderPass(scene, camera);
renderPass.clearColor = layer_background_get_blend(layer_background_get_id("Background"));
composer.addPass(renderPass);

// Add a mesh and lights to the scene for test
var cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: c_fuchsia });
var cubeMesh = new UeStaticMesh(cubeGeometry, new UeMeshStandardMaterial());

var ambientLight = new UeAmbientLight(c_dkgray);
var dirLight = new UeDirectionalLight(c_ltgray, 1, { x: 150, y: 80, z: 90 }); 

scene.add(cubeMesh, ambientLight, dirLight);

