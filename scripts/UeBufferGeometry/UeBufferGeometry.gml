function BufferGeometry(data = {}): Object3D(data) constructor {
    isBufferGeometry = true;
    vertices = data[$ "vertices"] ?? [];
    index = data[$ "index"] ?? undefined;
    vformat = data[$ "vformat"] ?? global.UE_DEFAULT_VERTEX_FORMAT;
    vb = undefined;
    
    function build() {
        vb = vertex_create_buffer();
        vertex_begin(vb, vformat.vf);
        var attrs = vformat.attrs;
        
        var useIndex = is_array(index);
        var ilen = array_length(useIndex ? index : vertices);
        for (var i = 0; i < ilen; i++) {
            var vertex = vertices[useIndex ? index[i] : i];
            
            for (var a = 0, alen = array_length(attrs); a < alen; a++) {
                var attr = attrs[a];
                
                switch (attr.kind) {
                    case "position": vertex_position_3d(vb, vertex.x, vertex.y, vertex.z); break;
                    case "normal": vertex_normal(vb, vertex.nx, vertex.ny, vertex.nz); break;
                    case "uv": vertex_texcoord(vb, vertex.u, vertex.v); break;
                    case "color": vertex_color(vb, vertex.color, vertex.alpha); break;
                    case "custom": 
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
    
    build();
}