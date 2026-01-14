scene = new UeScene();
camera = new UePerspectiveCamera({ x: -10, y: -300, z: 50 }).use();

renderer = new UeRenderer();

orbitControls = new UeOrbitControls(camera);

// --- Environment ---
var ambientLight = new UeAmbientLight(c_white, 0.2);
scene.add(ambientLight);

var dirLight = new UeDirectionalLight(c_white, 0.5);
vec3_set(dirLight.position, 10, 20, 10);
scene.add(dirLight);

scene.add(new UeGridHelper(500));

// --- Particles ---
ps = new UeParticleSystem();
ps.setPosition(0, 0, 10);

// Smoke
var smokeType = new UeParticleType()
  .setLife(2.5, 4.0)
  .setSpeed(30, 50, 3, 20, -2)
  .setDirection(0, 360, 0, 40)
  .setSize(50, 100, 50)
  .setRotation(0, 360, 30, 5)
  .setColor($333333, $111111)
  .setAlpha(0.3, 0.0)
  .setShape("smoke");

var smokeEmitter = new UeParticleEmitter(800);
smokeEmitter.region("box", -25, -25, 30, 25, 25, 50);
smokeEmitter.stream(smokeType, 35);

// Fire
var fireType = new UeParticleType()
  .setLife(0.3, 0.6)
  .setSpeed(130, 220, 8, 20, -60, 0, 50, 15)
  .setDirection(0, 360, 0, 60)
  .setSize(45, 75, -40, 20)
  .setRotation(0, 360, 350, 150)
  .setColor($55DDFF, $0044FF)
  .setAlpha(1.0, 0.0)
  .setAdditive(true)
  .setGravity(35)
  .setShape("smoke");

var fireEmitter = new UeParticleEmitter(1500);
fireEmitter.region("box", -15, -15, 0, 15, 15, 5);
fireEmitter.stream(fireType, 550);

// Embers
var emberType = new UeParticleType()
  .setLife(1.2, 2.5)
  .setSpeed(60, 150, 15, 50, 0, 0, 0, 30)
  .setDirection(0, 360, 50, 20)
  .setSize(3, 6, -3)
  .setColor($00CCFF, $0033FF)
  .setAlpha(1.0, 0.0)
  .setAdditive(true)
  .setGravity(15);

var emberEmitter = new UeParticleEmitter(400);
emberEmitter.region("box", -25, -25, 0, 25, 25, 15);
emberEmitter.stream(emberType, 60);

ps.addEmitter(smokeEmitter);
ps.addEmitter(fireEmitter);
ps.addEmitter(emberEmitter);