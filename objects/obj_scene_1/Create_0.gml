renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 150, y: 50, z: 50, xt: 10, yt: 0, zt: 30 });

// Create the terrain
var terrainGeometry = new UeCircleGeometry(500);
var terrain = new UeMesh(terrainGeometry, { z: -100 });

// Example tree (group of meshes)
var treeGroup = new UeMesh();

var treeShadowGeometry = new UeCircleGeometry(25, { color: c_gray });
var treeShadow = new UeMesh(treeShadowGeometry, { z: -24 });

var treeTrunkGeometry = new UeBoxGeometry(20, 20, 50, { color: c_maroon });
var treeTrunk = new UeMesh(treeTrunkGeometry, { rx: 90 });

var treeTopGeometry = new UeSphereGeometry(40, { color: #11aa11 });
var treeTop = new UeMesh(treeTopGeometry, { z: 55 });

treeGroup.add(treeShadow, treeTrunk, treeTop);

// Lights
var ambientLight = new UeAmbientLight(#226622);
var pointLight = new UePointLight(2000, { x: 50, y: 70, z: 50 });

// Add everything to the scene
scene.add(ambientLight, pointLight, terrain, treeGroup);

sceneBuffer = new UeBufferExporter().parse(scene);
buffer_save(sceneBuffer, "scene0.buff");
buffer_delete(sceneBuffer);
scene.clear();
var model = new UeBufferLoader().load("scene0.buff");
scene.add(model.objects);