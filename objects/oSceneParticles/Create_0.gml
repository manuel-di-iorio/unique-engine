scene = new UeScene();
camera = new UePerspectiveCamera({ y: 5, z: 15, yt: 2 });

renderer = new UeRenderer({
  shadowMap: {
    enabled: true
  }
});

orbitControls = new UeOrbitControls(camera);

// --- Environment ---
var ambientLight = new UeAmbientLight(c_white, 0.2);
scene.add(ambientLight);

var dirLight = new UeDirectionalLight(c_white, 0.5);
vec3_set(dirLight.position, 10, 20, 10);
dirLight.castShadow = true;
scene.add(dirLight);

scene.add(new UeAxesHelper(50));

// Ground
var groundGeo = new UePlaneGeometry(20, 20);
var groundMat = new UeMeshStandardMaterial({ color: #222222 });
var ground = new UeMesh(groundGeo, groundMat);
ground.receiveShadow = true;
scene.add(ground);

scene.add(new UeGridHelper(20, 20));

// --- Particle Systems ---
fireSystem = new UeParticleSystem(new UeParticlePool(500));
fireSystem.softFactor = 5.0;
fireSystem.castShadow = true;
scene.add(fireSystem);

smokeSystem = new UeParticleSystem(new UeParticlePool(200));
smokeSystem.softFactor = 5.0;
smokeSystem.castShadow = false;
scene.add(smokeSystem);

// 1. Fire Type
fireType = new UeParticleType()
  .setLife(0.5, 1.0)
  .setSpeed(2.0, 4.0)
  .setDirection(85, 95)
  .setSize(0.4, 0.8, -0.2)
  .setAlpha(1.0, 0.5, 0)
  .setColor(#FFCC00, #FF4400, #220000);
fireType.useColorMix = true;
fireType.useAlphaMix = true;

// 2. Smoke Type
smokeType = new UeParticleType()
  .setLife(2.0, 4.0)
  .setSpeed(1.0, 2.0)
  .setDirection(80, 100)
  .setSize(0.8, 1.5, 0.5)
  .setAlpha(0, 0.4, 0)
  .setColor(#444444, #222222, #111111);
smokeType.useColorMix = true;
smokeType.useAlphaMix = true;

// 3. Emitters
fireEmitter = new UeParticleEmitter(fireType, {
  rate: 120,
  shape: "sphere",
  shapeSize: [0.3],
  position: [0, 0.1, 0],
  castShadow: true,
  receiveShadow: false
});

smokeEmitter = new UeParticleEmitter(smokeType, {
  rate: 30,
  shape: "sphere",
  shapeSize: [0.6],
  position: [0, 1.2, 0],
  castShadow: false,
  receiveShadow: true
});

fireSystem.addEmitter(fireEmitter);
smokeSystem.addEmitter(smokeEmitter);

fireSystem.addModule(new UeParticleTypeUpdate(fireType));
smokeSystem.addModule(new UeParticleTypeUpdate(smokeType));

// --- Point Light for Fire ---
fireLight = new UePointLight(#FF6600, 4, 15);
vec3_set(fireLight.position, 0, 1.5, 0);
fireLight.castShadow = true;
scene.add(fireLight);

time = 0;
