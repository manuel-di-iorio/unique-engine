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
     *   4 bytes = buffer size
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
        var size = 38 + 1 + (parent ? 37 : 1) + 2 + childrenCount * 37 + 2 + (geometry ? 37 : 1) + (material ? 37 : 1) +
          4 * 13;
        var buffer = buffer_create(size, buffer_fixed, 1);
        
        // Write the buffer size
        buffer_write(buffer, buffer_u32, size);
        
        // Write the buffer type
        buffer_write(buffer, buffer_u8, UE_BUFFER_TYPE.MESH);
        
        // Write the UUID
        buffer_write(buffer, buffer_string, uuid);
        
        // Write the children UUIDs
        buffer_write(buffer, buffer_u16, array_length(children));
        
        array_foreach(children, method({ buffer }, function(child) {
            buffer_write(buffer, buffer_string, child.uuid);
        }));
        
        // Write the visible property
        buffer_write(buffer, buffer_u8, visible);
        
        // Write the parent property (if set)
        buffer_write(buffer, buffer_string, parent ? parent.uuid : "");
        
        // Write the render order
        buffer_write(buffer, buffer_u16, renderOrder);
        
        // Write the geometry UUID
        buffer_write(buffer, buffer_string, geometry ? geometry.uuid : "");
        
        // Write the material UUID
        buffer_write(buffer, buffer_string, material ? material.uuid : "");
        
        // Write the transform (position, rotation, scale, up)
        buffer_write(buffer, buffer_u32, position.x);
        buffer_write(buffer, buffer_u32, position.y);
        buffer_write(buffer, buffer_u32, position.z);
        
        buffer_write(buffer, buffer_u32, rotation.x);
        buffer_write(buffer, buffer_u32, rotation.y);
        buffer_write(buffer, buffer_u32, rotation.z);
        buffer_write(buffer, buffer_u32, rotation.w);
        
        buffer_write(buffer, buffer_u32, scale.x);
        buffer_write(buffer, buffer_u32, scale.y);
        buffer_write(buffer, buffer_u32, scale.z);
        
        buffer_write(buffer, buffer_u32, up.x);
        buffer_write(buffer, buffer_u32, up.y);
        buffer_write(buffer, buffer_u32, up.z);
        
        return buffer;  
    }
}