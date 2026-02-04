camera = new UePerspectiveCamera({ x: 150, y: -700, z: 300 }).use();
orbit = new UeOrbitControls(camera);
project = new UeProjectLoader();

var scene = project.scene;

// Get the main decorated tree
var _tree = scene.getObjectByName("mTreeDecoratedSnow");

// Create the terrain
var _terrainGeometry = new UeCircleGeometry(1000, { color: #FFFFFF });
var _terrain = new UeStaticMesh(_terrainGeometry, undefined);
scene.add(_terrain);

// Add directional light
dirLight = new UeDirectionalLight(c_ltgray, 1, { x: -300, y: 300, z: 200 });
// dirLight.target = _tree;

// Add the terrain and lights to the scene
scene.add(new UeAmbientLight(c_gray), dirLight);
