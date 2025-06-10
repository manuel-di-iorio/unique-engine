/// Billboard mesh
function SpriteMesh(data = {}): SquareMesh(data) constructor {
    material = new UeSpriteMaterial({ map: data[$ "map"] });
}