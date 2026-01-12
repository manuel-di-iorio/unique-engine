renderer = new UeRenderer({ sortObjects: false });
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 450, y: -300, z: 300 }).use();
orbitControls = new UeOrbitControls(camera, { zt: 150 });

// Lighting
var hemiLight = new UeHemisphereLight(#AAFFAA, c_maroon, 0.8);
var sunLight = new UeDirectionalLight(#FFFFC8, 1, { x: 160, y: 150, z: 185, zt: 130 });
scene.add(hemiLight, sunLight);

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
