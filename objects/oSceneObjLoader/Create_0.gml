renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 450, y: -300, z: 300 });
orbitControls = new UeOrbitControls(camera, { zt: 150 });
camera.use();

// Lighting
var ambientLight = new UeAmbientLight(c_dkgray);
var sunLight = new UeDirectionalLight({ x: 60, z: 185, color: #FFFFC8, intensity: .8 });
scene.add(ambientLight, sunLight);

objMesh = undefined;
objLoader = new UeObjLoader();

// Load the model
var mtl = new UeMtlLoader();
var materials = mtl.load("cat/12221_Cat_v1_l3.mtl");

objLoader.setMaterials(materials);

loadTime = get_timer();
objMesh = objLoader.load("cat/12221_Cat_v1_l3.obj");
loadTime = (get_timer() - loadTime) / 1000000;
objMesh.setScale(10, 10, 10);
objMesh.rotateZ(90);
objMesh.updateMatrix();

objMesh.traverse(function(mesh) {
    mesh.matrixAutoUpdate = false;
    
    var geometry = mesh[$ "geometry"];
    if (geometry != undefined) geometry.freeze();
});

scene.add(objMesh);
scene.updateWorldMatrix(false, true);