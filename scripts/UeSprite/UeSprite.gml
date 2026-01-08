/// Create a billboard mesh
function UeSprite(material = new UeSpriteMaterial(), data = {}): UeMesh(undefined, material, data) constructor {
    isSprite = true;
    self.geometry = new UePlaneGeometry();
    self.isSprite = true;
}