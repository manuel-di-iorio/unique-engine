renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 150, y: 50, z: 50, xt: 10, yt: 0, zt: 30 });
//camera = new UePerspectiveCamera({ x: 400, y: 300, z: 300 });

project = new UeProjectLoader();
project.setScene("Scene0");
