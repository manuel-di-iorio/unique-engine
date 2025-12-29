renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: -70, y: -130, z: 70 }).use();
orbit = new UeOrbitControls(camera);
scene.add(new UeAmbientLight(c_ltgray), new UeGridHelper(2000));

// Create the box object
var boxSize = 50;
var boxGeometry = new UeBoxGeometry(boxSize, boxSize, boxSize);

var box3 = box3_create(); 
box3_set_from_center_and_size(box3, vec3_create(0, 0, 0), vec3_create(boxSize, boxSize, boxSize));
boxGeometry.boundingBox = box3;
boxGeometry.boundingSphere = sphere_create(vec3_create(0, 0, 0), boxSize);
box = new UeMesh(boxGeometry, new UeMeshStandardMaterial());
box.material.textures.map = new UeTexture(spr_tex_box, { generateMipmaps: true });
box.material.build();
scene.add(box);

// Create the TransformControls helper and attach the object
control = new UeGizmoControls(camera);
control.attach(box);
