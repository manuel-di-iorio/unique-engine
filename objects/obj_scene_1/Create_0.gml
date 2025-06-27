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
    [  50, -100 ],
    [  80,  100 ],
    [  10,  200 ],
    [ 120,   80 ],
    [ -150, -170 ],
    [ -90,   35 ]
];

array_foreach(treePositions, function(arr) {
    var sprMesh = new UeSprite(matTree, {
        x: arr[0], y: arr[1], z: 10,
        sx: 26, sy: 40,
        isSprite: true
    });
    //sprMesh.setScale(26,40, 1)
    //sprMesh.scale.set(26, 40, 1)
    //sprMesh.matrixNeedsUpdate = true;
    scene.add(sprMesh);
});

// Lighting
ambientLight = new UeAmbientLight(#5A4628);

sunLight = new UeDirectionalLight(-200, -100, -150, { color: #FFFFC8, intensity: .8 });

scene.add(ambientLight, sunLight, desert, pyramid0, pyramid1, pyramid2);