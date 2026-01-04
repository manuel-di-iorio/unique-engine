function UeNormalsMaterial(data = {}): UeMaterial(data) constructor {
  lights = 0;
  shader = sh_ue_normals;
  build();
}