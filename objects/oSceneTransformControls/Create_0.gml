renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: -10, z: 50 });
orbit = new UeOrbitControls(camera);

var ambientLight = new UeAmbientLight();
scene.add(ambientLight);

scene.add(new UeGridHelper(500));

var boxGeometry = new UeBoxGeometry(50, 50, 50);
boxGeometry.boundingSphere = new UeSphere(UE_VECTOR3_ZERO, 50);
box = new UeMesh(boxGeometry);
box.material.textures.map = new UeTexture({ image: spr_tex_box });
box.material.build();
scene.add(box);

control = new UeTransformControls(camera);
control.attach(box);
scene.add(control.getHelper());