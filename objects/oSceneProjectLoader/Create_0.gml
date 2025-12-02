camera = new UePerspectiveCamera({ x: 100, y: -600, z: 300 });
orbit = new UeOrbitControls(camera, { xt: 150, zt: 50 });
project = new UeProjectLoader();
project.renderer.shadowMap.enabled = true;
var scene = project.scene;

// Get the main decorated tree
var _tree = scene.getObjectByName("oTreeDecoratedSnow_16");
var _treePos = _tree.position;

// Create the terrain
var _materialStandard = new UeMeshStandardMaterial();
var _terrainGeometry = new UeCircleGeometry(1000, { color: #FFFFFF });
var _terrain = new UeStaticMesh(_terrainGeometry, _materialStandard, { x: _treePos.x, y: _treePos.y });

// Add the objects to the current scene
scene.traverse(function(child){
    child.castShadow = true;
    child.receiveShadow = true;
});

// Add directional light
_dir = 30;
_dirLight = new UeDirectionalLight(_dir, 60);
scene.add(_terrain, new UeAmbientLight(c_dkgray), _dirLight);
scene.updateWorldMatrix(false, true);

// Shadows
_terrain.receiveShadow = true;
_dirLight.castShadow = true;
