function UeGeometry(data = {}) constructor {
    isGeometry = true;                            // Flag to identify this as a geometry
    type = "Geometry";                            // Type identifier string
    uuid = ueUuid();                              // Unique identifier for this geometry instance
    name = data[$ "name"] ?? undefined;           // Optional name for the geometry
    vertices = data[$ "vertices"] ?? [];          // Array of vertex data
    index = data[$ "index"] ?? undefined;         // Optional index array for indexed geometry
    format = data[$ "format"] ?? global.UE_DEFAULT_VERTEX_FORMAT; // Vertex format description
    vb = undefined;                               // Vertex buffer handle (created on build)
    canFreeze = data[$ "canFreeze"] ?? true;      // Flag whether vertex buffer can be frozen (optimization)

    // Axis-aligned bounding box for the geometry
    boundingBox = data[$ "boundingBox"] ?? undefined;
    
    // Bounding sphere for the geometry
    boundingSphere = data[$ "boundingSphere"] ?? undefined;

    // Build the vertex buffer from vertices and format
    function build() {
        gml_pragma("forceinline");
        dispose();
        vb = vertex_create_buffer();               // Create a new vertex buffer
        vertex_begin(vb, format.vf);               // Begin vertex buffer with format flags
        var attrs = format.attrs;                   // Attributes defined by the format
        
        var useIndex = is_array(index);             // Check if geometry uses indexed vertices
        var ilen = array_length(useIndex ? index : vertices);
        var alen = array_length(attrs);

        // Iterate through vertices or indices
        for (var i = 0; i < ilen; i++) {
            var vertex = vertices[useIndex ? index[i] : i];
            
            // Add vertex attributes based on format
            for (var a = 0; a < alen; a++) {
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
        if (vb) {
            vertex_delete_buffer(vb);
            vb = undefined;
        }
        return self;
    }
    
    // Compute bounding box based on current vertices
    function computeBoundingBox() {
        gml_pragma("forceinline");
        boundingBox ??= new UeBox3();
        boundingBox.setFromPoints(vertices);
        return self;
    }
    
    // Compute bounding sphere based on current vertices
    function computeBoundingSphere() {
        gml_pragma("forceinline");
        boundingSphere ??= new UeSphere();
        boundingSphere.setFromPoints(vertices);
        return self;
    }
    
    // Vertically flip the UV of the vertices and rebuild the geometry
    function flipUV() {
        gml_pragma("forceinline");
    
        for (var i = 0, l= array_length(vertices); i < l; i++) {
            var v = vertices[i];
            v.v = 1 - v.v;
        }
    
        build(); 
        return self;
    }
    
    function toJSON() {
        gml_pragma("forceinline");
        return { 
            uuid,
            type,
            name,
            format: format.toJSON(),
            boundingBox: boundingBox ? boundingBox.toJSON() : undefined,
            boundingSphere: boundingSphere ? boundingSphere.toJSON() : undefined
        };
    }

    function fromJSON(data) {
        gml_pragma("forceinline");
        uuid = data[$ "uuid"];
        name = data[$ "name"];
        format = new UeVertexFormat().fromJSON(data[$ "format"]);
        
        if (data[$ "boundingBox"] != undefined) {
            boundingBox = new UeBox3().fromJSON(data.boundingBox);
        }
        
        if (data[$ "boundingSphere"] != undefined) {
            boundingSphere = new UeSphere().fromJSON(data.boundingSphere);
        }
        
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
            payload,
            ctx: {
                vbBuffer, 
                vbBufferSize
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
        
        // We need to transform the position and rotation (normal)
        var e = matrix.data;
        // matrix for normals is the inverse transpose of the matrix
        var normalMatrix = matrix.clone().invert().transpose();
        var n = normalMatrix.data;
        
        for (var i = 0, l = array_length(vertices); i < l; i++) {
            var v = vertices[i];
            
            // Apply position transform
            var vx = v.x, vy = v.y, vz = v.z;
            v.x = e[0]*vx + e[4]*vy + e[8]*vz + e[12];
            v.y = e[1]*vx + e[5]*vy + e[9]*vz + e[13];
            v.z = e[2]*vx + e[6]*vy + e[10]*vz + e[14];
            
            // Apply normal transform if exists
            if (v[$ "nx"] != undefined) {
                 var nx = v.nx, ny = v.ny, nz = v.nz;
                 v.nx = n[0]*nx + n[4]*ny + n[8]*nz;
                 v.ny = n[1]*nx + n[5]*ny + n[9]*nz;
                 v.nz = n[2]*nx + n[6]*ny + n[10]*nz;
                 
                 // Normalize normal
                 var len = sqrt(v.nx*v.nx + v.ny*v.ny + v.nz*v.nz);
                 if (len > 0) {
                     v.nx /= len;
                     v.ny /= len;
                     v.nz /= len;
                 }
            }
        }
        
        build(); // Rebuild vertex buffer
        return self;
    }

    /**
     * Merges an array of geometries into a single new geometry.
     * @param {Array<Struct.UeGeometry>} geometries
     * @returns {Struct.UeGeometry}
     */
    function merge(geometries) {
        gml_pragma("forceinline");
        if (!is_array(geometries)) return undefined;
        
        var mergedVertices = [];
        
        for (var i = 0, il = array_length(geometries); i < il; i++) {
            var geo = geometries[i];
            var vs = geo.vertices;
            for(var j=0, jl=array_length(vs); j<jl; j++) {
                 var v = vs[j];
                 // Manual shallow clone with dot notation
                 array_push(mergedVertices, {
                     x: v.x, y: v.y, z: v.z,
                     nx: v.nx, ny: v.ny, nz: v.nz,
                     u: v.u, v: v.v,
                     color: v.color, alpha: v.alpha
                 }); 
            }
        }
        
        return new UeGeometry({ vertices: mergedVertices });
    }

    // Auto-build vertex buffer if vertices are provided
    if (array_length(vertices)) build();
}
