function UeGeometry(data = {}) constructor {
    isGeometry = true;
    type = "Geometry";
    uuid = ueUuid();
    name = data[$ "name"] ?? undefined;
    
    // Core attributes
    position = data[$ "position"] ?? undefined;
    normal   = data[$ "normal"]   ?? undefined;
    uv       = data[$ "uv"]       ?? undefined;
    color    = data[$ "color"]    ?? undefined;
    index    = data[$ "index"]    ?? undefined;
    
    format = data[$ "format"] ?? global.UE_DEFAULT_VERTEX_FORMAT;
    vb = undefined;
    canFreeze = data[$ "canFreeze"] ?? true;

    boundingBox = data[$ "boundingBox"] ?? undefined;
    boundingSphere = data[$ "boundingSphere"] ?? undefined;

    // Build the vertex buffer from vertices and format
    function build() {
        gml_pragma("forceinline");
        if (position == undefined) return self;
        dispose();
        
        vb = vertex_create_buffer();
        vertex_begin(vb, format.vf);
        
        var attrs = format.attrs;
        var useIdx = is_array(index);
        var count = useIdx ? array_length(index) : (array_length(position) / 3);
        var alen = array_length(attrs);

        for (var i = 0; i < count; i++) {
            var vi = useIdx ? index[i] : i;
            var vi3 = vi * 3, vi2 = vi * 2;

            for (var a = 0; a < alen; a++) {
                var attr = attrs[a];
                switch (attr.kind) {
                    case UE_FORMAT_ATTR.POSITION:
                        vertex_position_3d(vb, position[vi3], position[vi3+1], position[vi3+2]);
                        break;
                    case UE_FORMAT_ATTR.NORMAL:
                        if (normal != undefined) vertex_normal(vb, normal[vi3], normal[vi3+1], normal[vi3+2]);
                        else vertex_normal(vb, 0, 0, 1);
                        break;
                    case UE_FORMAT_ATTR.UV:
                        if (uv != undefined) vertex_texcoord(vb, uv[vi2], uv[vi2+1]);
                        else vertex_texcoord(vb, 0, 0);
                        break;
                    case UE_FORMAT_ATTR.COLOR:
                        if (color != undefined) vertex_color(vb, color[vi2], color[vi2+1]);
                        else vertex_color(vb, c_white, 1);
                        break;
                    case UE_FORMAT_ATTR.CUSTOM:
                        var val = self[$ attr.name];
                        if (val != undefined) {
                            var stride = 1;
                            if (attr.type == vertex_type_float2) stride = 2;
                            else if (attr.type == vertex_type_float3) stride = 3;
                            else if (attr.type == vertex_type_float4) stride = 4;
                            else if (attr.type == vertex_type_ubyte4) stride = 4;
                            var ci = vi * stride;
                            if (attr.type == vertex_type_float1) vertex_float1(vb, val[ci]);
                            else if (attr.type == vertex_type_float2) vertex_float2(vb, val[ci], val[ci+1]);
                            else if (attr.type == vertex_type_float3) vertex_float3(vb, val[ci], val[ci+1], val[ci+2]);
                            else if (attr.type == vertex_type_float4) vertex_float4(vb, val[ci], val[ci+1], val[ci+2], val[ci+3]);
                            else if (attr.type == vertex_type_ubyte4) vertex_ubyte4(vb, val[ci], val[ci+1], val[ci+2], val[ci+3]);
                        }
                        break;
                }
            }
        }

        vertex_end(vb); // Finalize vertex buffer
        
        // Automatically freeze the vertex buffer if allowed
        if (canFreeze) freeze();
        
        return self;
    }
    
    // Freeze the vertex buffer to optimize usage
    function freeze() {
        gml_pragma("forceinline");
        if (vb) vertex_freeze(vb);
        return self;
    }
    
    // Dispose the vertex buffer, releasing GPU resources
    function dispose() {
        gml_pragma("forceinline");
        if (vb != undefined) {
            vertex_delete_buffer(vb);
            vb = undefined;
        }
        return self;
    }
    
    // Compute bounding box based on current vertices
    function computeBoundingBox() {
        gml_pragma("forceinline");
        boundingBox ??= new UeBox3();
        if (position != undefined) boundingBox.setFromBufferAttribute(position);
        return self;
    }
    
    // Compute bounding sphere based on current vertices
    function computeBoundingSphere() {
        gml_pragma("forceinline");
        boundingSphere ??= new UeSphere();
        if (position != undefined) boundingSphere.setFromBufferAttribute(position);
        return self;
    }
    
    // Vertically flip the UV of the vertices and rebuild the geometry
    function flipUV() {
        gml_pragma("forceinline");
        if (uv == undefined) return self;
        for (var i = 1, l = array_length(uv); i < l; i += 2) {
            uv[i] = 1 - uv[i];
        }
    
        build(); 
        return self;
    }
    
    function toJSON() {
        var res = { 
            uuid: uuid, 
            type: type, 
            name: name, 
            position: position, 
            normal: normal, 
            uv: uv, 
            color: color, 
            index: index, 
            format: format.toJSON() 
        };
        res.boundingBox = boundingBox ? boundingBox.toJSON() : undefined;
        res.boundingSphere = boundingSphere ? boundingSphere.toJSON() : undefined;
        
        var attrs = format.attrs;
        for (var i = 0, l = array_length(attrs); i < l; i++) {
            if (attrs[i].kind == UE_FORMAT_ATTR.CUSTOM) {
                res[$ attrs[i].name] = self[$ attrs[i].name];
            }
        }
        return res;
    }

    function fromJSON(data) {
        gml_pragma("forceinline");
        uuid = data[$ "uuid"];
        name = data[$ "name"];
        position = data[$ "position"];
        normal = data[$ "normal"];
        uv = data[$ "uv"];
        color = data[$ "color"];
        index = data[$ "index"];
        format = new UeVertexFormat().fromJSON(data[$ "format"]);
        
        var attrs = format.attrs;
        for (var i = 0, l = array_length(attrs); i < l; i++) {
            if (attrs[i].kind == UE_FORMAT_ATTR.CUSTOM) {
                self[$ attrs[i].name] = data[$ attrs[i].name];
            }
        }
        if (data[$ "boundingBox"] != undefined) boundingBox = new UeBox3().fromJSON(data.boundingBox);
        if (data[$ "boundingSphere"] != undefined) boundingSphere = new UeSphere().fromJSON(data.boundingSphere);
        return self;
    }
    
    /** Internal method: prepare data for export or serialization */
    function _compileData(data) {
        gml_pragma("forceinline");
        var vbBuffer = buffer_create_from_vertex_buffer(vb, buffer_fast, 1);
        var vbBufferSize = buffer_get_size(vbBuffer);
        
        var payload = toJSON();
        payload.vbBufferSize = vbBufferSize;
        data.size += vbBufferSize;
        
        return {
            payload: payload,
            ctx: {
                vbBuffer: vbBuffer, 
                vbBufferSize: vbBufferSize
            }
        };
    }
    
    /** Internal method: copy vertex buffer data into export buffer */
    function _compileBufferExtra(buffer, ctx) {
        gml_pragma("forceinline");
        buffer_copy(ctx.vbBuffer, 0, ctx.vbBufferSize, buffer, buffer_tell(buffer));
        buffer_seek(buffer, buffer_seek_relative, ctx.vbBufferSize);
    } 
    
    
    function export(fname) {
        if (vb == undefined) return self;
        var buf = buffer_create_from_vertex_buffer(vb, buffer_fast, 1);
        buffer_save(buf, fname);
        buffer_delete(buf);
        return self;
    }
    
    function import(fname) {
        var buf = buffer_load(fname);
        vb = vertex_create_buffer_from_buffer(buf, format.vf);
        buffer_delete(buf);
        return self;
    }

    /**
     * Create a clone of the vertex buffer
     */
    function cloneVb() {
        gml_pragma("forceinline");
        if (vb == undefined) return self;
        var tmpBuf = buffer_create_from_vertex_buffer(vb, buffer_fast, 1);
        var cloneVb = vertex_create_buffer_from_buffer(tmpBuf, format.vf);
        buffer_delete(tmpBuf);
        return cloneVb;
    }
    
    /**
     * Applies the matrix transform to the geometry vertices.
     * @param {Struct} matrix - UeMatrix4
     */
    function applyMatrix(matrix) {
        gml_pragma("forceinline");
        if (position == undefined) return self;
        
        var e = matrix.data;
        for (var i = 0, l = array_length(position); i < l; i += 3) {
            var vx = position[i], vy = position[i+1], vz = position[i+2];
            position[i]   = e[0]*vx + e[4]*vy + e[8]*vz + e[12];
            position[i+1] = e[1]*vx + e[5]*vy + e[9]*vz + e[13];
            position[i+2] = e[2]*vx + e[6]*vy + e[10]*vz + e[14];
        }
        
        if (normal != undefined) {
            var normalMatrix = matrix.clone().invert().transpose();
            var n = normalMatrix.data;
            for (var i = 0, l = array_length(normal); i < l; i += 3) {
                var nx = normal[i], ny = normal[i+1], nz = normal[i+2];
                normal[i]   = n[0]*nx + n[4]*ny + n[8]*nz;
                normal[i+1] = n[1]*nx + n[5]*ny + n[9]*nz;
                normal[i+2] = n[2]*nx + n[6]*ny + n[10]*nz;
                
                var d = sqrt(normal[i]*normal[i] + normal[i+1]*normal[i+1] + normal[i+2]*normal[i+2]);
                if (d > 0) { normal[i] /= d; normal[i+1] /= d; normal[i+2] /= d; }
            }
        }
        
        build();
        return self;
    }

    /**
     * Merges an array of geometries into a single new geometry. They must share the same format.
     * @param {Array<Struct.UeGeometry>} geometries
     * @returns {Struct.UeGeometry}
     */
    function merge(geometries) {
        gml_pragma("forceinline");
        if (!is_array(geometries) || array_length(geometries) == 0) return undefined;
        
        var res = new UeGeometry();
        // Assuming all geometries have the same format as the first one
        res.format = geometries[0].format;
        
        var pos = [], norm = [], _uv = [], col = [], idx = [];
        var offset = 0;
        
        for (var i = 0, il = array_length(geometries); i < il; i++) {
            var g = geometries[i];
            var vCount = array_length(g.position) / 3;
            
            pos = array_concat(pos, g.position);
            if (g.normal != undefined) norm = array_concat(norm, g.normal);
            if (g.uv != undefined) _uv = array_concat(_uv, g.uv);
            if (g.color != undefined) col = array_concat(col, g.color);
            
            if (g.index != undefined) {
                for (var j = 0; j < array_length(g.index); j++) {
                    array_push(idx, g.index[j] + offset);
                }
            }
            
            offset += vCount;
        }
        
        res.position = pos;
        if (array_length(norm) > 0) res.normal = norm;
        if (array_length(_uv) > 0) res.uv = _uv;
        if (array_length(col) > 0) res.color = col;
        if (array_length(idx) > 0) res.index = idx;
        
        res.build();
        return res;
    }

    // Auto-build vertex buffer if position is provided
    if (position != undefined) build();
}
