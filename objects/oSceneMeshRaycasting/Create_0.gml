renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera().use();

orbitControls = new UeOrbitControls(camera, {
    autoRotate: true, 
    autoRotateSpeed: .1,
    enablePan: false,
    enableRotate: false,
    enableZoom: false,
});

// Lightning
ambientLight = new UeAmbientLight(#888888);
dirLight = new UeDirectionalLight(#FFFFC8, .8, { x: 90, y: 45 });
scene.add(ambientLight, dirLight);

// Create the raycaster
raycaster = new UeRaycaster();
raycaster.layers.set(1);
raycaster.setFromCamera(camera);
intersectedBox = undefined;

meshGroup = new UeStaticMesh(undefined);
scene.add(meshGroup);

// Create the materials
materialDefault = new UeMeshStandardMaterial();
materialDefault.setUniform("ueEmissive", [0.8, 0.8, 0]);
materialDefault.setUniform("ueEmissiveIntensity", 0);

materialSelected = new UeMeshStandardMaterial();
materialSelected.setUniform("ueEmissive", [0.8, 0.8, 0]);
materialSelected.setUniform("ueEmissiveIntensity", 1);

// Create the random boxes
var maxDist = 500;
var gap = 300;

for (var i = 0; i < 150; i++) {
    var color = make_color_rgb(irandom_range(60, 255), irandom_range(60, 255), irandom_range(60, 255));
    var size = random_range(30, 40);
    
    var geometry = new UeBoxGeometry(size, size, size, { color });
    
    var mesh = new UeStaticMesh(geometry, materialDefault);
    mesh.layers.enable(1); // Only objects having layer 1 will be intersected
    meshGroup.add(mesh);

    // Set the rotation
    mesh.setRotation(random_range(0, 360), random_range(0, 360), random_range(0, 360));
    
    // Choose a position far from the center
    var xx = 0, yy = 0, zz = 0;
    do {
        xx = random_range(-maxDist, maxDist);
        yy = random_range(-maxDist, maxDist);
        zz = random_range(-maxDist, maxDist);
    } until (xx * xx + yy * yy + zz * zz >= gap * gap);
    
    mesh.setPosition(xx, yy, zz); 
     
    // Set the bounding box size matching the mesh scale
    geometry.boundingBox = box3_create();
    box3_set_from_center_and_size(geometry.boundingBox, UE_MATH_VECTOR3_ZERO, vec3_create(size, size, size));
    
    // Set the bounding sphere for frustum testing
    // Radius = half diagonal of cube = size * sqrt(3) / 2
    geometry.boundingSphere = sphere_create(0, 0, 0, size * sqrt(3) / 2);
    
    mesh.updateMatrix();
}

scene.updateMatrixWorld();
