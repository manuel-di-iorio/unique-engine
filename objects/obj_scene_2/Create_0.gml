renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 200, y: 70, z: 100 });
orbitControls = new UeOrbitControls(camera);

// Textures
var texPyramid   = new UeTexture({ image: spr_tex_pyramid });
var texSand      = new UeTexture({ image: spr_tex_sand });
var texPalmTree  = new UeTexture({ image: spr_tex_palm_tree });

// Materials
var matSand     = new UeMaterial({ map: texSand, shader: sh_ue_standard });
var matPyramid0 = new UeMaterial({ map: texPyramid, shader: sh_ue_standard });
var matPyramid1 = new UeMaterial({ map: texPyramid, shader: sh_ue_standard });
var matPyramid2 = new UeMaterial({ map: texPyramid, shader: sh_ue_standard });
matTree         = new UeSpriteMaterial({ map: texPalmTree });

// Terrain
var desert = new UeMesh(new UePlaneGeometry(1000, 1000), matSand);

// Pyramids
var pyramid0 = new UeMesh(new UePyramidGeometry({ base: 160, height: 100 }), matPyramid0);
var pyramid1 = new UeMesh(new UePyramidGeometry({ base: 75, height: 60 }), matPyramid1, { x: -150, y: -150, z: 0 });
var pyramid2 = new UeMesh(new UePyramidGeometry({ base: 60, height: 40 }), matPyramid2, { x: -150, y: 150, z: 0 });

// Palm trees (billboards)
var treePositions = [
    [  150, -200 ],
    [  180,  200 ],
    [  40,  350 ],
    [ 220,   180 ],
    [ -180, -320 ],
    [ -220, 125 ]
];

array_foreach(treePositions, function(arr) {
    var sprMesh = new UeSprite(matTree, {
        x: arr[0], y: arr[1], z: 19,
        sx: 26, sy: 40,
        isSprite: true
    });
    scene.add(sprMesh);
});

// Lighting
var ambientLight = new UeAmbientLight(#5A4628);
var sunLight = new UeDirectionalLight(-200, -100, -150, { color: #FFFFC8, intensity: .8 });

scene.add(ambientLight, sunLight, desert, pyramid0, pyramid1, pyramid2);
