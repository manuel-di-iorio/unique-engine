renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: -10, z: 50 });
orbit = new UeOrbitControls(camera);

var ambientLight = new UeAmbientLight(c_ltgray);
scene.add(ambientLight);

scene.add(new UeGridHelper(2000));

var boxSize = 50;
var boxGeometry = new UeBoxGeometry(boxSize, boxSize, boxSize);
boxGeometry.boundingBox = new UeBox3().setFromCenterAndSize(UE_VECTOR3_ZERO, new UeVector3(boxSize, boxSize, boxSize));
boxGeometry.boundingSphere = new UeSphere(UE_VECTOR3_ZERO, boxSize);
box = new UeMesh(boxGeometry);
box.visible = false;
box.material.textures.map = new UeTexture({ image: spr_tex_box });
box.material.build();
scene.add(box);

control = new UeTransformControls(camera);
control.attach(box);
scene.add(control.getHelper());

//tool = "view";
tool = "move";