controls.update();

// 1. Input e Movimento
var mx = keyboard_check(ord("D")) - keyboard_check(ord("A"));
var my = keyboard_check(ord("W")) - keyboard_check(ord("S"));
var jump = keyboard_check_pressed(vk_space);
var _y = controls.yaw;

// Vettori direzione basati su camera yaw (Z-up: X=right, Y=forward, Z=up)
var fwdX = dcos(_y), fwdY = dsin(_y);
var rigX = fwdY, rigY = -fwdX; 

var targetVX = (fwdX * my + rigX * mx) * maxSpeed;
var targetVY = (fwdY * my + rigY * mx) * maxSpeed;

playerVelocity[VEC3.x] = lerp(playerVelocity[VEC3.x], targetVX, (mx != 0 || my != 0) ? 0.2 : 0.15);
playerVelocity[VEC3.y] = lerp(playerVelocity[VEC3.y], targetVY, (mx != 0 || my != 0) ? 0.2 : 0.15);
playerVelocity[VEC3.z] -= _gravity;

// Jump e Coyote Time
if (isOnGround) coyoteTimer = coyoteTimeMax; else if (coyoteTimer > 0) coyoteTimer--;
if (jump && coyoteTimer > 0) {
    playerVelocity[VEC3.z] = jumpForce;
    isOnGround = false;
    coyoteTimer = 0;
    audio_play_sound(sndDemoPlatformJump, 5, false);
}

// 2. Integrazione e Collisioni
vec3_add(player.position, playerVelocity);
isOnGround = false;

// Broad-phase + Resolution
var radius = 15;
var cyHeight = 25; 
var capsule = global.UE_CAPSULE_TEMP0;
capsule[0] = player.position[VEC3.x]; capsule[1] = player.position[VEC3.y]; capsule[2] = player.position[VEC3.z] - cyHeight;
capsule[3] = player.position[VEC3.x]; capsule[4] = player.position[VEC3.y]; capsule[5] = player.position[VEC3.z] + cyHeight;
capsule[6] = radius;

var push = global.UE_VEC3_TEMP0;
var nCubes = array_length(platformCubes);
for(var i = 0; i < nCubes; i++) {
    var c = platformCubes[i];
    
    // Broad-phase: Check distanza al quadrato
    var dx = player.position[VEC3.x] - c.position[VEC3.x];
    var dy = player.position[VEC3.y] - c.position[VEC3.y];
    var dz = player.position[VEC3.z] - c.position[VEC3.z];
    if ((dx*dx + dy*dy + dz*dz) > 22500) continue; 
    
    var box = global.UE_BOX3_TEMP1;
    box3_copy(box, c.geometry.boundingBox);
    box3_translate(box, c.position);
    
    if (capsule_intersects_box(capsule, box, push)) {
        player.position[VEC3.x] += push[VEC3.x];
        player.position[VEC3.y] += push[VEC3.y];
        player.position[VEC3.z] += push[VEC3.z];
        if (push[VEC3.z] > 0) isOnGround = true;
        else if (push[VEC3.z] < 0 && playerVelocity[VEC3.z] > 0) playerVelocity[VEC3.z] = 0;
        
        // Aggiorna capsula per collisioni successive nello stesso frame
        capsule[0] = player.position[VEC3.x]; capsule[1] = player.position[VEC3.y]; capsule[2] = player.position[VEC3.z] - cyHeight;
        capsule[3] = player.position[VEC3.x]; capsule[4] = player.position[VEC3.y]; capsule[5] = player.position[VEC3.z] + cyHeight;
    }
}

// Ground check (Floor infinito o terreno verde a Z=0)
if (player.position[VEC3.z] < 40) {
    if (playerVelocity[VEC3.z] < -2 && !isOnGround) audio_play_sound(sndDemoPlatformFalling, 3, false);
    player.position[VEC3.z] = 40;
    playerVelocity[VEC3.z] = 0;
    isOnGround = true;
} 
if (isOnGround) playerVelocity[VEC3.z] = 0;

// Out of bounds check
if (player.position[VEC3.x] < -1250) player.position[VEC3.x] = -1250;
if (player.position[VEC3.y] < -1250) player.position[VEC3.y] = -1250;
if (player.position[VEC3.x] > 1250) player.position[VEC3.x] = 1250;
if (player.position[VEC3.y] > 1250) player.position[VEC3.y] = 1250;

// 3. Raccolta Collezionabili
var pBox = global.UE_BOX3_TEMP1;
box3_copy(pBox, player.geometry.boundingBox);
box3_expand_by_scalar(pBox, 10);
box3_translate(pBox, player.position);

for (var i = array_length(collectibles) - 1; i >= 0; i--) {
    var ico = collectibles[i];
    ico.rotateX(0.7); ico.rotateZ(1.1); // Animazione rotazione
    
    var iSphere = global.UE_SPHERE_TEMP0;
    sphere_copy(iSphere, ico.geometry.boundingSphere);
    sphere_translate(iSphere, ico.position);
    
    if (sphere_intersects_box(iSphere, pBox)) {
        scene.remove(ico);
        array_delete(collectibles, i, 1);
        collectedCount++;
        audio_play_sound(sndDemoPlatformCollect, 5, false);
        if (collectedCount == totalCollectibles) audio_play_sound(sndDemoPlatformWin, 10, false);
    }
}

// 4. Camera OTS Sync
var camDist = 180, latOff = 35, tH = 60;
var p = controls.pitch;
var cP = dcos(p);
var dX = cP * dcos(_y), dY = cP * dsin(_y), dZ = dsin(p);
var rX = dY, rY = -dX; // Right vector (Forward x Up)

var tx = player.position[VEC3.x], ty = player.position[VEC3.y], tz = player.position[VEC3.z] + tH;
vec3_set(camera.position, tx - dX*camDist + rX*latOff, ty - dY*camDist + rY*latOff, tz - dZ*camDist);
vec3_set(camera.target, tx + rX*latOff, ty + rY*latOff, tz);
quat_set_from_axis_angle(player.rotation, [0,0,1], _y);
