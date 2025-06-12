function UeMesh(geometry = undefined, data = {}): UeObject3D(data) constructor {
    self.isMesh = true;
    self.geometry = geometry;
    self.material = data[$ "material"] ?? new UeMeshStandardMaterial();
    self.primitive = data[$ "primitive"] ?? pr_trianglelist;
    //self.boundingBox = data[$ "boundingBox"] ?? new Box3(); // @todo
    
    function render(renderState) {
        var scene = renderState.scene;
        var lightState = renderState.lightState;
        
        if (scene.matrixAutoUpdate && matrixAutoUpdate) {
            update();
        }
        
        if (visible && geometry) {
            matrix_set(matrix_world, matrixWorld.data);
            material.use(renderState, self); 
            vertex_submit(geometry.vb, primitive, material.textures.map ?? -1);
            shader_reset();
        }
    }
    
    function import(fname) {
        
    }
    
    function export(fname) {
        
    }
}