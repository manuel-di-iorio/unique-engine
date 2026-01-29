/// Create a billboard mesh
function UeSprite(material = new UeSpriteMaterial(), data = {}): UeMesh(undefined, material, data) constructor {
    self.isSprite = true;
    self.geometry = new UePlaneGeometry();
    self.lockHorizontal = data[$ "lockHorizontal"] ?? false;
    self.lockVertical = data[$ "lockVertical"] ?? false;
}
