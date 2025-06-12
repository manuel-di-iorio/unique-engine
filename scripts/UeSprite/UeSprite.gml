/// Create a billboard mesh
function UeSprite(material = new UeSpriteMaterial(), data = {}): UeMesh(data) constructor {
    self.isSprite = true;
    self.geometry = new PlaneGeometry(1, 1);
    self.material = material;
}