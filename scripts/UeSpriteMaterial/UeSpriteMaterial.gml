function UeSpriteMaterial(data = {}): UeMaterial(data) constructor {
    shader = sh_ue_sprite;
    lights = false;
    transparent = data[$ "transparent"] ?? true;
    build();
}