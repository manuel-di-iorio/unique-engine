renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: -10, z: 50 });

// Create the raycaster
raycaster = new UeRaycaster();

// Create the debug hit sphere
var hitSphereGeom = new UeSphereGeometry(2, { color: c_yellow });
hitSphere = new UeStaticMesh(hitSphereGeom, new UeMeshBasicMaterial(), { visible: false });
scene.add(hitSphere);

scene.add(new UeGridHelper(500));

axesHelper = new UeAxesHelper(50);
axesHelper.geometry.boundingSphere = new UeSphere(UE_VECTOR3_ZERO, 100);
scene.add(axesHelper);
