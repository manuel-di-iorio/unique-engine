function UeDeferredGBufferMaterial(data = {}): UeMaterial(data) constructor {
  shader = sh_ue_gbuffer;
  transparent = false; // G-Buffer is only for opaque objects
  allowOverride = false;
  
  // Color
  var _color = data[$ "color"];
  if (_color != undefined) {
      color = [ color_get_red(_color)/255, color_get_green(_color)/255, color_get_blue(_color)/255 ];
  } else {
      color = [1, 1, 1];
  }
  uniforms.ueColor = { type: UE_UNIFORM_TYPE.VEC3, value: color };

  // Emissive
  var _emissive = data[$ "emissive"];
  if (_emissive != undefined) {
      emissive = [ color_get_red(_emissive)/255, color_get_green(_emissive)/255, color_get_blue(_emissive)/255 ];
  } else {
      emissive = [0, 0, 0];
  }
  uniforms.ueEmissive = { type: UE_UNIFORM_TYPE.VEC3, value: emissive };
  self.emissiveIntensity = data[$ "emissiveIntensity"] ?? 0;

  // Metalness
  metalness = data[$ "metalness"] ?? 0;
  uniforms.ueMetalness = { type: UE_UNIFORM_TYPE.FLOAT, value: metalness };

  // Roughness
  roughness = data[$ "roughness"] ?? 1;
  uniforms.ueRoughness = { type: UE_UNIFORM_TYPE.FLOAT, value: roughness };

  // AO
  aoIntensity = data[$ "aoIntensity"] ?? 1;
  aoMapIntensity = data[$ "aoMapIntensity"] ?? 1;
  uniforms.ueAoIntensity = { type: UE_UNIFORM_TYPE.FLOAT, value: aoIntensity };
  uniforms.ueAoMapIntensity = { type: UE_UNIFORM_TYPE.FLOAT, value: aoMapIntensity };

  // Normal Map
  normalMapScale = data[$ "normalMapScale"] ?? vec2_create(1, 1);
  uniforms.ueNormalMapScale = { type: UE_UNIFORM_TYPE.VEC2, value: normalMapScale };

  // Displacement
  displacementScale = data[$ "displacementScale"] ?? 0;
  displacementBias = data[$ "displacementBias"] ?? 0;
  uniforms.ueDisplacementScale = { type: UE_UNIFORM_TYPE.FLOAT, value: displacementScale };
  uniforms.ueDisplacementBias = { type: UE_UNIFORM_TYPE.FLOAT, value: displacementBias };

  // Flat Shading
  flatShading = data[$ "flatShading"] ?? false;
  uniforms.ueFlatShading = { type: UE_UNIFORM_TYPE.FLOAT, value: flatShading };

  // Receive Shadow
  receiveShadow = data[$ "receiveShadow"] ?? true;
  uniforms.ueReceiveShadow = { type: UE_UNIFORM_TYPE.FLOAT, value: receiveShadow };

  /** === Textures === */
  textures.alphaMap = data[$ "alphaMap"];
  textures.ormMap = data[$ "ormMap"];
  textures.normalMap = data[$ "normalMap"];
  textures.emissiveMap = data[$ "emissiveMap"];
  textures.displacementMap = data[$ "displacementMap"];

  build();
}
