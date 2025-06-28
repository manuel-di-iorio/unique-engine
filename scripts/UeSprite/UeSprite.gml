/// Create a billboard mesh
function UeSprite(material = new UeSpriteMaterial(), data = {}): UeMesh(undefined, data) constructor {
    self.geometry = new UePlaneGeometry(1, 1);
    self.isSprite = true;
    self.material = material;
}