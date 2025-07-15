renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera()//{ z: 100 });

orbitControls = new UeOrbitControls(camera, {
    //autoRotate: true, 
    //autoRotateSpeed: .1,
    //enablePan: false,
    //enableRotate: false,
    //enableZoom: false,
});

// Lightning
ambientLight = new UeAmbientLight(#888888);
dirLight = new UeDirectionalLight(-100, 50, 70);
scene.add(ambientLight, dirLight);

// Create the raycaster
raycaster = new UeRaycaster();

// Create the random boxes
var maxDist = 0//350;
var gap = 50;
var vecZero = new UeVector3(0, 0, 0);

for (var i = 0; i < 1; i++) {
    var color = make_color_rgb(irandom_range(60, 255), irandom_range(60, 255), irandom_range(60, 255));
    var size = random_range(30, 40);
    var geometry = new UeBoxGeometry(size, size, size, { color });
    var mesh = new UeMesh(geometry);
    scene.add(mesh);
    
    // Choose a position far from the camera XY
    var xx = 50//(irandom(1) == 0) ? random_range(-maxDist, -gap) : random_range(gap, maxDist);
    var yy = 50//(irandom(1) == 0) ? random_range(-maxDist, -gap) : random_range(gap, maxDist);
    var zz = 0//(irandom(1) == 0) ? random_range(-maxDist, 0) : random_range(0, maxDist); 
    mesh.setPosition(xx, yy, zz);
    
    // Set the rotation
    //mesh.setRotation(random_range(0, 360), random_range(0, 360), random_range(0, 360));
    
    // Set the bounding box size matching the mesh scale
    //geometry.boundingBox.sizeMin = new UeVector3(-size/2, -size/2, -size/2)
    //geometry.boundingBox.sizeMax = new UeVector3(size/2, size/2, size/2)
    geometry.boundingBox.setFromCenterAndSize(vecZero, new UeVector3(size, size, size));
    
    mesh.bbox = new UeBoxHelper(mesh, c_yellow, { visible: false });
    scene.add(mesh.bbox);
}

// Create the ray arrow helper
raycaster.setFromCamera(device_mouse_x_to_gui(0), device_mouse_y_to_gui(0), camera);

raycasterRay = raycaster.ray;
rayArrowHelper = new UeArrowHelper(raycasterRay.direction, raycasterRay.origin, 250);
scene.add(rayArrowHelper);

scene.add(new UeLine(new UeLineGeometry({ color: c_red }).setPositions([0,0,-size/2, 0, 0, size/2])));
scene.add(new UeLine(new UeLineGeometry({ color: c_green }).setPositions([0,-size/2, 0, 0, size/2, 0])));
scene.add(new UeLine(new UeLineGeometry({ color: c_blue }).setPositions([-size/2, 0, 0, size/2, 0, 0])));
