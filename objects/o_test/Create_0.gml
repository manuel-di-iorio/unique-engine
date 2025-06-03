renderer = new Renderer();
scene = new Scene();
camera = new Camera({ x: 150, y: 50, z: 50, xt: 10, yt: 0, zt: 30, onUpdate: scrUpdateCamera });

// Default material
material = new Material({ shader: ue_shader_light });

// Terrain
circle = new CircleMesh({ z: -70, radius: 500 });

// Example tree and terrain
treeShadow = new CircleMesh({ z: -24, radius: 25, color: c_gray });
treeTrunk = new TreeTrunkMesh({ rx: 90 });
treeTop = new TreeTopMesh({ z: 55 });

// Lights
ambientLight = new AmbientLight({ color: #226622 });
pointLight = new PointLight({ x: 40, y: 40, z: 50 });

scene.add([ ambientLight, pointLight, circle, treeShadow, treeTrunk, treeTop ]);