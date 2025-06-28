function UeBufferGeometry(data = {}): UeObject3D(data) constructor {
    isBufferGeometry = true;
    vertices = data[$ "vertices"] ?? [];
    index = data[$ "index"] ?? undefined;
    format = data[$ "format"] ?? global.UE_DEFAULT_VERTEX_FORMAT;
    vb = undefined;
    canFreeze = data[$ "canFreeze"] ?? true;
    
    function build() {
        vb = vertex_create_buffer();
        vertex_begin(vb, format.vf);
        var attrs = format.attrs;
        
        var useIndex = is_array(index);
        var ilen = array_length(useIndex ? index : vertices);
        for (var i = 0; i < ilen; i++) {
            var vertex = vertices[useIndex ? index[i] : i];
            
            for (var a = 0, alen = array_length(attrs); a < alen; a++) {
                var attr = attrs[a];
                
                switch (attr.kind) {
                    case UE_FORMAT_ATTR.POSITION: vertex_position_3d(vb, vertex.x, vertex.y, vertex.z); break;
                    case UE_FORMAT_ATTR.NORMAL: vertex_normal(vb, vertex.nx, vertex.ny, vertex.nz); break;
                    case UE_FORMAT_ATTR.UV: vertex_texcoord(vb, vertex.u, vertex.v); break;
                    case UE_FORMAT_ATTR.COLOR: vertex_color(vb, vertex.color, vertex.alpha); break;
                    case UE_FORMAT_ATTR.CUSTOM: 
                        var customValue = vertex.custom[$ attr.name];
                        switch (attr.type) {
                            case vertex_type_float1: vertex_float1(vb, customValue); break;
                            case vertex_type_float2: vertex_float2(vb, customValue[0], customValue[1]); break;
                            case vertex_type_float3: vertex_float3(vb, customValue[0], customValue[1], customValue[2]); break;
                            case vertex_type_float4: vertex_float4(vb, customValue[0], customValue[1], customValue[2], customValue[3]); break;
                            case vertex_type_ubyte4: vertex_ubyte4(vb, customValue[0], customValue[1], customValue[2], customValue[3]); break;
                            
                        }
                    break;
                }
            }
        }

        vertex_end(vb);
        return self;
    }
    
    function freeze() {
        vertex_freeze(vb);
        return self;
    }
    
    function dispose() {
        vertex_delete_buffer(vb);
        vb = undefined;
        return self;
    }
    
    function export() {
        var vbBuffer = buffer_create_from_vertex_buffer(vb, buffer_fast, 1);
        var vbBufferSize = buffer_get_size(vbBuffer);
        var size = 1 + 4 + vbBufferSize;
        var buffer = buffer_create(size, buffer_fast, 1);
        
        // Write the buffer type
        buffer_write(buffer, buffer_u8, UE_BUFFER_TYPE.VBUFF);
      
        // Write the vbuffer size
        buffer_write(buffer, buffer_u32, vbBufferSize);
        
        // Write the vbuffer data
        buffer_copy(vbBuffer, 0, vbBufferSize, buffer, 5);
        
        return buffer;
    }
    
    // Build the vertex buffer with the initial vertices data
    build();
    
    // Automatically freeze the vertex buffer on init
    if (canFreeze && array_length(vertices)) vertex_freeze(vb);
}