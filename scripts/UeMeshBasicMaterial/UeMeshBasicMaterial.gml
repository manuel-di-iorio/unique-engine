function MeshBasicMaterial(data = {}): Material(data) constructor {
    lights = 0;
    shader = sh_ue_basic;
    build();
}