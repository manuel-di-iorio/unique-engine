function UeVertexFormat() constructor {
    isVertexFormat = true;
    vf = undefined;
    attrs = [];

    function position() {
        array_push(attrs, { kind: UE_FORMAT_ATTR.POSITION });
        return self;
    }
    
    function normal() {
        array_push(attrs, { kind: UE_FORMAT_ATTR.NORMAL });
        return self;
    }

    function uv() {
        array_push(attrs, { kind: UE_FORMAT_ATTR.UV });
        return self;
    }
    
    function color() {
        array_push(attrs, { kind: UE_FORMAT_ATTR.COLOR });
        return self;
    }
    
    function custom(name, type) {
        array_push(attrs, { kind: UE_FORMAT_ATTR.CUSTOM, name, type });
        return self;
    }

    function build() {
        vertex_format_begin();

        for (var i = 0, len = array_length(attrs); i < len; i++) {
            var attr = attrs[i];
            
            switch (attr.kind) {
                case UE_FORMAT_ATTR.POSITION: vertex_format_add_position_3d(); break;
                case UE_FORMAT_ATTR.NORMAL: vertex_format_add_normal(); break;
                case UE_FORMAT_ATTR.UV: vertex_format_add_texcoord(); break;
                case UE_FORMAT_ATTR.COLOR: vertex_format_add_color(); break; 
                case UE_FORMAT_ATTR.CUSTOM: vertex_format_add_custom(attr.type, vertex_usage_texcoord); break;
            }
        }
        
        vf = vertex_format_end();
        return self;
    }
    
    function dispose() {
        vertex_format_delete(vf);
        vf = undefined;
        return self;
    }
    
    function export() {
        var attrsSize = array_length(attrs);
        var size = 1 + 1 + attrsSize * 2;
    
        var buffer = buffer_create(size, buffer_fast, 1);
        
        // Write the buffer type
        buffer_write(buffer, buffer_u8, UE_BUFFER_TYPE.FORMAT);
        
        // Write the attributes count
        buffer_write(buffer, buffer_u8, attrsSize);
        
        // Write the attributes data
        for (var i=0; i<attrsSize; i++) {
            var attr = attrs[i];
            buffer_write(buffer, buffer_u8, attr.kind);
            buffer_write(buffer, buffer_u8, attr.type);
        }
        
        return buffer;
    }
}