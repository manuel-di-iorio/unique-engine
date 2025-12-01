camera = new UePerspectiveCamera({ x: 100, y: -600, z: 300 });
orbit = new UeOrbitControls(camera, { xt: 150, zt: 50 });
project = new UeProjectLoader();

// Get the main decorated tree
var _tree = project.scene.getObjectByName("oTreeDecoratedSnow_16");
var _treePos = _tree.position;

// Create the terrain
var _materialStandard = new UeMeshStandardMaterial();
var _terrainGeometry = new UeCircleGeometry(1000, { color: #FFFFFF });
var _terrain = new UeMesh(_terrainGeometry, _materialStandard, { x: _treePos.x, y: _treePos.y });

// Add the objects to the current scene
project.scene.add(_terrain, new UeAmbientLight(c_dkgray), new UeDirectionalLight(30, 60));