function UeBufferLoader() constructor {
    // Temporary internal variables
    buffer = undefined;
    offset = 0;
    uuid = undefined;
    model = undefined;
    rootMesh = undefined;
    meshes = [];
    meshesMap = {};
    
    /***
     * Load a scene/mesh from a buffer file
     **/
    function load(fname) {
        rootMesh = new UeMesh();
        
        var ended = false;
        var bufferCompressed = buffer_load(fname);
        buffer = buffer_decompress(bufferCompressed);
        buffer_delete(bufferCompressed);
        offset = 0;
        model = {
            formats: {},
            geometries: {},
            textures: {},
            materials: {},
            mesh: rootMesh
        }
        
        while (!ended) {
            _readObject();
            ended = true;
        }
        
        // Resolve the UUID associations
        _resolveGeometriesUUIDs();
        _resolveMaterialUUIDs(); 
        _resolveMeshesUUIDs(); 
        
        buffer_delete(buffer);
        meshes = [];
        meshesMap = {};
        
        return model;
    }
    
    function _readObject() {
        var size = buffer_read(buffer, buffer_u32);
        var type = buffer_read(buffer, buffer_u8);
        uuid = buffer_read(buffer, buffer_string);
        
        switch (type) {
            case UE_BUFFER_TYPE.FORMAT: _readTypeFormat(); break;
            case UE_BUFFER_TYPE.VBUFF: _readTypeVbuff(); break;
            case UE_BUFFER_TYPE.TEXTURE: _readTypeTexture(); break;
            case UE_BUFFER_TYPE.MATERIAL: _readTypeMaterial(); break;
            case UE_BUFFER_TYPE.MESH: _readTypeMesh(); break;
        }
        
        offset += size;
        buffer_seek(buffer, buffer_seek_start, offset);
    }
    
    // Types
    function _readTypeFormat() {
        var attrsCount = buffer_read(buffer, buffer_u8);
        var attrs = array_create(attrsCount);
        
        for (var i=0; i<attrsCount; i++) {
            var kind = buffer_read(buffer, buffer_u8);
            var type = buffer_read(buffer, buffer_u8);
            attrs[i] = { kind, type };
        }
        
        var format = new UeVertexFormat();
        format.uuid = uuid;
        format.attrs = attrs;
        format.build();
        
        model.formats[$ uuid] = format;
    }
    
    function _readTypeVbuff() {
        
    }
    
    function _readTypeTexture() {
        // Read the texture props
        var textrepeat = buffer_read(buffer, buffer_u8);
        var filter = buffer_read(buffer, buffer_u8);
        var generateMipmaps = buffer_read(buffer, buffer_u8);
        
        // Read the sprite props
        var spriteWidth = buffer_read(buffer, buffer_u32);
        var spriteHeight = buffer_read(buffer, buffer_u32);
        var spriteBuffSize = buffer_read(buffer, buffer_u32);
        
        // Create the sprite buffer
        var spriteBuff = buffer_create(spriteBuffSize, buffer_fast, 1);
        buffer_copy(buffer, offset + 59, spriteBuffSize, spriteBuff, 0);
        
        // Draw the sprite buffer onto a temporary surface
        var spriteSurf = surface_create(spriteWidth, spriteHeight);
        buffer_set_surface(spriteBuff, spriteSurf, 0);
        buffer_delete(spriteBuff);
        
        // Create the actual sprite from the surface
        var image = sprite_create_from_surface(spriteSurf, 0, 0, spriteWidth, spriteHeight, false, false, 0, 0);
        surface_free(spriteSurf);
        
        var texture = new UeTexture({ image, filter, generateMipmaps });
        texture.uuid = uuid;
        texture[$ "repeat"] = texrepeat;
        
        model.textures[$ uuid] = texture;
    }
    
    function _readTypeMaterial() {
        var material = new UeMaterial();

        // UUID
        material.uuid = uuid;
    
        // Material base properties (in ordine come nell'export)
        material.color = buffer_read(buffer, buffer_u8);
        material.transparent = buffer_read(buffer, buffer_u8);
        material.opacity = buffer_read(buffer, buffer_u8);
        material.side = buffer_read(buffer, buffer_u8);
        material.depthTest = buffer_read(buffer, buffer_u8);
        material.depthWrite = buffer_read(buffer, buffer_u8);
        material.depthFunc = buffer_read(buffer, buffer_u8);
        material.forceSinglePass = buffer_read(buffer, buffer_u8);
        material.alphaTest = buffer_read(buffer, buffer_u8);
        material.colorWrite = buffer_read(buffer, buffer_u8);
        material.blending = buffer_read(buffer, buffer_u8);
        material.blendEquation = buffer_read(buffer, buffer_u8);
        material.blendEquationAlpha = buffer_read(buffer, buffer_u8);
        material.blendSrc = buffer_read(buffer, buffer_u8);
        material.blendDst = buffer_read(buffer, buffer_u8);
        material.blendSrcAlpha = buffer_read(buffer, buffer_u8);
        material.blendDstAlpha = buffer_read(buffer, buffer_u8);
        material.lights = buffer_read(buffer, buffer_u8);
    
        // Uniforms
        var uniformsCount = buffer_read(buffer, buffer_u8);
        material.uniforms = {};
    
        for (var i = 0; i < uniformsCount; i++) {
            var uname = buffer_read(buffer, buffer_string);
            var utype = buffer_read(buffer, buffer_u8);
            material.uniforms[$ uname] = { type: utype };
        }
    
        // Textures
        var texturesCount = buffer_read(buffer, buffer_u8);
        material.textures = {};
    
        for (var i = 0; i < texturesCount; i++) {
            var tname = buffer_read(buffer, buffer_string);
            var tuuid = buffer_read(buffer, buffer_string);
            material.textures[$ tname] = tuuid;
        }

        model.materials[$ uuid] = material;
    }
    
    function _readTypeMesh() {
        var mesh = new UeMesh();
     
        // Read the children   
        var childrenCount = buffer_read(buffer, buffer_u16);
        mesh.children = array_create(childrenCount);
        for (var i = 0; i < childrenCount; i++) {
            mesh.children[i] = buffer_read(buffer, buffer_string);
        }
        
        // Read the other props
        mesh.visible = buffer_read(buffer, buffer_u8);
        var meshParent = buffer_read(buffer, buffer_string)
        mesh.parent = meshParent != "" ? meshParent : undefined;
        
        mesh.renderOrder = buffer_read(buffer, buffer_u16);
        
        meshGeometry = buffer_read(buffer, buffer_string);
        mesh.geometry = meshGeometry != "" ? meshGeometry : undefined;
        
        meshMaterial = buffer_read(buffer, buffer_string);
        mesh.material = meshMaterial != "" ? meshMaterial : undefined;
        
        // Read the transform
        var px = buffer_read(buffer, buffer_u32);
        var py = buffer_read(buffer, buffer_u32);
        var pz = buffer_read(buffer, buffer_u32);
        mesh.position = new UeVector3(px, py, pz);

        var rx = buffer_read(buffer, buffer_u32);
        var ry = buffer_read(buffer, buffer_u32);
        var rz = buffer_read(buffer, buffer_u32);
        var rw = buffer_read(buffer, buffer_u32);
        mesh.rotation = new UeQuaternion().set(rx, ry, rz, rw);

        var sx = buffer_read(buffer, buffer_u32);
        var sy = buffer_read(buffer, buffer_u32);
        var sz = buffer_read(buffer, buffer_u32);
        mesh.scale = new UeVector3(sx, sy, sz);
        
        var ux = buffer_read(buffer, buffer_u32);
        var uy = buffer_read(buffer, buffer_u32);
        var uz = buffer_read(buffer, buffer_u32);
        mesh.up = new UeVector3(ux, uy, uz);
        
        mesh.updateMatrix();
        
        // Store the mesh into a temporary flat array/map for later association of the UUIDs
        array_push(meshes, mesh);
        meshesMap[$ uuid] = mesh;
    }
    
    /** Resolvers */
    function _resolveGeometriesUUIDs() {
        struct_foreach(model.geometries, method({ loadedFormats: model.formats }, function(geometry) {
            geometry.format = loadedFormats[$ geometry.format];
        }));
    }
    
    function _resolveMaterialUUIDs() {
        struct_foreach(model.materials, method({ loadedTextures: model.textures }, function(material) {
            var textures = material.textures;
            var texNames = struct_get_names(textures);
            var texNamesCount = struct_names_count(textures);
        
            for (var i = 0; i < texNamesCount; i++) {
                var tname = texNames[i];
                var tuuid = textures[$ tname];
                material.textures[$ tname] = loadedTextures[$ tuuid];
            }   
        }));
    }
    
    function _resolveMeshesUUIDs() {
        array_foreach(meshes, function(mesh) {
            var parentUuid = mesh.parent; 
            if (parentUuid != undefined) {
                meshesMap[$ parentUuid].add(mesh);
            } else {
                rootMesh.add(mesh);
            }
            
            mesh.geometry = model.geometries[$ mesh.geometry];
            mesh.material = model.materials[$ mesh.material];
            
            for (var i = 0, n = array_length(mesh.children); i < n; i++) {
                mesh.children[i] = meshesMap[$ mesh.children[i]];
            }
        });
    }
}