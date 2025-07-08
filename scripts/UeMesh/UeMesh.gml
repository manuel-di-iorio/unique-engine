function UeMesh(geometry = undefined, data = {}): UeObject3D(data) constructor {
    self.isMesh = true;
    self.type = "Mesh";
    self.geometry = geometry ?? data[$ "geometry"];
    self.material = data[$ "material"] ?? global.UE_MESH_STANDARD_MATERIAL;
    self.primitive = data[$ "primitive"] ?? pr_trianglelist;
    //self.boundingBox = data[$ "boundingBox"] ?? new UeBox3(); // @todo
    
    function render(renderState) {
        var scene = renderState.scene;
        var lightState = renderState.lightState;
        
        if (scene.matrixAutoUpdate && matrixAutoUpdate) {
            update();
        }
        
        if (visible && geometry) {
            matrix_set(matrix_world, matrixWorld.data);
            material.use(renderState, self);
            vertex_submit(geometry.vb, primitive, material.textures[$ "map"] ?? -1);
            shader_reset();
        }
    }
    
    /** Internal export methods */
    function _compileData(data) {
        var _self = self;
        var payload = {
            children: array_map(children, function(child) { return child.uuid }),
            // Props:
            visible,
            parent: parent ? parent.uuid : undefined,
            renderOrder,
            geometry: geometry ? geometry.uuid : undefined,
            material: material ? material.uuid : undefined,
            
            px: position.x,
            py: position.y,
            pz: position.z,
            
            rx: rotation.x,
            ry: rotation.y,
            rz: rotation.z, 
            rw: rotation.w,
            
            sx: scale.x,
            sy: scale.y,
            sz: scale.z,
            
            ux: up.x,
            uy: up.y,
            uz: up.z,
        };
        
        return { obj: _self, payload };
    }
}