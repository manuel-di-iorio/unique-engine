renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 400, y: -200, z: 200 });
orbitControls = new UeOrbitControls(camera, { zt: 150 });

// Lighting
var ambientLight = new UeAmbientLight(c_dkgray);
var sunLight = new UeDirectionalLight(150, 50, 50, { color: #FFFFC8 });

// Load the model
mtl = new UeMtlLoader();
var materials = mtl.load("cat/12221_Cat_v1_l3.mtl");

objLoader = new UeObjLoader();
objLoader.setMaterials(materials);

objMesh = objLoader.load("cat/12221_Cat_v1_l3.obj");
objMesh.setScale(10, 10, 10);
objMesh.rotateZ(90);
objMesh.updateMatrix();

objMesh.traverse(function(mesh) {
    mesh.matrixAutoUpdate = false;
    
    var geometry = mesh[$ "geometry"];
    if (geometry != undefined) geometry.freeze();
});


scene.add(ambientLight, sunLight, objMesh);