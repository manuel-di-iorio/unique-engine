camera = new UePerspectiveCamera({ x: 100, y: -600, z: 300 });
camera.use();
orbit = new UeOrbitControls(camera, { xt: 150, zt: 50 });
project = new UeProjectLoader();
project.renderer.shadowMap.enabled = true;

var scene = project.scene;

// Get the main decorated tree
var _tree = scene.getObjectByName("oTreeDecoratedSnow_16");
treePos = _tree.position;

// Create the terrain
var _materialStandard = new UeMeshStandardMaterial();
var _terrainGeometry = new UeCircleGeometry(1000, { color: #FFFFFF });
var _terrain = new UeStaticMesh(_terrainGeometry, _materialStandard, { x: treePos.x, y: treePos.y });

scene.traverse(function(child){
    child.castShadow = true;
    child.receiveShadow = true;
});

// Add directional light
dirLight = new UeDirectionalLight({ z: 600, castShadow: true});
dirLight.target = _tree;
dirLightAngle = 0;

// Add the terrain and lights to the scene
scene.add(_terrain, new UeAmbientLight(c_dkgray), dirLight);
scene.updateWorldMatrix(false, true);

// Shadows
_terrain.receiveShadow = true;
dirLight.castShadow = true;
shadowMapViewer = new UeShadowMapViewer(dirLight);