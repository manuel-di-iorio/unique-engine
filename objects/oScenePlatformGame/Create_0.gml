// --- Sistema ed Engine ---
renderer = new UeRenderer({ 
  toneMapping: UE_TONE_MAPPING.NEUTRAL
});
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
player.geometry.computeBoundingSphere();

// --- Luci ---
ambientLight = new UeAmbientLight(make_color_rgb(120, 160, 180), { intensity: 0.35 });
dirLight = new UeDirectionalLight(make_color_rgb(255, 245, 230), 1.0, {
  castShadow: true,
  shadow: {
    left: -1000,
    right: 1000,
    top: -1000,
    bottom: 1000,
    far: 3000,
    mapWidth: 2048,
    mapHeight: 2048
  }
});
vec3_set(dirLight.position, 400, 800, 300);
scene.add(ambientLight, dirLight, player);

// --- Fisica ---
playerVelocity = vec3_create(0, 0, 0);
_gravity = 0.5;
jumpForce = 12;
maxSpeed = 6;
acceleration = 1.5;
_friction = 0.8;
isOnGround = false;
coyoteTimer = 0;
coyoteTimeMax = 15;

// --- Generazione Mondo ---
platformCubes = [];
cubeColors = [
    make_color_rgb(229, 115, 115), make_color_rgb(129, 199, 132), make_color_rgb(100, 181, 246),
    make_color_rgb(255, 241, 118), make_color_rgb(240, 98, 146), make_color_rgb(255, 183, 77),
    make_color_rgb(186, 104, 200), make_color_rgb(77, 182, 172)
];

function checkOverlap(nx, ny, nz, radius, pPos) {
    var margin = 60; // Slightly increased for non-uniform shapes
    if (point_distance_3d(nx, ny, nz, pPos[0], pPos[1], pPos[2]) < (radius + playerRadius + margin)) return true;
    for (var i = 0, il = array_length(platformCubes); i < il; i++) {
        var c = platformCubes[i];
        var bSphere = c.geometry.boundingSphere;
        var rSum = radius + bSphere[SPHERE.r] + margin;
        if (point_distance_3d(nx, ny, nz, c.position[0], c.position[1], c.position[2]) < rSum) return true;
    }
    return false;
}

// Terreno e Blocchi
var groundMat = new UeMeshStandardMaterial({
    color: make_color_rgb(100, 140, 100),
    roughness: 0.8,
    metalness: 0.1
});
ground = new UeStaticMesh(new UePlaneGeometry(2500, 2500), groundMat, { receiveShadow: true });
scene.add(ground);

var numCubes = 40;
var maxAttempts = 50;
var maxPosition = 400;

var cubeMat = new UeMeshStandardMaterial({
    roughness: 1.0,
    metalness: 0.0
});

for (var i = 0; i < numCubes; i++) {
    var placed = false;
    var attempts = 0;
    while (!placed && attempts < maxAttempts) {
        attempts++;
        var w = irandom_range(60, 150);
        var d = irandom_range(60, 150);
        var h = irandom_range(40, 100);
        
        // Correct bounding radius for non-uniform box
        var radius = 0.5 * sqrt(w*w + d*d + h*h);
        
        var cubeX = irandom_range(-maxPosition, maxPosition);
        var cubeY = irandom_range(-maxPosition, maxPosition);
        var cubeZ = irandom_range(playerHeight + 20, 700);

        if (!checkOverlap(cubeX, cubeY, cubeZ, radius, player.position)) {
            var cube = new UeStaticMesh(new UeBoxGeometry(w, d, h, { color: cubeColors[irandom(7)] }), cubeMat, { castShadow: true, receiveShadow: true });
            vec3_set(cube.position, cubeX, cubeY, cubeZ);

            // Varietà: Evita allineamenti perfetti (±2°)
            cube.setRotation(random_range(-2, 2), random_range(-2, 2), random_range(-2, 2));

            // Scala random (0.98 - 1.02)
            var s = random_range(0.98, 1.02);
            vec3_set(cube.scale, s, s, s);

            cube.geometry.computeBoundingBox();
            cube.geometry.computeBoundingSphere();
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
    var goldMat = new UeMeshStandardMaterial({
        color: make_color_rgb(255, 200, 40),
        roughness: 0.3,
        metalness: 0.8
    });

    repeat(totalCollectibles) {
        var cube = platformCubes[irandom(nPlats - 1)];
        // Importante: colore caldo e materiale più brillante (gold)
        var ico = new UeMesh(new UeIcosahedronGeometry(20, 0), goldMat, { castShadow: true, receiveShadow: true });

        var bbox = cube.geometry.boundingBox;
        var top = cube.position[2] + (bbox[3] - bbox[0]) * 0.5;
        vec3_set(ico.position, cube.position[0], cube.position[1], top + 35);
        ico.geometry.computeBoundingBox();
        ico.geometry.computeBoundingSphere();
        scene.add(ico);
        array_push(collectibles, ico);
    }
}
