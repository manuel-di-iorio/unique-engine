function UeMeshStandardMaterial(data = {}): UeMaterial(data) constructor {
  var cfg = __uniformNamesConfig;
  
  shader = sh_ue_standard;
  
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
  uniforms.ueEmissiveIntensity = { type: UE_UNIFORM_TYPE.FLOAT, value: data[$ "emissiveIntensity"] ?? 0 };

  // AO
  aoIntensity = data[$ "aoIntensity"] ?? 1;
  aoMapIntensity = data[$ "aoMapIntensity"] ?? 1;
  uniforms.ueAoIntensity = { type: UE_UNIFORM_TYPE.FLOAT, value: aoIntensity };
  uniforms.ueAoMapIntensity = { type: UE_UNIFORM_TYPE.FLOAT, value: aoMapIntensity };
  
  // Bump
  bumpScale = data[$ "bumpScale"] ?? 1;
  uniforms.ueBumpScale = { type: UE_UNIFORM_TYPE.FLOAT, value: bumpScale };

  // Displacement
  displacementScale = data[$ "displacementScale"] ?? 0;
  displacementBias = data[$ "displacementBias"] ?? 0;
  uniforms.ueDisplacementScale = { type: UE_UNIFORM_TYPE.FLOAT, value: displacementScale };
  uniforms.ueDisplacementBias = { type: UE_UNIFORM_TYPE.FLOAT, value: displacementBias };
  
  // Light Map
  lightMapIntensity = data[$ "lightMapIntensity"] ?? 1;
  uniforms.ueLightMapIntensity = { type: UE_UNIFORM_TYPE.FLOAT, value: lightMapIntensity };
  
  // Metalness
  metalness = data[$ "metalness"] ?? 0;
  uniforms.ueMetalness = { type: UE_UNIFORM_TYPE.FLOAT, value: metalness };

  // Roughness
  roughness = data[$ "roughness"] ?? 1;
  uniforms.ueRoughness = { type: UE_UNIFORM_TYPE.FLOAT, value: roughness };

  // Normal Map
  normalMapScale = data[$ "normalMapScale"] ?? vec2_create(1, 1);
  uniforms.ueNormalMapScale = { type: UE_UNIFORM_TYPE.VEC2, value: normalMapScale };
  
  // Env Map
  envMapIntensity = data[$ "envMapIntensity"] ?? 1;
  envMapRotation = data[$ "envMapRotation"] ?? euler_create();
  uniforms.ueEnvMapIntensity = { type: UE_UNIFORM_TYPE.FLOAT, value: envMapIntensity };
  uniforms.ueEnvMapRotation = { type: UE_UNIFORM_TYPE.VEC3, value: envMapRotation };

  // Flat Shading
  flatShading = data[$ "flatShading"] ?? false;
  uniforms.ueFlatShading = { type: UE_UNIFORM_TYPE.FLOAT, value: flatShading };

  // Fog
  fog = data[$ "fog"] ?? true;

  /** === Textures === */
  textures.emissiveMap = data[$ "emissiveMap"];
  textures.alphaMap = data[$ "alphaMap"];
  textures.normalMap = data[$ "normalMap"];  
  textures.ormMap = data[$ "ormMap"];
  textures.displacementMap = data[$ "displacementMap"];
//   textures.lightMap = data[$ "lightMap"];
//   textures.envMap = data[$ "envMap"] ?? global.UE_TEXTURE_DEFAULT_BLACK;
  
  build();
}
