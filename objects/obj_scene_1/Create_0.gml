renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 150, y: 50, z: 50, xt: 10, yt: 0, zt: 30 });
camera.matrixAutoUpdate = false;

// Create the terrain
var terrainGeometry = new UeCircleGeometry(500);
var terrain = new UeMesh(terrainGeometry, undefined, { z: -100 });
terrain.matrixAutoUpdate = false;

/**
 * Example tree (group of meshes)
 */
var treeGroup = new UeMesh();
treeGroup.matrixAutoUpdate = false;

var treeShadowGeometry = new UeCircleGeometry(25, { color: c_gray });
treeShadowGeometry.matrixAutoUpdate = false;

var treeShadow = new UeMesh(treeShadowGeometry, undefined, { z: -24 });
treeShadow.matrixAutoUpdate = false;

var treeTrunkGeometry = new UeBoxGeometry(20, 20, 50, { color: c_maroon });
treeTrunkGeometry.matrixAutoUpdate = false;

var treeTrunk = new UeMesh(treeTrunkGeometry);
treeTrunk.matrixAutoUpdate = false;

var treeTopGeometry = new UeSphereGeometry(40, { color: #11aa11 });
treeTopGeometry.matrixAutoUpdate = false;

var treeTop = new UeMesh(treeTopGeometry, undefined, { z: 55 });
treeTop.matrixAutoUpdate = false;

treeGroup.add(treeShadow, treeTrunk, treeTop);

// Lights
var ambientLight = new UeAmbientLight(#226622);
var pointLight = new UePointLight(2000, { x: 50, y: 70, z: 50 });

// Add everything to the scene
scene.add(ambientLight, pointLight, terrain, treeGroup);