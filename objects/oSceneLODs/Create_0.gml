renderer = new UeRenderer();
camera = new UePerspectiveCamera({ x: 100, y: -100, z: 150 }).use();
controls = new UeOrbitControls(camera);
scene = new UeScene();

// Light
hemiLight = new UeHemisphereLight(c_gray, c_dkgray);
dirLight = new UeDirectionalLight(#FFFF00, 1, { x: -100, y: 50, z: 80 }); 
scene.add(hemiLight, dirLight);

// Terrain
terrainGeometry = new UePlaneGeometry(1000, 1000, { color: #222222 });
terrainMesh = new UeStaticMesh(terrainGeometry);
scene.add(terrainMesh);

// Objects
geometryHigh = new UeSphereGeometry(50, { lats: 64, lons: 64, color: c_white });
meshHigh = new UeStaticMesh(geometryHigh);

geometryMedium = new UeSphereGeometry(50, { lats: 16, lons: 16, color: c_yellow });
meshMedium = new UeStaticMesh(geometryMedium);

geometryLow = new UeSphereGeometry(50, { lats: 6, lons: 6, color: c_blue });
meshLow = new UeStaticMesh(geometryLow);

// Lod
lod = new UeLod({ z: 64 });
lod.addLevel(meshHigh);
lod.addLevel(meshMedium, 250);
lod.addLevel(meshLow, 600);
scene.add(lod);
