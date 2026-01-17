renderer = new UeRenderer({ toneMapping: UE_TONE_MAPPING.REINHARD });
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 400, y: 300, z: 300 }).use();
orbitControls = new UeOrbitControls(camera);

// Lighting
var ambientLight = new UeAmbientLight(c_gray);
sunLight = new UeDirectionalLight(#FFFFC8, .8, { z: 100 } );
sunLightHelper = new UeDirectionalLightHelper(sunLight, 30);
sunLightAngle = 0;

// Load the model
assimpLoader = new UeAssimpLoader();
loadedModel = assimpLoader.load("pbr_mech/pbr_mech_practice.glb");

var mesh = loadedModel.root;

mesh.rotateX(90);
mesh.rotateZ(90);
mesh.setScale(200, 200, 200);

mesh.traverse(function(submesh) {
  if (submesh[$ "geometry"] == undefined) return;
  submesh.geometry.freeze();
  submesh.matrixAutoUpdate = false;
  submesh.updateMatrix();  
});

// Manually import the texture into the model's materials
var materials = loadedModel.materials;

scene.add(ambientLight, sunLight, sunLightHelper, mesh);
scene.updateWorldMatrix(false, true);

// == Mesh: Mech 1 ==
var materialMech1 = materials[$ "Mech1"];

// Mech 1 - Base Color
sprMech1_baseColor = sprite_add("pbr_mech/Mech1_baseColor.png", 1, false, false, 0, 0);
texMech1_baseColor = new UeTexture(sprMech1_baseColor);
materialMech1.setTexture("map", texMech1_baseColor);

// Mech 1 - Normal
sprMech1_normal = sprite_add("pbr_mech/Mech1_normal.png", 1, false, false, 0, 0);
texMech1_normal = new UeTexture(sprMech1_normal);
materialMech1.setTexture("normalMap", texMech1_normal);

// Mech 1 - ORM
sprMech1_metallicRoughness = sprite_add("pbr_mech/Mech1_metallicRoughness.png", 1, false, false, 0, 0);
texMech1_metallicRoughness = new UeTexture(sprMech1_normal);
materialMech1.setTexture("ormMap", texMech1_metallicRoughness);

materialMech1.build();

// == Mesh: Mech 2 ==
var materialMech2 = materials[$ "Mech2"];

// Mech 2 - Base Color
sprMech2_baseColor = sprite_add("pbr_mech/Mech2_baseColor.png", 1, false, false, 0, 0);
texMech2_baseColor = new UeTexture(sprMech2_baseColor);
materialMech2.setTexture("map", texMech2_baseColor);

// Mech 2 - Normal
sprMech2_normal = sprite_add("pbr_mech/Mech2_normal.png", 1, false, false, 0, 0);
texMech2_normal = new UeTexture(sprMech2_normal);
materialMech2.setTexture("normalMap", texMech2_normal);

// Mech 2 - ORM
sprMech2_metallicRoughness = sprite_add("pbr_mech/Mech2_metallicRoughness.png", 1, false, false, 0, 0);
texMech2_metallicRoughness = new UeTexture(sprMech2_normal);
materialMech2.setTexture("ormMap", texMech2_metallicRoughness);

materialMech2.build();
