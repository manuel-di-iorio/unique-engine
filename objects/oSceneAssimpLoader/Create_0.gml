renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 400, y: 300, z: 300 }).use();
orbitControls = new UeOrbitControls(camera, { autoRotate: true });

// Lighting
var ambientLight = new UeAmbientLight(c_gray);
var sunLight = new UeDirectionalLight(#FFFFC8, .8, { x: 90, y: 45, z: 100 });

// Load the model
assimpLoader = new UeAssimpLoader();
loadTime = get_timer();
airplaneMesh = assimpLoader.load("airplane/11804_Airplane_v2_l2.obj").model;
loadTime = (get_timer() - loadTime) / 1000;

// Manually import the texture into the model's material
sprAirplane = sprite_add("airplane/11804_Airplane_diff.jpg", 1, false, false, 0, 0);
texAirplane = new UeTexture(sprAirplane);

airplaneMesh.traverse(function(mesh) {
    mesh.rotateZ(90);
    mesh.updateMatrix();
    mesh.matrixAutoUpdate = false;
    
    var geometry = mesh[$ "geometry"];
    if (geometry != undefined) geometry.freeze();
    
    var material = mesh[$ "material"];
    if (material != undefined) {
        material.textures.map = texAirplane;
        material.build();
    }
});

scene.add(ambientLight, sunLight, airplaneMesh);
scene.updateWorldMatrix(false, true);

airplaneBox = new UeBoxHelper(airplaneMesh);
airplaneBox.visible = false;
airplaneBox.matrixAutoUpdate = false;
scene.add(airplaneBox);

showWireframe = false;
