renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera();
camera.use();

orbitControls = new UeOrbitControls(camera, {
    autoRotate: true, 
    autoRotateSpeed: .1,
    enablePan: false,
    enableRotate: false,
    enableZoom: false,
});

// Lightning
ambientLight = new UeAmbientLight(#888888);
dirLight = new UeDirectionalLight(90, 45, { color: #FFFFC8, intensity: .8 });
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
materialDefault.uniforms.ueEmissive.value = [0.8, 0.8, 0];
materialDefault.uniforms.ueEmissiveIntensity.value = 0;

materialSelected = new UeMeshStandardMaterial();
materialSelected.uniforms.ueEmissive.value = [0.8, 0.8, 0];
materialSelected.uniforms.ueEmissiveIntensity.value = 1;

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
    geometry.boundingBox = new UeBox3();
    geometry.boundingBox.setFromCenterAndSize(UE_VECTOR3_ZERO, new UeVector3(size, size, size));
    
    // Set the bounding sphere for frustum testing
    geometry.boundingSphere = new UeSphere(UE_VECTOR3_ZERO, size);
    
    mesh.updateMatrix();
}

scene.updateWorldMatrix(false, true);
