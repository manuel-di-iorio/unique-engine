renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 400, y: 300, z: 300 });
orbitControls = new UeOrbitControls(camera, { autoRotate: true });

// Lighting
var ambientLight = new UeAmbientLight(c_dkgray);
var sunLight = new UeDirectionalLight(150, 50, 50, { color: #FFFFC8 });

// Load the model
assimpLoader = new AssimpLoader();
var importedMesh = assimpLoader.load("11804_Airplane_v2_l2.obj");

// Manually import the texture into the model's material
sprAirplane = sprite_add("11804_Airplane_diff.jpg", 1, false, false, 0, 0);
texAirplane = new UeTexture({ image: sprAirplane });
importedMesh.traverse(function(mesh) {
    var material = mesh.material;
    material.textures.map = texAirplane;
    material.build();
});

scene.add(ambientLight, sunLight, importedMesh);