function UeLine(geometry = undefined, material = undefined, data = {}): UeMesh(geometry, material, data) constructor {
    isLine = true;
    primitive = pr_linestrip;
    self.geometry = geometry ?? new UeBufferGeometry();
    self.material = material ?? new UeLineBasicMaterial();
}