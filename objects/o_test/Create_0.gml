renderer = new Renderer();
scene = new Scene();
camera = new PerspectiveCamera();
orbitControls = new OrbitControls({ camera, radius: 230, elevation: 30 });

ambientLight = new AmbientLight({ color: c_dkgray });
dirLight = new DirectionalLight({ xt: -150, yt: -50, zt: 50, color: #FFFFC8 });

assimpLoader = new AssimpLoader();
importedMesh = assimpLoader.load("11804_Airplane_v2_l2.obj");
scene.add(ambientLight, dirLight, importedMesh);