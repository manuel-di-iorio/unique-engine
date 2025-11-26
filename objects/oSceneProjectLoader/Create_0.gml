renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 20, y: -100, z: 40, zt: 10 });
orbit = new UeOrbitControls(camera);
project = new UeProjectLoader();
project.setScene("sDemo");
project.scene.add(new UeAmbientLight(c_dkgray), new UeDirectionalLight(30, 60));