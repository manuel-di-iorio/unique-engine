function Geometry(data = {}): Object3D(data) constructor {
    vertices = data[$ "vertices"] ?? [];
    indices = data[$ "indices"] ?? [];
    normals = data[$ "normals"] ?? [];
    color = data[$ "color"] ?? c_white;
    uvs = data[$ "uvs"] ?? [];
    vformat = data[$ "vformat"] ?? global.UE_DEFAULT_VERTEX_FORMAT;
    vb = undefined;
    
    function build() {
        vb = vertex_create_buffer();
        vertex_begin(vb, vformat);
        
        for (var i = 0; i < array_length(vertices); i += 3) {
            vertex_position_3d(vb, vertices[i], vertices[i+1], vertices[i+2]);
            vertex_normal(vb, normals[i], normals[i+1], normals[i+2]);
            vertex_texcoord(vb, 0, 0);
            vertex_color(vb, color, 1);
        }

        vertex_end(vb);
        return self;
    }
    
    function freeze() {
        vertex_freeze(vb);
        return self;
    }
    
    function remove() {
        vertex_delete_buffer(vb);
        vb = undefined;
        return self;
    }
    
    build();
}