renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 150, y: 50, z: 50, xt: 10, yt: 0, zt: 30 });
camera.matrixAutoUpdate = false;

// Create the default material
var material = new UeMeshStandardMaterial()

// Create the terrain
var terrainGeometry = new UeCircleGeometry(500, { material, color: #226622 });
var terrain = new UeStaticMesh(terrainGeometry, undefined, { z: -100 });

/**
 * Example tree (group of meshes)
 */
var treeGroup = new UeStaticMesh();

var treeShadowGeometry = new UeCircleGeometry(25, { color: #183318, segments: 64 });
var treeShadow = new UeStaticMesh(treeShadowGeometry, undefined, { z: -24 });

var treeTrunkGeometry = new UeBoxGeometry(20, 20, 50, { color: #600000 });
var treeTrunk = new UeStaticMesh(treeTrunkGeometry, material);

var treeTopGeometry = new UeSphereGeometry(40, { color: #11aa11, lats: 40, lons: 40 });
var treeTop = new UeStaticMesh(treeTopGeometry, undefined, { z: 55 });

treeGroup.add(treeShadow, treeTrunk, treeTop);

// Light
var ambientLight = new UeAmbientLight(#999966);

// Add everything to the scene
scene.add(ambientLight, terrain, treeGroup);