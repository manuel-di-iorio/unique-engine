function UeBufferExporter() constructor {
    /**
     * Export a scene or a mesh to a buffer, which is a chain of object buffers (textures, geometries, etc)
     * @param {UeScene|UeMesh} object
     * @return {Buffer}
     */
    function parse(object) {
        var obj = object[$ "isScene"] ? object : { children: [object] };
        
        // Build the child buffers
        var childrenData = {};
        var size = _buildChildrenBuffers(obj, childrenData);
        
        // Write the scene buffer with buffer type and scene uuid
        var buffer = buffer_create(size, buffer_fixed, 1);
        
        // Copy the children buffers into the main buffer
        var offset = 0;
        var childrenDataNames = variable_struct_get_names(childrenData);
        var childrenDataNamesCount = variable_struct_names_count(childrenData);
        
        for (var i = 0; i < childrenDataNamesCount; i++) {
            var childData = childrenData[$ childrenDataNames[i]];
            buffer_copy(childData.buffer, 0, childData.size, buffer, offset);
            buffer_delete(childData.buffer);
            offset += childData.size;
        }

        var compressedBuffer = buffer_compress(buffer, 0, offset);
        buffer_delete(buffer);
        return compressedBuffer;
    }
    
    /**
     * 
     */
    function _buildChildrenBuffers(obj, childrenData) {
        var _children = obj.children;
        var size = 0;
        
        for (var i = 0, n = array_length(_children); i < n; i++) {
            var child = _children[i];
            
            size += _buildObjBuffer(child, childrenData); 
            
            if (child[$ "isMesh"]) {
                if (child[$ "geometry"]) size += _buildObjBuffer(child.geometry, childrenData);
                if (child[$ "material"]) size += _buildObjBuffer(child.material, childrenData);
            }
            
            size += _buildChildrenBuffers(child, childrenData);
        }
        
        return size;
    }
    
    /**
     * Export an object buffer (if not yet exported)
     */
    function _buildObjBuffer(obj, childrenData) {
        var _uuid = obj.uuid;
        var size = 0;
        
        if (!childrenData[$ _uuid]) {
            var objBuff = obj.export();
            var objBuffSize = buffer_get_size(objBuff);
            size += objBuffSize;
            childrenData[$ _uuid] = { buffer: objBuff, size: objBuffSize };
        }
        
        // If the object is a buffer geometry, also export the vertex format
        if (obj[$ "isBufferGeometry"]) size += _buildObjBuffer(obj.format, childrenData);
        
        // If the object is a material, also export its textures
        if (obj[$ "isMaterial"]) {
            var textures = obj.textures;
            var texturesNames = variable_struct_get_names(textures);
            var texturesNamesCount = variable_struct_names_count(textures);
            
            for (var i = 0; i < texturesNamesCount; i++) {
                 size += _buildObjBuffer(textures[$ texturesNames[i]], childrenData);
            }
        }
        
        return size;
    }
}