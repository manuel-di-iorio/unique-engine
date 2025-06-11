function SpriteMaterial(data = {}): Material(data) constructor {
    textures.map = data[$ "map"];
    shader = sh_ue_sprite;
    lights = false;
    transparent = data[$ "transparent"] ?? true;
}