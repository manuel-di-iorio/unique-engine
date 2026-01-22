renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 0, y: -200, z: 100 }).use();
camera.lookAt(0, 0, 0);
controls = new UeOrbitControls(camera);

// Create text geometry
textGeo = new UeTextGeometry("Hello Unique Engine!\n3D Text is here.", fText, {
    halign: fa_center,
    valign: fa_middle,
    size: 0.5,
    color: c_aqua
});

// Create material using the font texture
var fontInfo = font_get_info(fText);
textMat = new UeMeshBasicMaterial({ 
    map: new UeTexture(),
    transparent: true,
    blending: true,
    side: cull_noculling,
    color: c_aqua,
    emissive: c_aqua,
    emissiveIntensity: 1.0
});

// Since we created an empty UeTexture, we need to set its internal handle
textMat.textures.map.__cachedTexture = fontInfo.texture;
textMat.build(); // Rebuild to catch the custom manual texture assignment

textMesh = new UeStaticMesh(textGeo, textMat);
scene.add(textMesh);

ambientLight = new UeAmbientLight(c_white, 1.0);
scene.add(ambientLight);
