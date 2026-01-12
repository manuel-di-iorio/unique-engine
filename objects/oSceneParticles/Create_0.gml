//scene = new UeScene();
//camera = new UePerspectiveCamera({ x: -10, y: -100, z: 50 });
//
//renderer = new UeRenderer({
  //autoClear: true,
  //autoClearColor: c_black,
  //shadowMap: {
    //enabled: true
  //}
//});
//
//orbitControls = new UeOrbitControls(camera);
//
//// --- Environment ---
//var ambientLight = new UeAmbientLight(c_white, 0.2);
//scene.add(ambientLight);
//
//var dirLight = new UeDirectionalLight(c_white, 0.5);
//vec3_set(dirLight.position, 10, 20, 10);
//dirLight.castShadow = true;
//scene.add(dirLight);
//
//scene.add(new UeAxesHelper(10));
//
//// Ground
//var groundGeo = new UePlaneGeometry(50, 50);
//var groundMat = new UeMeshStandardMaterial({ color: #222222 });
//var ground = new UeMesh(groundGeo, groundMat);
//ground.receiveShadow = true;
//scene.add(ground);
//
//scene.add(new UeGridHelper(50, 50));
//
//// --- Particle Systems ---
//particleRenderer = new UeParticleRenderer();
//
//fireSystem = new UeParticleSystem(500);
//fireSystem.softFactor = 0.0;
//// fireSystem.castShadow = true; // Shadows disabled for now per user request
//
//smokeSystem = new UeParticleSystem(200);
//smokeSystem.softFactor = 0.0;
//// smokeSystem.castShadow = false;
//
//// 1. Fire Type
//fireType = new UeParticleType()
  //.set("life", [0.4, 0.8])
  //.set("speed", [3.0, 6.0])
  //.set("direction", [0, 360])
  //.set("pitch", [80, 100])
  //.set("size", [0.5, 1.2])
  //.set("alpha", 1.0)
  //.setColor(#FFCC00);
//
//// 2. Smoke Type
//smokeType = new UeParticleType()
  //.set("life", [1.5, 3.0])
  //.set("speed", [2.0, 4.0])
  //.set("direction", [0, 360])
  //.set("pitch", [70, 110])
  //.set("size", [1.0, 2.5])
  //.set("alpha", 0)
  //.setColor(#444444);
//
//// 3. Emitters
//fireEmitter = new UeParticleEmitter({
  //rate: 400,
  //shape: "sphere",
  //shapeSize: [0.5],
  //position: [0, 0.1, 0]
//});
//
//smokeEmitter = new UeParticleEmitter({
  //rate: 100,
  //shape: "sphere",
  //shapeSize: [1.0],
  //position: [0, 1.2, 0]
//});
//
//fireSystem.addEmitter(fireEmitter);
//smokeSystem.addEmitter(smokeEmitter);
//
//// 4. Modules (Initialization & Behavior)
//// Core modules bundled into DefaultModule
//fireSystem.addModule(new UeParticleDefaultModule(fireType));
//
//// Behavior modules
//fireSystem.addModule(new UeParticleSizeModule(-0.5));
//fireSystem.addModule(new UeParticleColorGradientModule({
    //colorStart: #FFCC00, colorMiddle: #FF4400, colorEnd: #220000,
    //alphaStart: 1.0, alphaMiddle: 0.8, alphaEnd: 0
//}));
//
//// Core modules
//smokeSystem.addModule(new UeParticleDefaultModule(smokeType));
//
//// Behavior modules
//smokeSystem.addModule(new UeParticleSizeModule(1.0));
//smokeSystem.addModule(new UeParticleColorGradientModule({
    //colorStart: #444444, colorMiddle: #222222, colorEnd: #111111,
    //alphaStart: 0, alphaMiddle: 0.3, alphaEnd: 0
//}));
//
//// --- Point Light for Fire ---
//fireLight = new UePointLight(#FF6600, 4, 15);
//vec3_set(fireLight.position, 0, 1.5, 0);
//fireLight.castShadow = true;
//scene.add(fireLight);
//
//time = 0;
