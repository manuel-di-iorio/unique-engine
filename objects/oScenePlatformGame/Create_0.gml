// --- Sistema ed Engine ---
renderer = new UeRenderer({ shadowMap: { enabled: true } });
scene = new UeScene();
camera = new UePerspectiveCamera().use();
controls = new UePointerLockControls(camera, { sensitivityX: 0.1, sensitivityY: 0.1 });

// --- Parametri Player ---
playerRadius = 15;
playerHeight = 50;
player = new UeMesh(new UeCapsuleGeometry(playerRadius, playerHeight, 8, 12, 1, { 
    color: make_color_rgb(32, 67, 240)
}), undefined, { castShadow: true, receiveShadow: true });
player.geometry.computeBoundingBox();

// --- Luci ---
ambientLight = new UeAmbientLight(make_color_rgb(170, 170, 170));
dirLight = new UeDirectionalLight(make_color_rgb(255, 255, 136), 0.8, { x: 200, y: 300, z: 500, castShadow: true });
scene.add(ambientLight, dirLight, player);

// --- Fisica ---
playerVelocity = vec3_create(0, 0, 0);
_gravity      = 0.5;
jumpForce     = 12;
maxSpeed      = 6;
acceleration  = 1.5;
_friction     = 0.8;
isOnGround    = false;
coyoteTimer   = 0;
coyoteTimeMax = 10;

// --- Generazione Mondo ---
platformCubes = [];
cubeColors = [
    make_color_rgb(229, 115, 115), make_color_rgb(129, 199, 132), make_color_rgb(100, 181, 246), 
    make_color_rgb(255, 241, 118), make_color_rgb(240, 98, 146), make_color_rgb(255, 183, 77), 
    make_color_rgb(186, 104, 200), make_color_rgb(77, 182, 172)
];

function checkOverlap(nx, ny, nz, size, pPos) {
    var margin = 50;
    if (point_distance_3d(nx, ny, nz, pPos[0], pPos[1], pPos[2]) < (size + playerRadius + margin)) return true;
    for (var i = 0, il = array_length(platformCubes); i < il; i++) {
        var c = platformCubes[i];
        var bbox = c.geometry.boundingBox;
        var cSize = (bbox[3] - bbox[0]) * 0.5;
        if (abs(nx - c.position[0]) < (size + cSize + margin) &&
            abs(ny - c.position[1]) < (size + cSize + margin) &&
            abs(nz - c.position[2]) < (size + cSize + margin)) return true;
    }
    return false;
}

// Terreno e Blocchi
ground = new UeStaticMesh(new UePlaneGeometry(1500, 1500, { color: make_color_rgb(34, 139, 34) }), undefined, { receiveShadow: true });
scene.add(ground);

var numCubes = 40;
var maxAttempts = 50;
var maxPosition = 250;

for (var i = 0; i < numCubes; i++) {
    var placed = false;
    var attempts = 0;
    while (!placed && attempts < maxAttempts) {
        var cubeSize = irandom_range(30, 80);
        var halfSize = cubeSize * 0.5;
        var cubeX = irandom_range(-maxPosition, maxPosition);
        var cubeY = irandom_range(-maxPosition, maxPosition);
        var cubeZ = irandom_range(playerHeight, 600);
        
        if (!checkOverlap(cubeX, cubeY, cubeZ, halfSize, player.position)) {
            var cube = new UeStaticMesh(new UeBoxGeometry(cubeSize, cubeSize, cubeSize, { color: cubeColors[irandom(7)] }), undefined, { castShadow: true, receiveShadow: true });
            vec3_set(cube.position, cubeX, cubeY, cubeZ);
            cube.geometry.computeBoundingBox();
            cube.updateMatrix();
            cube.updateWorldMatrix();
            scene.add(cube);
            array_push(platformCubes, cube);
            placed = true;
        }
        attempts++;
    }
}

// --- Collezionabili ---
collectibles = [];
collectedCount = 0;
totalCollectibles = 10;
audio_play_sound(sndDemoPlatformBG, 1, true);

var nPlats = array_length(platformCubes);
if (nPlats > 0) {
    repeat(totalCollectibles) {
        var cube = platformCubes[irandom(nPlats - 1)];
        var ico = new UeMesh(new UeIcosahedronGeometry(15, 0, { color: c_orange }), undefined, { castShadow: true, receiveShadow: true });
        var top = cube.position[2] + (cube.geometry.boundingBox[3] - cube.geometry.boundingBox[0]) * 0.5;
        vec3_set(ico.position, cube.position[0], cube.position[1], top + 25);
        ico.geometry.computeBoundingBox();
        scene.add(ico);
        array_push(collectibles, ico);
    }
}
