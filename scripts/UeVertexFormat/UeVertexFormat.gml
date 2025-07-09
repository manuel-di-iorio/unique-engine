function UeVertexFormat() constructor {
    isVertexFormat = true;
    type = "VertexFormat";
    uuid = ueUuid();
    name = data[$ "name"] ?? undefined;
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
    
    /** Internal export methods */
    function _compileData(data) {
        var _self = self;
        var payload = { attrs };
        return { obj: _self, payload };
    }
}