renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 200, y: 70, z: 100 }).use();
orbitControls = new UeOrbitControls(camera);

// Textures
var texPyramid   = new UeTexture(spr_tex_pyramid);
var texSand      = new UeTexture(spr_tex_sand);
var texPalmTree  = new UeTexture(spr_tex_palm_tree);

// Materials
var matSand     = new UeMeshStandardMaterial({ map: texSand });
var matPyramid0 = new UeMeshStandardMaterial({ map: texPyramid });
var matPyramid1 = new UeMeshStandardMaterial({ map: texPyramid });
var matPyramid2 = new UeMeshStandardMaterial({ map: texPyramid });
matTree         = new UeSpriteMaterial({ map: texPalmTree });

// Terrain
var desert = new UeStaticMesh(new UePlaneGeometry(1000, 1000), matSand);

// Pyramids
var pyramid0 = new UeStaticMesh(new UePyramidGeometry({ base: 160, height: 100 }), matPyramid0);

var pyramid1 = new UeStaticMesh(new UePyramidGeometry({ base: 75, height: 60 }), matPyramid1, { x: -150, y: -150, z: 0 });

var pyramid2 = new UeStaticMesh(new UePyramidGeometry({ base: 60, height: 40 }), matPyramid2, { x: -150, y: 150, z: 0 });

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
    });
    sprMesh.matrixAutoUpdate = false;
    scene.add(sprMesh);
});

// Lighting
var ambientLight = new UeAmbientLight(#5A4628);
var sunLight = new UeDirectionalLight(#FFFFC8, .7, { x: 100, y: 300 });

scene.add(ambientLight, sunLight, desert, pyramid0, pyramid1, pyramid2);
scene.updateWorldMatrix(false, true);
