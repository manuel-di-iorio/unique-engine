function Mesh(data = {}): Object3D(data) constructor {
    type = "Mesh";
    geometry = data[$ "geometry"] ?? undefined;
    material = data[$ "material"] ?? new Material({ shader: ue_shader_light });
    primitive = pr_trianglelist;
    bbox = { x1: 0, y1: 0, z1: 0, x2: 0, y2: 0, z2: 0, x_size: 0, y_size: 0, z_size: 0 };
    
    function update() {
        transform();
        
        for (var i = 0, len = array_length(children); i < len; i++) {
            var child = children[i];
            child.update();
        }
    };
    
    function render(lightState) {
        if (!visible) return;

        if (matrixAutoUpdate) update();
        matrix_set(matrix_world, matrix.data);
        material.use(lightState);
        vertex_submit(geometry.vb, primitive, material.textures.map ?? -1);
        shader_reset();

        // Recursively render the children
        for (var i = 0, len = array_length(children); i < len; i++) {
            var child = children[i];
            child.render(lightState);
        }
    }
}