orbitControls.update();
renderer.render(scene, camera);


// tree 147FCC
// sand D6FFF9


// ------------ 1 ------------

//camera = new PerspectiveCamera({ x: 150, y: 50, z: 50, xt: 10, yt: 0, zt: 30 });
//
//// Create the terrain
//terrain = new CircleMesh({ z: -100, radius: 500 });
//
//// Example tree
//tree = new Mesh();
//treeShadow = new CircleMesh({ z: -24, radius: 25, color: c_gray });
//treeTrunk = new ParallelepipedMesh({ rx: 90, color: c_maroon });
//treeTop = new SphereMesh({ radius: 40, z: 55, color: #11aa11 });
//tree.add(treeShadow, treeTrunk, treeTop);
//
//// Lights
//ambientLight = new AmbientLight({ color: #226622 });
//pointLight = new PointLight({ x: 40, y: 40, z: 50 });
//
//scene.add(ambientLight, pointLight, terrain, tree);

//



// -------------- 2 -------------

//camera = new PerspectiveCamera();
//orbitControls = new OrbitControls({ camera, radius: 230, elevation: 30 });
//
//// Load the textures and create the materials
//var tex_pyramid = new Texture({ image: spr_tex_pyramid });
//var tex_sand = new Texture({ image: spr_tex_sand  });
//var tex_palm_tree = new Texture({ image: spr_tex_palm_tree });
//
//material_sand = new Material({ map: tex_sand, shader: sh_ue_standard });
//material_pyramid = new Material({ map: tex_pyramid, shader: sh_ue_standard });
//
//// Create the sand terrain
//var desert = new SquareMesh({ width: 1000, height: 1000, color: #F0DCA0, material: material_sand });
//
//// Pyramids
//var pyramid0 = new PyramidMesh({ base: 160, height: 100, color: #C8B464, material: material_pyramid });
//var pyramid1 = new PyramidMesh({ x: -150, y: -150, base: 75, height: 60, color: #C8B464, material: material_pyramid });
//var pyramid2 = new PyramidMesh({ x: -150, y: 150, base: 60, height: 40, color: #C8B464, material: material_pyramid });
//
//// Trees
//var tree0 = new SpriteMesh({ x: 50, y: -100, z: 10, width: 26, height: 40, map: tex_palm_tree });
//var tree1 = new SpriteMesh({ x: 80, y: 100, z: 10, width: 26, height: 40, map: tex_palm_tree });
//var tree2 = new SpriteMesh({ x: 10, y: 200, z: 10, width: 26, height: 40, map: tex_palm_tree });
//var tree3 = new SpriteMesh({ x: 120, y: 80, z: 10, width: 26, height: 40, map: tex_palm_tree });
//var tree4 = new SpriteMesh({ x: -150, y: -170, z: 10, width: 26, height: 40, map: tex_palm_tree });
//var tree5 = new SpriteMesh({ x: -90, y: 35, z: 10, width: 26, height: 40, map: tex_palm_tree });
//
//// Lights
//var sun = new DirectionalLight({ xt: -200, yt: -100, zt: -150, color: #FFFFC8 });
//var ambient = new AmbientLight({ color: #5A4628 });
//
//scene.add(ambient, sun, desert, pyramid0, pyramid1, pyramid2, tree0, tree1, tree2, tree3, tree4, tree5);

