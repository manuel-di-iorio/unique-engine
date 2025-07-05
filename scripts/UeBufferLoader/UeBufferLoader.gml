function UeBufferLoader() constructor {
    // Temporary internal variables
    cache = {
        formats: {},
        geometries: {},
        textures: {},
        materials: {},
        meshesFlat: [],
        meshesFlatMap: {}
    };
    
    /***
     * Load the scene objects from a buffer file
     **/
    function load(fname) {
        var rootMesh = new UeMesh();
        
        var bufferCompressed = buffer_load(fname);
        var buffer = buffer_decompress(bufferCompressed);
        buffer_delete(bufferCompressed);
        var size = buffer_get_size(buffer);
        
        while (buffer_tell(buffer) < size) {
            _readObject(buffer);
        }
        
        // Resolve the UUID associations
        _resolveGeometriesUUIDs();
        _resolveMaterialUUIDs(); 
        _resolveMeshesUUIDs(rootMesh); 
        
        buffer_delete(buffer);
        meshes = [];
        meshesMap = {};
        
        return {
            mesh: rootMesh,
            textures: cache.textures,
            materials: cache.materials,
            lights: [] // @todo
        };
    }
    
    function _readObject(buffer) {
        var str = buffer_read(buffer, buffer_string);
        var obj = json_parse(str);
      
        switch (obj.type) {
            case UE_BUFFER_TYPE.FORMAT: _readTypeFormat(obj, buffer); break;
            case UE_BUFFER_TYPE.VBUFF: _readTypeGeometry(obj, buffer); break;
            case UE_BUFFER_TYPE.TEXTURE: _readTypeTexture(obj, buffer); break;
            case UE_BUFFER_TYPE.MATERIAL: _readTypeMaterial(obj, buffer); break;
            case UE_BUFFER_TYPE.MESH: _readTypeMesh(obj, buffer); break;
        }
    }
    
    
    /** Types */
    function _readTypeFormat(obj, buffer) {
        var format = new UeVertexFormat();
        format.uuid = obj.uuid;
        format.name = obj.name;
        format.attrs = obj.attrs;
        format.build(); 
        cache.formats[$ obj.uuid] = format;
    }
    
    function _readTypeGeometry(obj, buffer) {
        var geometry = new UeBufferGeometry();
        geometry.uuid = obj.uuid;
        geometry.name = obj.name;
        geometry.format = obj.format;
        
        var vbBufferSize = obj.vbBufferSize;
        var vbBuff = buffer_create(vbBufferSize, buffer_fast, 1);
        buffer_copy(buffer, buffer_tell(buffer), vbBufferSize, vbBuff, 0);
        buffer_seek(buffer, buffer_seek_relative, vbBufferSize);
        geometry.vb = vbBuff; // The actual vbuffer is created on the association step
    
        cache.geometries[$ obj.uuid] = geometry;
    }
    
    function _readTypeTexture(obj, buffer) {
        // Create the sprite buffer
        var image = undefined;
        
        var spriteBuffSize = obj.spriteBuffSize;
        if (spriteBuffSize) {
            var spriteBuff = buffer_create(spriteBuffSize, buffer_fast, 1);
            buffer_copy(buffer, buffer_tell(buffer), spriteBuffSize, spriteBuff, 0);
            
            // Draw the sprite buffer onto a temporary surface
            var spriteSurf = surface_create(spriteWidth, spriteHeight);
            buffer_set_surface(spriteBuff, spriteSurf, 0);
            buffer_delete(spriteBuff);
            
            // Create the actual sprite from the surface
            image = sprite_create_from_surface(spriteSurf, 0, 0, spriteWidth, spriteHeight, false, false, 0, 0);
            surface_free(spriteSurf);
        }
        
        var texture = new UeTexture({ image });
        texture.uuid = obj.uuid;
        texture.name = obj.name;
        texture.filter = obj.filter;
        texture.generateMipmaps = obj.generateMipmaps;
        texture[$ "repeat"] = texrepeat;
        
        cache.textures[$ obj.uuid] = texture;
    }
    
    function _readTypeMaterial(obj, buffer) {
        var material = new UeMaterial();

        // UUID
        material.uuid = obj.uuid;
        material.name = obj.name;
    
        // Material base properties
        material.color = obj.color;
        material.transparent = obj.transparent;
        material.opacity = obj.opacity;
        material.side = obj.side;
        material.depthTest = obj.depthTest;
        material.depthWrite = obj.depthWrite;
        material.depthFunc = obj.depthFunc;
        material.forceSinglePass = obj.forceSinglePass;
        material.alphaTest = obj.alphaTest;
        material.colorWrite = obj.colorWrite;
        material.blending = obj.blending;
        material.blendEquation = obj.blendEquation;
        material.blendEquationAlpha = obj.blendEquationAlpha;
        material.blendSrc = obj.blendSrc;
        material.blendDst = obj.blendDst;
        material.blendSrcAlpha = obj.blendSrcAlpha;
        material.blendDstAlpha = obj.blendDstAlpha;
        material.lights = obj.lights;
    
        // Uniforms and textures
        material.uniforms = obj.uniforms;
        material.textures = obj.textures; // Actual references are retrieved in the next step
        
        cache.materials[$ obj.uuid] = material;
    }
    
    function _readTypeMesh(obj, buffer) {
        var mesh = new UeMesh();
        mesh.uuid = obj.uuid;
        mesh.name = obj.name;
        
        // Read the children   
        mesh.children = obj.children;
        
        // Read the other props
        mesh.visible = obj.visible;
        mesh._parentUuid = obj.parent;
        mesh.renderOrder = obj.renderOrder;
        mesh.geometry = obj[$ "geometry"];
        mesh.material = obj[$ "material"];
        
        // Read the transform
        mesh.position = new UeVector3(obj.px, obj.py, obj.pz);
        mesh.rotation = new UeQuaternion().set(obj.rx, obj.ry, obj.rz, obj.rw);
        mesh.scale = new UeVector3(obj.sx, obj.sy, obj.sz);
        mesh.up = new UeVector3(obj.ux, obj.uy, obj.uz);
        mesh.updateMatrix();
        
        // Store the mesh into a temporary flat array/map for later association of the UUIDs
        array_push(cache.meshesFlat, mesh);
        cache.meshesFlatMap[$ obj.uuid] = mesh;
    }
    
    /** Resolvers */
    function _resolveGeometriesUUIDs() {
        struct_foreach(cache.geometries, function(geometryUuid, geometry) {
            geometry.format = cache.formats[$ geometry.format];
            geometry.vb = vertex_create_buffer_from_buffer(geometry.vb, geometry.format.vf);
        });
    }
    
    function _resolveMaterialUUIDs() {
        struct_foreach(cache.materials, function(materialUuid, material) {
            var materialTextures = material.textures; 
            var texNames = struct_get_names(materialTextures);
            var texNamesCount = struct_names_count(materialTextures);
        
            for (var i = 0; i < texNamesCount; i++) {
                var tname = texNames[i];
                var tuuid = materialTextures[$ tname];
                material.textures[$ tname] = cache.textures[$ tuuid];
            }   
        });
    }
    
    function _resolveMeshesUUIDs(rootMesh) {
        var meshesFlat = cache.meshesFlat;
        
        for (var i = 0, n = array_length(meshesFlat); i < n; i++) {
            var mesh = meshesFlat[i];
            
            var parentUuid = mesh._parentUuid;
            if (parentUuid != undefined) {
                cache.meshesFlatMap[$ parentUuid].add(mesh);
            } else {
                rootMesh.add(mesh);
            }
            
            mesh.geometry = cache.geometries[$ mesh.geometry];
            mesh.material = cache.materials[$ mesh.material];
            
            for (var c = 0, clen = array_length(mesh.children); c < clen; c++) {
                mesh.children[c] = cache.meshesFlatMap[$ mesh.children[c]];
            }
        }
    }
}