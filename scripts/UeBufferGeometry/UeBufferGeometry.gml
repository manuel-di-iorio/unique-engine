function UeBufferGeometry(data = {}) constructor {
    isBufferGeometry = true;                     // Flag to identify this as a buffer geometry
    type = "BufferGeometry";                      // Type identifier string
    uuid = ueUuid();                              // Unique identifier for this geometry instance
    name = data[$ "name"] ?? undefined;           // Optional name for the geometry
    vertices = data[$ "vertices"] ?? [];          // Array of vertex data
    index = data[$ "index"] ?? undefined;         // Optional index array for indexed geometry
    format = data[$ "format"] ?? global.UE_DEFAULT_VERTEX_FORMAT; // Vertex format description
    vb = undefined;                               // Vertex buffer handle (created on build)
    canFreeze = data[$ "canFreeze"] ?? true;      // Flag whether vertex buffer can be frozen (optimized)

    // Axis-aligned bounding box for the geometry (auto-calculated or provided)
    boundingBox = data[$ "boundingBox"] ?? new UeBox3();
    
    // Bounding sphere for the geometry (auto-calculated or provided)
    boundingSphere = data[$ "boundingSphere"] ?? new UeSphere();

    // Build the vertex buffer from vertices and format
    function build() {
        vb = vertex_create_buffer();               // Create a new vertex buffer
        vertex_begin(vb, format.vf);               // Begin vertex buffer with format flags
        var attrs = format.attrs;                   // Attributes defined by the format
        
        var useIndex = is_array(index);             // Check if geometry uses indexed vertices
        var ilen = array_length(useIndex ? index : vertices);
        
        // Iterate through vertices or indices
        for (var i = 0; i < ilen; i++) {
            var vertex = vertices[useIndex ? index[i] : i];
            
            // Add vertex attributes based on format
            for (var a = 0, alen = array_length(attrs); a < alen; a++) {
                var attr = attrs[a];
                
                switch (attr.kind) {
                    case UE_FORMAT_ATTR.POSITION:
                        vertex_position_3d(vb, vertex.x, vertex.y, vertex.z);
                        break;
                    case UE_FORMAT_ATTR.NORMAL:
                        vertex_normal(vb, vertex.nx, vertex.ny, vertex.nz);
                        break;
                    case UE_FORMAT_ATTR.UV:
                        vertex_texcoord(vb, vertex.u, vertex.v);
                        break;
                    case UE_FORMAT_ATTR.COLOR:
                        vertex_color(vb, vertex.color, vertex.alpha);
                        break;
                    case UE_FORMAT_ATTR.CUSTOM:
                        var customValue = vertex.custom[$ attr.name];
                        switch (attr.type) {
                            case vertex_type_float1:
                                vertex_float1(vb, customValue);
                                break;
                            case vertex_type_float2:
                                vertex_float2(vb, customValue[0], customValue[1]);
                                break;
                            case vertex_type_float3:
                                vertex_float3(vb, customValue[0], customValue[1], customValue[2]);
                                break;
                            case vertex_type_float4:
                                vertex_float4(vb, customValue[0], customValue[1], customValue[2], customValue[3]);
                                break;
                            case vertex_type_ubyte4:
                                vertex_ubyte4(vb, customValue[0], customValue[1], customValue[2], customValue[3]);
                                break;
                        }
                        break;
                }
            }
        }

        vertex_end(vb);                           // Finalize vertex buffer
        
        // Automatically freeze the vertex buffer if allowed
        if (canFreeze) vertex_freeze(vb);
        
        return self;
    }
    
    // Freeze the vertex buffer to optimize usage
    function freeze() {
        if (vb) vertex_freeze(vb);
        return self;
    }
    
    // Dispose the vertex buffer, releasing GPU resources
    function dispose() {
        if (vb) {
            vertex_delete_buffer(vb);
            vb = undefined;
        }
        return self;
    }
    
    // Compute bounding box based on current vertices
    function computeBoundingBox() {
        boundingBox.setFromPoints(vertices);
        return self;
    }
    
    // Compute bounding sphere based on current vertices
    function computeBoundingSphere() {
        boundingSphere.setFromPoints(vertices);
        return self;
    }
    
    /** Internal method: prepare data for export or serialization */
    function _compileData(data) {
        var _self = self;
        var vbBuffer = buffer_create_from_vertex_buffer(vb, buffer_fast, 1);
        var vbBufferSize = buffer_get_size(vbBuffer);
        
        var payload = { 
            format: format.uuid,
            vbBufferSize
        };
        data.size += vbBufferSize;
        
        return {
            obj: _self,
            payload,
            ctx: {
                vbBuffer, 
                vbBufferSize
            }
        };
    }
    
    /** Internal method: copy vertex buffer data into export buffer */
    function _compileBufferExtra(buffer, ctx) {
        buffer_copy(ctx.vbBuffer, 0, ctx.vbBufferSize, buffer, buffer_tell(buffer));
        buffer_seek(buffer, buffer_seek_relative, ctx.vbBufferSize);
    } 
    
    // Auto-build vertex buffer if vertices are provided
    if (array_length(vertices)) build();
}
