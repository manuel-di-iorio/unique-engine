// EXPERIMENTAL
renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera({ x: 0, y: -200, z: 100 }).use();
controls = new UeOrbitControls(camera);

// Create geometry without building it yet (empty text)
textGeo = new UeTextGeometry("", fDemoUI, {
  //halign: fa_center,
  //valign: fa_middle,
  size: 1,
  color: c_aqua
});
  
// Create material using the font texture
textMat = new UeMaterial({ 
  shader: sh_ue_text,
  map: textGeo.getFontTexture(),
  transparent: true,
  blending: true,
  depthWrite: false,
  blendSrc: bm_one,
  blendDst: bm_inv_src_alpha,
  color: c_white,
  side: cull_noculling
});

textMesh = new UeStaticMesh(textGeo, textMat);
scene.add(textMesh);