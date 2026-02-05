function UeSpriteMaterial(data = {}): UeMaterial(data) constructor {
  lights = 0;
  shader = sh_ue_sprite;
  alphaTest = data[$ "alphaTest"] ?? 25; // Default sprite alpha test
  transparent = data[$ "transparent"] ?? true;
  blending = transparent;
  side = data[$ "side"] ?? cull_noculling;
  
  var _color = data[$ "color"] ?? c_white;
  color = [color_get_red(_color) / 255, color_get_green(_color) / 255, color_get_blue(_color) / 255];
  uniforms.ueColor = { type: UE_UNIFORM_TYPE.VEC3, value: color };
  
  build();
}
