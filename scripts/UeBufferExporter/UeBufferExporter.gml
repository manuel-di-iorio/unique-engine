function UeBufferExporter() constructor {
    /**
     * Export a scene or a mesh to a buffer
     */
    // @MissingDoc
    function parse(obj, compileSprites = true) {
        var compilation = {
            size: 0,
            elems: [],
            cache: {},
            compileSprites
        };
         
        _compileObject(obj, compilation);
        
        if (obj[$ "isScene"]) {
            _compileChildren(obj, "lights", compilation);
        }
        
        var buffer = buffer_create(compilation.size, buffer_fixed, 1);
        _buildObjects(buffer, compilation);
   
        var compressedBuffer = buffer_compress(buffer, 0, buffer_get_size(buffer)+1);
        buffer_delete(buffer);
        return compressedBuffer;
    }
    
    function _compileObject(obj, compilation) {
        if (!obj[$ "isScene"] && !compilation.cache[$ obj.uuid]) {
            // Stringify the object's payload, by also enhancing it with other props
            var compiledData = obj._compileData(compilation);
            var payload = compiledData.payload;
            payload.type = obj.type;
            payload.uuid = obj.uuid;
            if (obj[$ "name"] != undefined) payload.name = obj.name;
            var payloadStr = json_stringify(payload);
            compiledData.payloadStr = payloadStr;
            
            // Update the compilation info
            compilation.cache[$ obj.uuid] = true;
            compilation.size += string_byte_length(payloadStr) + 1;
            array_push(compilation.elems, compiledData);
        }
        
        switch (obj.type) {
            case "BufferGeometry": 
                _compileObject(obj.format, compilation); 
                break;
            
            case "Material":
                struct_foreach(obj.textures, method({ compilation, _compileObject }, function(textureUuid, texture) {
                    _compileObject(texture, compilation);
                }));
                break;
            
            case "Mesh":
                if (obj[$ "geometry"] != undefined) _compileObject(obj[$ "geometry"], compilation);
                if (obj[$ "material"] != undefined) _compileObject(obj[$ "material"], compilation);
                break; 
        }
        
        _compileChildren(obj, "children", compilation);
    }
        
    function _compileChildren(obj, listField, compilation) {
        var children = obj[$ listField];
        if (children != undefined) {
            for (var i = 0, n = array_length(children); i < n; i++) {
               _compileObject(children[i], compilation);
            }
        }
    }
    
    function _buildObjects(buffer, compilation) {
        var elems = compilation.elems;
        
        for (var i = 0, n = array_length(elems); i < n; i++) {
            var elem = elems[i];
            buffer_write(buffer, buffer_string, elem.payloadStr);
            
            // Write the object's extra data to the buffer (eg. sprite, vbuffer, etc..)
            var compileBufferExtra = elem.obj[$ "_compileBufferExtra"];
            if (compileBufferExtra) compileBufferExtra(buffer, elem[$ "ctx"]);
        }
    }
}