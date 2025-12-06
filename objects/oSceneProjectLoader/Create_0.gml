camera = new UePerspectiveCamera({ x: 100, y: -600, z: 300 }).use();
orbit = new UeOrbitControls(camera, { xt: 150, zt: 50 });
project = new UeProjectLoader();

var scene = project.scene;

// Get the main decorated tree
var _tree = scene.getObjectByName("oTreeDecoratedSnow_16");
treePos = _tree.position;

// Create the terrain
var _materialStandard = new UeMeshStandardMaterial();
var _terrainGeometry = new UeCircleGeometry(1000, { color: #FFFFFF });
var _terrain = new UeStaticMesh(_terrainGeometry, _materialStandard, { x: treePos.x, y: treePos.y });

// Add directional light
dirLight = new UeDirectionalLight(c_ltgray, 1, { x: -300, y: 300, z: 200 });
dirLight.target = _tree;

// Add the terrain and lights to the scene
scene.add(_terrain, new UeAmbientLight(c_dkgray), dirLight);
scene.updateWorldMatrix(false, true);