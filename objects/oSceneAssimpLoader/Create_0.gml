renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 400, y: 300, z: 300 });
orbitControls = new UeOrbitControls(camera, { autoRotate: true });

// Lighting
var ambientLight = new UeAmbientLight(c_dkgray);
var sunLight = new UeDirectionalLight(90, 45, { color: #FFFFC8, intensity: .8 });

// Load the model
assimpLoader = new UeAssimpLoader();
loadTime = get_timer();
airplaneMesh = assimpLoader.load("airplane/11804_Airplane_v2_l2.obj");
loadTime = (get_timer() - loadTime) / 1000;

// Manually import the texture into the model's material
sprAirplane = sprite_add("airplane/11804_Airplane_diff.jpg", 1, false, false, 0, 0);
texAirplane = new UeTexture(sprAirplane);

airplaneMesh.traverse(function(mesh) {
    mesh.matrixAutoUpdate = false;
    
    var geometry = mesh[$ "geometry"];
    if (geometry != undefined) geometry.freeze();
    
    var material = mesh[$ "material"];
    if (material != undefined) {
        material.textures.map = texAirplane;
        material.build();
    }
});

airplaneBox = new UeBoxHelper(airplaneMesh);
airplaneBox.visible = false;
airplaneBox.matrixAutoUpdate = false;


scene.add(ambientLight, sunLight, airplaneMesh, airplaneBox);

showWireframe = false;