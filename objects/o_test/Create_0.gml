renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 150, y: 50, z: 50, xt: 10, yt: 0, zt: 30 });

// Create the terrain
terrainGeometry = new UeCircleGeometry(500);
terrain = new UeMesh(terrainGeometry, { z: -100 });

// Example tree (group of meshes)
treeGroup = new UeMesh();

treeShadowGeometry = new UeCircleGeometry(25, { color: c_gray });
treeShadow = new UeMesh(treeShadowGeometry, { z: -24 });

treeTrunkGeometry = new UeParallelepipedGeometry({ color: c_maroon })
treeTrunk = new UeMesh(treeTrunkGeometry, { rx: 90 });

treeTopGeometry = new UeSphereGeometry(40, { color: #11aa11 });
treeTop = new UeMesh(treeTopGeometry, { z: 55 });

treeGroup.add(treeShadow, treeTrunk, treeTop);

// Lights
ambientLight = new UeAmbientLight({ color: #226622 });
pointLight = new UePointLight(2000, { x: 40, y: 40, z: 50 });

// Add everything to the scene
scene.add(ambientLight, pointLight, terrain, treeGroup);