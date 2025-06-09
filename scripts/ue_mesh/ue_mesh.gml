function Mesh(data = {}): Object3D(data) constructor {
    isMesh = true;
    geometry = data[$ "geometry"] ?? undefined;
    material = data[$ "material"] ?? new Material();
    primitive = pr_trianglelist;
    bbox = { x1: 0, y1: 0, z1: 0, x2: 0, y2: 0, z2: 0, x_size: 0, y_size: 0, z_size: 0 };
    
    function render(renderState) {
        var scene = renderState.scene;
        var lightState = renderState.lightState;
        
        if (scene.matrixAutoUpdate && matrixAutoUpdate) update();
        
        matrix_set(matrix_world, matrixWorld.data);
        material.use(renderState, self); 
        vertex_submit(geometry.vb, primitive, material.textures.map ?? -1);
        shader_reset();
    }
    
    function import(fname) {
        
    }
    
    function export(fname) {
        
    }
}