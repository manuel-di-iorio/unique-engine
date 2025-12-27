function UeBufferLoader() constructor {
    // Temporary internal variables
    cache = {
        formats: {},
        geometries: {},
        textures: {},
        materials: {},
        meshesFlat: [],
        meshesFlatMap: {},
        lights: {}
    };
    
    /***
     * Load the scene objects from a buffer file
     **/
    function load(fname, isCompressed = true, resetCache = true) {
        gml_pragma("forceinline");
        if (resetCache) {
            cache.formats = {};
            cache.geometries = {};
            cache.textures = {};
            cache.materials = {};
            cache.meshesFlat = [];
            cache.meshesFlatMap = {};
            cache.lights = {};
        }
        
        // Load the buffer (decompress it first if specified)
        var buffer = buffer_load(fname);
        
        if (isCompressed) {
            var bufferDecompressed = buffer_decompress(buffer);
            buffer_delete(buffer);
            buffer = bufferDecompressed;
        }
        
        var size = buffer_get_size(buffer);
        var objects = []; 
        
        while (buffer_tell(buffer) < size) {
            _readObject(buffer, objects);
        }
        
        // Resolve the UUID associations
        _resolveGeometriesUUIDs();
        _resolveMaterialUUIDs(); 
        _resolveMeshesUUIDs(objects); 
        
        buffer_delete(buffer);
        
        return {
            objects,
            textures: cache.textures,
            materials: cache.materials
        };
    }
    
    function _readObject(buffer, objects) {
        gml_pragma("forceinline");
        var str = buffer_read(buffer, buffer_string);
        var obj = json_parse(str); 
      
        switch (obj.type) {
            case "VertexFormat": _readTypeFormat(obj, buffer); break;
            case "Geometry": _readTypeGeometry(obj, buffer); break;
            case "Texture": _readTypeTexture(obj, buffer); break;
            case "Material": _readTypeMaterial(obj, buffer); break;
            case "Mesh": _readTypeMesh(obj, buffer); break;
            case "Light": _readTypeLight(obj, buffer, objects); break;
        }
    }
    
    
    /** Types */
    function _readTypeFormat(obj, buffer) {
        gml_pragma("forceinline");
        var format = new UeVertexFormat();
        format.uuid = obj.uuid;
        
        var name = obj[$ "name"];
        if (name != undefined) format.name = name;
            
        format.attrs = obj.attrs;
        format.build(); 
        cache.formats[$ obj.uuid] = format;
    }
    
    function _readTypeGeometry(obj, buffer) {
        gml_pragma("forceinline");
        var geometry = new UeGeometry();
        geometry.uuid = obj.uuid;
        
        var name = obj[$ "name"];
        if (name != undefined) geometry.name = name;
        
        geometry.format = obj.format;
        
        var vbBufferSize = obj.vbBufferSize;
        var vbBuff = buffer_create(vbBufferSize, buffer_fast, 1);
        buffer_copy(buffer, buffer_tell(buffer), vbBufferSize, vbBuff, 0);
        buffer_seek(buffer, buffer_seek_relative, vbBufferSize);
        geometry._vbBuffer = vbBuff; // The actual vbuffer is created on the association step
    
        cache.geometries[$ obj.uuid] = geometry;
    }
    
    function _readTypeTexture(obj, buffer) {
        gml_pragma("forceinline");
        // Create the sprite buffer
        var image = undefined;
        
        var spriteBuffSize = obj[$ "spriteBuffSize"];
        if (spriteBuffSize) {
            // Draw the sprite buffer onto a temporary surface
            var spriteWidth = obj.spriteWidth;
            var spriteHeight = obj.spriteHeight;
            var spriteSurf = surface_create(spriteWidth, spriteHeight);
            
            buffer_set_surface(buffer, spriteSurf, buffer_tell(buffer));
            buffer_seek(buffer, buffer_seek_relative, spriteBuffSize);
            
            // Create the actual sprite from the surface
            image = sprite_create_from_surface(spriteSurf, 0, 0, spriteWidth, spriteHeight, false, false, 0, 0);
            surface_free(spriteSurf);
        }

        var texture = new UeTexture({ image });
        texture.uuid = obj.uuid;
        
        var name = obj[$ "name"];
        if (name != undefined) texture.name = name;
        
        texture.filter = obj.filter;
        texture.generateMipmaps = obj.generateMipmaps;
        var repeatVec = obj[$ "repeat"];
        var offset = obj.offset;
        var center = obj.center;
        texture[$ "repeat"] = vec2_create(repeatVec.x, repeatVec.y);
        texture.offset = vec2_create(offset.x, offset.y);
        texture.center = vec2_create(center.x, center.y);
        texture.rotation = obj.rotation;
        texture.flipX = obj.flipX;
        texture.flipY = obj.flipY;
        texture.wrapS = obj.wrapS;
        texture.wrapT = obj.wrapT;
        texture.userData = obj.userData;
        
        cache.textures[$ obj.uuid] = texture;
    }
    
    function _readTypeMaterial(obj, buffer) {
        gml_pragma("forceinline");
        var material = new UeMaterial();
        material.uuid = obj.uuid;
        
        var name = obj[$ "name"];
        if (name != undefined) material.name = name;
    
        // Material base properties
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
        
        // Try to set the material from the name
        var shaderName = obj[$ "shader"];
        if (shaderName != undefined) {
            var shader = asset_get_index(shaderName);
            if (shader != -1) material.shader = shader;
        }
        
        cache.materials[$ obj.uuid] = material;
    }
    
    function _readTypeMesh(obj, buffer) {
        gml_pragma("forceinline");
        var mesh = new UeMesh();
        mesh.uuid = obj.uuid;
        
        var name = obj[$ "name"];
        if (name != undefined) mesh.name = name;
        
        // Read the children   
        mesh.children = obj.children;
        
        // Read the other props
        mesh.visible = obj.visible;
        mesh._parentUuid = obj.parent;
        mesh.renderOrder = obj.renderOrder;
        mesh.geometry = obj[$ "geometry"];
        mesh.material = obj[$ "material"];
        mesh.layers.mask = obj.layers;
        
        // Read the transform
        mesh.position = vec3_create(obj.px, obj.py, obj.pz);
        mesh.rotation = quat_create();
        quat_set(mesh.rotation, obj.rx, obj.ry, obj.rz, obj.rw);
        mesh.scale = vec3_create(obj.sx, obj.sy, obj.sz);
        mesh.up = vec3_create(obj.ux, obj.uy, obj.uz);
        mesh.updateMatrix();
        
        // Store the mesh into a temporary flat array/map for later association of the UUIDs
        array_push(cache.meshesFlat, mesh);
        cache.meshesFlatMap[$ obj.uuid] = mesh;
    }
    
    function _readTypeLight(obj, buffer, objects) {
        gml_pragma("forceinline");
        var light = new UeLight();
        var name = obj[$ "name"];
        if (name != undefined) light.name = name;
        
        light.uuid = obj.uuid;
        light.lightType = obj.lightType;
        light.enabled = obj.enabled;
        light.intensity = obj.intensity;
        light.range = obj.range;
        light.color = obj.color;
        light.position = vec3_create(obj.px, obj.py, obj.pz);
        
        if (obj[$ "targetX"] != undefined) {
            light.target = vec3_create(obj.targetX, obj.targetY, obj.targetZ);
        }
        
        array_push(objects, light);
    }
    
    /** Resolvers */
    function _resolveGeometriesUUIDs() {
        gml_pragma("forceinline");
        struct_foreach(cache.geometries, function(geometryUuid, geometry) {
            geometry.format = cache.formats[$ geometry.format];
            geometry.vb = vertex_create_buffer_from_buffer(geometry._vbBuffer, geometry.format.vf);
            buffer_delete(geometry._vbBuffer);
            variable_struct_remove(geometry, "_vbBuffer");
        });
    }
    
    function _resolveMaterialUUIDs() {
        gml_pragma("forceinline");
        struct_foreach(cache.materials, function(materialUuid, material) {
            var materialTextures = material.textures; 
            var texNames = struct_get_names(materialTextures);
            var texNamesCount = struct_names_count(materialTextures);
        
            for (var i = 0; i < texNamesCount; i++) {
                var tname = texNames[i];
                var tuuid = materialTextures[$ tname];
                material.textures[$ tname] = cache.textures[$ tuuid];
            }   
            
            material.build();
        });
    }
    
    function _resolveMeshesUUIDs(objects) {
        gml_pragma("forceinline");
        var meshesFlat = cache.meshesFlat;
        
        for (var i = 0, n = array_length(meshesFlat); i < n; i++) {
            var mesh = meshesFlat[i];
            
            mesh.geometry = cache.geometries[$ mesh.geometry];
            mesh.material = cache.materials[$ mesh.material];
            
            for (var c = 0, clen = array_length(mesh.children); c < clen; c++) {
                mesh.children[c] = cache.meshesFlatMap[$ mesh.children[c]];
            }
            
            var parentUuid = mesh._parentUuid;
            if (parentUuid != undefined) {
                cache.meshesFlatMap[$ parentUuid].add(mesh);
            } else {
                array_push(objects, mesh);
            }
        }
    }
}
