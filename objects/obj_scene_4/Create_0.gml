renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera()//{ z: 100 });

orbitControls = new UeOrbitControls(camera, {
    autoRotate: true, 
    autoRotateSpeed: .1,
    enablePan: false,
    enableRotate: false,
    enableZoom: false,
});

// Lightning
ambientLight = new UeAmbientLight(#888888);
dirLight = new UeDirectionalLight(-100, 50, 70);
scene.add(ambientLight, dirLight);

// Create the raycaster
raycaster = new UeRaycaster();

// Create the random boxes
for (var i = 0; i < 1; i++) {
    var color = make_color_rgb(irandom_range(60, 255), irandom_range(60, 255), irandom_range(60, 255));
    var size = random_range(30, 40);
    var geometry = new UeBoxGeometry(size, size, size, { color });
    var mesh = new UeMesh(geometry);

    // Choose a position far from the camera XY
    var maxDist = 0//350;
    var gap = 50;
    var xx = (irandom(1) == 0) ? random_range(-maxDist, -gap) : random_range(gap, maxDist);
    var yy = (irandom(1) == 0) ? random_range(-maxDist, -gap) : random_range(gap, maxDist);
    var zz = (irandom(1) == 0) ? random_range(-maxDist, 0) : random_range(0, maxDist); 
    mesh.setPosition(xx, yy, zz); 
    
    // Set the rotation
    //mesh.setRotation(random_range(0, 360), random_range(0, 360), random_range(0, 360));
     
    // Set the scale
    
    //mesh.setScale(scale, scale, scale);
    
    // Set the bounding box size matching the mesh scale
    geometry.computeBoundingBox();
    
    mesh.bbox = new UeBoxHelper(mesh)
    scene.add(mesh.bbox);
   
    //geometry.boundingBox.set(new UeVector3(0, 0, 0), new UeVector3(scale, scale, scale));
    //geometry.boundingBox.setFromCenterAndSize(new UeVector3(scale/2, scale/2, scale/2), new UeVector3(scale, scale, scale));
    
    scene.add(mesh);
}