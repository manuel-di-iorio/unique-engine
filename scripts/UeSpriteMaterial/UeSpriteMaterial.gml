function UeSpriteMaterial(data = {}): UeMaterial(data) constructor {
  lights = 0;
  shader = sh_ue_sprite;
  transparent = data[$ "transparent"] ?? true;
  blending = transparent;
  build();
}