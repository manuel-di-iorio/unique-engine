function UeVertexFormat(data = {}) constructor {
    isVertexFormat = true;
    type = "VertexFormat";
    uuid = ueUuid();
    name = data[$ "name"] ?? "";
    vf = undefined;
    attrs = [];

    function position() {
        gml_pragma("forceinline");
        array_push(attrs, { kind: UE_FORMAT_ATTR.POSITION });
        return self;
    }
    
    function normal() {
        gml_pragma("forceinline");
        array_push(attrs, { kind: UE_FORMAT_ATTR.NORMAL });
        return self;
    }
  
    function tangent() {
        gml_pragma("forceinline");
        array_push(attrs, { kind: UE_FORMAT_ATTR.CUSTOM, name: "tangent", type: vertex_type_float4 });
        return self;
    }

    function uv() {
        gml_pragma("forceinline");
        array_push(attrs, { kind: UE_FORMAT_ATTR.UV });
        return self;
    }
    
    function color() {
        gml_pragma("forceinline");
        array_push(attrs, { kind: UE_FORMAT_ATTR.COLOR });
        return self;
    }

    function bones() {
        gml_pragma("forceinline");
        array_push(attrs, { kind: UE_FORMAT_ATTR.CUSTOM, name: "boneIndices", type: vertex_type_float4 });
        array_push(attrs, { kind: UE_FORMAT_ATTR.CUSTOM, name: "boneWeights", type: vertex_type_float4 });
        return self;
    }
    
    function custom(name, type) {
        gml_pragma("forceinline");
        array_push(attrs, { kind: UE_FORMAT_ATTR.CUSTOM, name, type });
        return self;
    }

    /**
     * Returns the stride of the vertex format.
     * @returns {number} The stride of the vertex format.
     */
    function getStride() {
      gml_pragma("forceinline");
      return vertex_format_get_info(self.vf)[$ "stride"];
    }

    function build() {
        gml_pragma("forceinline");
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
        gml_pragma("forceinline");
        vertex_format_delete(vf);
        vf = undefined;
        return self;
    }
    
    function toJSON() {
        gml_pragma("forceinline");
        return {
            uuid,
            type,
            name,
            attrs
        };
    }

    function fromJSON(data) {
        gml_pragma("forceinline");
        uuid = data.uuid;
        name = data.name;
        attrs = data.attrs;
        build();
        return self;
    }
    
    /** Internal export methods */
    function _compileData(data) {
        gml_pragma("forceinline");
        return { payload: toJSON() };
    }

    /**
     * Creates a deep copy of the vertex format.
     * The clone will have a new UUID and the native format pointer (vf) will be reset,
     * requiring a new call to build() if you want to use it to create buffers.
     * @returns {Struct.UeVertexFormat} A new instance of UeVertexFormat.
     */
    function clone() {
        gml_pragma("forceinline");
        var _clone = variable_clone(self);
        _clone.uuid = ueUuid();
        _clone.vf = undefined;
        return _clone;
    }
}
