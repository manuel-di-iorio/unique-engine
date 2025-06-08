gpu_set_tex_filter(true);
gpu_set_texrepeat(true)
gpu_set_tex_mip_enable(true)

display_reset(4, true)

renderer = new Renderer();
scene = new Scene();
camera = new Camera();
orbitControls = new OrbitControls(camera, { radius: 230, elevation: 30 });

// Load the textures and create the materials
var tex_pyramid = sprite_get_texture(spr_tex_pyramid, 0);
var tex_sand = sprite_get_texture(spr_tex_sand, 0);
var tex_palm_tree = sprite_get_texture(spr_tex_palm_tree, 0);

material_sand = new Material({ map: tex_sand, shader: ue_shader_tex_light });
material_pyramid = new Material({ map: tex_pyramid, shader: ue_shader_tex_light });

// Create the sand terrain
var desert = new SquareMesh({ width: 1000, height: 1000, color: #F0DCA0, material: material_sand });

// Pyramids
var pyramid0 = new PyramidMesh({ base: 160, height: 100, color: #C8B464, material: material_pyramid });
var pyramid1 = new PyramidMesh({ x: -150, y: -150, base: 75, height: 60, color: #C8B464, material: material_pyramid });
var pyramid2 = new PyramidMesh({ x: -150, y: 150, base: 60, height: 40, color: #C8B464, material: material_pyramid });

// Trees
var tree0 = new SpriteMesh({ x: 50, y: -100, z: 10, width: 26, height: 40, map: tex_palm_tree });
var tree1 = new SpriteMesh({ x: 80, y: 100, z: 10, width: 26, height: 40, map: tex_palm_tree });
var tree2 = new SpriteMesh({ x: 10, y: 200, z: 10, width: 26, height: 40, map: tex_palm_tree });
var tree3 = new SpriteMesh({ x: 120, y: 80, z: 10, width: 26, height: 40, map: tex_palm_tree });
var tree4 = new SpriteMesh({ x: -150, y: -170, z: 10, width: 26, height: 40, map: tex_palm_tree });
var tree5 = new SpriteMesh({ x: -90, y: 35, z: 10, width: 26, height: 40, map: tex_palm_tree });

// Lights
var sun = new DirectionalLight({ xt: -200, yt: -100, zt: -150, color: #FFFFC8 });
var ambient = new AmbientLight({ color: #5A4628 });

scene.add(ambient, sun, desert, pyramid0, pyramid1, pyramid2, tree0, tree1, tree2, tree3, tree4, tree5);