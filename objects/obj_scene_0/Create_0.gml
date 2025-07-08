renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera();

cubeGeometry = new UeBoxGeometry(50, 50, 50, { color: c_blue });
cubeMesh = new UeMesh(cubeGeometry);

ambientLight = new UeAmbientLight();
dirLight = new UeDirectionalLight(-100, 50, -70);

scene.add(cubeMesh, ambientLight, dirLight);

// test
//sceneBuffer = new UeBufferExporter().parse(scene);
//buffer_save(sceneBuffer, "scene0.buff");
//buffer_delete(sceneBuffer);
//scene.clear();
//var model = new UeBufferLoader().load("scene0.buff");
//scene.add(model.objects);