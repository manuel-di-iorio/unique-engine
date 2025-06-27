renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 200, y: 70, z: 100 });
orbitControls = new UeOrbitControls(camera);

// Textures
texPyramid   = new UeTexture({ image: spr_tex_pyramid });
texSand      = new UeTexture({ image: spr_tex_sand });
texPalmTree  = new UeTexture({ image: spr_tex_palm_tree });

// Materials
matSand    = new UeMaterial({ map: texSand, shader: sh_ue_standard });
matPyramid = new UeMaterial({ map: texPyramid, shader: sh_ue_standard });
matTree    = new UeSpriteMaterial({ map: texPalmTree });

// Terrain
desert = new UeMesh(new UePlaneGeometry(1000, 1000), { material: matSand });

// Pyramids
pyramid0 = new UeMesh(new UePyramidGeometry({ base: 160, height: 100 }), { material: matPyramid });

pyramid1 = new UeMesh(new UePyramidGeometry({ base: 75, height: 60 }), {
    x: -150, y: -150, z: 0,
    material: matPyramid
});

pyramid2 = new UeMesh(new UePyramidGeometry({ base: 60, height: 40 }), {
    x: -150, y: 150, z: 0,
    material: matPyramid
});

// Palm trees (billboards)
treePositions = [
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
ambientLight = new UeAmbientLight(#5A4628);

sunLight = new UeDirectionalLight(-200, -100, -150, { color: #FFFFC8, intensity: .8 });

scene.add(ambientLight, sunLight, desert, pyramid0, pyramid1, pyramid2);