global.UE_DEFAULT_VERTEX_FORMAT = new VertexFormat().position().normal().uv().color().build();

function VertexFormat() constructor {
    vf = undefined;
    attrs = [];

    function position() {
        array_push(attrs, { kind: "position" });
        return self;
    }
    
    function normal() {
        array_push(attrs, { kind: "normal" });
        return self;
    }

    function uv() {
        array_push(attrs, { kind: "uv" });
        return self;
    }
    
    function color() {
        array_push(attrs, { kind: "color" });
        return self;
    }
    
    function custom(type) {
        array_push(attrs, { kind: "custom", type });
        return self;
    }

    function build() {
        vertex_format_begin();

        for (var i = 0, len = array_length(self.attrs); i < len; i++) {
            var attr = self.attrs[i];
            
            switch (attr.kind) {
                case "position":
                    vertex_format_add_position_3d();
                    break;
                case "normal":
                    vertex_format_add_normal();
                    break;
                case "uv":
                    vertex_format_add_texcoord();
                    break;
                case "color":
                    vertex_format_add_color();
                    break; 
                case "custom":
                    vertex_format_add_custom(attr.type, vertex_usage_texcoord);
                    break;
            }
        }
        
        vf = vertex_format_end();
        return vf;
    }
}