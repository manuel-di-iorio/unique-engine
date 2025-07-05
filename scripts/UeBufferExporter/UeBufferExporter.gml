function UeBufferExporter() constructor {
    /**
     * Export a scene or a mesh to a buffer
     */
    function parse(obj, compileSprites = true) {
        var compilation = {
            size: 0,
            elems: [],
            compileSprites
        };
        _compileObject(obj, compilation);
        
        var buffer = buffer_create(compilation.size, buffer_fixed, 1);
        _buildObjects(buffer, compilation);
   
        var compressedBuffer = buffer_compress(buffer, 0, buffer_get_size(buffer));
        buffer_delete(buffer);
        return compressedBuffer;
    }
    
    function _compileObject(obj, compilation) {
        if (!obj[$ "isScene"]) {
            // Compile the data of the object
            var compiledData = obj._compileData(compilation);
            compiledData.payload = json_stringify(compiledData.payload);
            array_push(compilation.elems, compiledData);
            compilation.size += string_byte_length(compiledData.payload);
        }
        
        if (obj[$ "isBufferGeometry"]) {
            _compileObject(obj.format, compilation);
        }
        
        if (obj[$ "isMaterial"]) {
            var textures = obj.textures;
            for (var i = 0, n = array_length(textures); i < n; i++) {
                _compileObject(textures[i], compilation);
            }
        }
        
        if (obj[$ "isMesh"]) {
            if (obj[$ "geometry"]) _compileObject(obj[$ "geometry"], compilation);
            if (obj[$ "material"]) _compileObject(obj[$ "material"], compilation);
        }
        
        // Recursively compile the children
        var children = obj[$ "children"];
        if (children != undefined) {
            for (var i = 0, n = array_length(obj.children); i < n; i++) {
               _compileObject(children[i], compilation);
            }
        }
    }
    
    function _buildObjects(buffer, compilation) {
        var elems = compilation.elems;
        
        for (var i = 0, n = array_length(elems); i < n; i++) {
            var elem = elems[i];
            buffer_write(buffer, buffer_string, elem.payload);
            
            // Write the object's extra data to the buffer (eg. sprite, vbuffer, etc..)
            var compileBufferExtra = elem.obj[$ "_compileBufferExtra"];
            if (compileBufferExtra) compileBufferExtra(buffer, elem[$ "ctx"]);
        }
    }
}