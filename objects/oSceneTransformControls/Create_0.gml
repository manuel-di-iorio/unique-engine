renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: -70, y: -130, z: 70 }).use();
orbit = new UeOrbitControls(camera);
scene.add(new UeAmbientLight(c_ltgray), new UeGridHelper(2000));

// Create the box object
var boxSize = 50;
var boxGeometry = new UeBoxGeometry(boxSize, boxSize, boxSize);
boxGeometry.boundingBox = new UeBox3().setFromCenterAndSize(UE_VECTOR3_ZERO, new UeVector3(boxSize, boxSize, boxSize));
boxGeometry.boundingSphere = new UeSphere(UE_VECTOR3_ZERO, boxSize);
box = new UeMesh(boxGeometry, new UeMeshStandardMaterial());
box.material.textures.map = new UeTexture(spr_tex_box);
box.material.build();
scene.add(box);

// Create the TransformControls helper and attach the object
control = new UeTransformControls(camera);
control.attach(box);
scene.add(control.getHelper());

tool = "view";