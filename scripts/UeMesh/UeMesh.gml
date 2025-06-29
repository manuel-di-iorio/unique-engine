function UeMesh(geometry = undefined, data = {}): UeObject3D(data) constructor {
    self.isMesh = true;
    self.geometry = geometry ?? data[$ "geometry"];
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
            vertex_submit(geometry.vb, primitive, material.textures[$ "map"] ?? -1);
            shader_reset();
        }
    }
    
     /**
     * Export the mesh properties to a buffer
     * 
     * Structure:
     *   1 byte = buffer type
     *   37 bytes = UUID
     *   1 byte = visible
     *   37 bytes = parent UUID
     *   2 bytes = render order
     *   37 bytes = geometry UUID
     *   37 bytes = material UUID
     */
    function export() {
        var childrenCount = array_length(children);
        var size = 38 + 1 + (parent ? 37 : 1) + childrenCount * 37 + 2 + (geometry ? 37 : 1) + (material ? 37 : 1) + 1;
        var buffer = buffer_create(size, buffer_fast, 1);
        
        // Write the buffer type
        buffer_write(buffer, buffer_u8, UE_BUFFER_TYPE.MESH);
        
        // Write the UUID
        buffer_write(buffer, buffer_string, uuid);
        
        // Write the visible property
        buffer_write(buffer, buffer_u8, visible);
        
        // Write the parent property (if set)
        buffer_write(buffer, buffer_string, parent ? parent.uuid : "");
        
        // Write the children UUIDs
        array_foreach(children, method(buffer, function(child) {
            buffer_write(self, buffer_string, child.uuid);
        }));
        
        // Write the render order
        buffer_write(buffer, buffer_u16, renderOrder);
        
        // Write the geometry UUID
        buffer_write(buffer, buffer_string, geometry ? geometry.uuid : "");
        
        // Write the material UUID
        buffer_write(buffer, buffer_string, material ? material.uuid : "");
        
        return buffer;  
    }
}