renderer = new Renderer();
scene = new Scene();
camera = new Camera({ x: 150, y: 50, z: 50, xt: 10, yt: 0, zt: 30, onUpdate: scrUpdateCamera });

// Default material
material = new Material({ shader: ue_shader_light });

// Create the terrain and specify the material to use
terrain = new CircleMesh({ z: -100, radius: 500, material });

// Example tree and terrain
tree = new Mesh();
treeShadow = new CircleMesh({ z: -24, radius: 25, color: c_gray });
treeTrunk = new ParallelepipedMesh({ rx: 90, color: c_maroon });
treeTop = new SphereMesh({ radius: 40, z: 55, color: #11aa11 });
tree.add([ treeShadow, treeTrunk, treeTop ]);

// Lights
ambientLight = new AmbientLight({ color: #226622 });
pointLight = new PointLight({ x: 40, y: 40, z: 50 });

scene.add([ ambientLight, pointLight, terrain, tree ]);