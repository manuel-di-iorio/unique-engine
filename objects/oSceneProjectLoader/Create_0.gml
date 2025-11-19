renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 20, y: -50, z: 40, zt: 10 });
project = new UeProjectLoader();
project.setScene("Scene0");