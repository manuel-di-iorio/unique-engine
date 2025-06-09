/// Billboard
function SpriteMesh(data = {}): SquareMesh(data) constructor {
    material = new Material({ 
        map: data[$ "map"],
        shader: ue_shader_sprite, 
        lights: false,
        transparent: data[$ "transparent"] ?? true
    });
}

