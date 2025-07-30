function UeObjLoader() constructor {
    // Optional settings
    flipUV = true;
    reverseWinding = false;
    materials = {}; // Loaded with the UeMtlLoader
    
    root = undefined;
    positions = [];
    normals = [];
    uvs = [];
    colors = [];
    meshes = [];
    currentMesh = undefined;
    currentMaterial = undefined;
    materialLibs = [];

    function load(fname) {
        root = new UeMesh();
        var buffer = buffer_load(fname);
        var size = buffer_get_size(buffer);
        var line = "";
        var char, byte;

        while (buffer_tell(buffer) < size) {
            byte = buffer_read(buffer, buffer_u8);
            if (byte == 13 || byte == 10) {
                _parseLine(line);
                line = "";

                // Gestione CRLF (13 + 10)
                var nextByte = buffer_peek(buffer, buffer_tell(buffer), buffer_u8);
                if (nextByte == 10 || nextByte == 13) {
                    buffer_seek(buffer, buffer_seek_relative, 1);
                }
            } else {
                line += chr(byte);
            }
        }
        if (line != "") _parseLine(line); // last line

        buffer_delete(buffer);
        _buildGeometries();
        
        return root;
    }

     function _startNewMesh(name) {
        if (currentMesh != undefined) {
            currentMesh.geometry.vertices = currentVertices;
            currentMesh.geometry.index = currentIndices;
            currentMesh.geometry.build();
            if (currentMaterial != undefined) currentMesh.material = currentMaterial;
            array_push(meshes, currentMesh);
        }
    
        // Prepara la nuova mesh
        currentMesh = new UeMesh();
        currentMesh.geometry = new UeBufferGeometry({ canFreeze: false });
        currentMesh.name = name;
    
        currentVertices = [];
        currentIndices = [];
    }

    function _parseLine(line) {
        var tokens = string_split_ext(string_trim(line), [" "], true);
        if (!array_length(tokens)) return;
        var type = tokens[0];

        switch (type) {
            case "v":
                var xx = real(tokens[1]), yy = real(tokens[2]), zz = real(tokens[3]);
                array_push(positions, [xx, yy, zz]);
                if (array_length(tokens) >= 7) {
                    var r = real(tokens[4]) * 255;
                    var g = real(tokens[5]) * 255;
                    var b = real(tokens[6]) * 255;
                    array_push(colors, make_color_rgb(r, g, b));
                } else {
                    array_push(colors, c_white);
                }
                break;

            case "vt":
                var u = real(tokens[1]), v = real(tokens[2]);
                if (flipUV) v = 1.0 - v;
                array_push(uvs, [u, v]);
                break;

            case "vn":
                array_push(normals, [real(tokens[1]), real(tokens[2]), real(tokens[3])]);
                break;

            case "f":
                if (currentMesh == undefined) _startNewMesh("default");
                _parseFace(tokens);
                break;

            case "o":
            case "g":
                _startNewMesh(tokens[1]);
                break;

            case "usemtl":
                currentMaterial = materials[$ tokens[1]];
                break;

            case "mtllib":
                array_push(materialLibs, tokens[1]);
                break;
        }
    }

    function _parseFace(tokens) {
        var count = array_length(tokens) - 1;
        var baseIndex = array_length(currentVertices);
        var faceIndices = [];
    
        for (var i = 1; i <= count; i++) {
            var parts = string_split(tokens[i], "/");
            var vi = real(parts[0]) - 1;
            var ti = (array_length(parts) >= 2 && parts[1] != "") ? real(parts[1]) - 1 : -1;
            var ni = (array_length(parts) >= 3 && parts[2] != "") ? real(parts[2]) - 1 : -1;
    
            var pos = positions[vi];
            var uv  = (ti >= 0) ? uvs[ti] : [0, 0];
            var nor = (ni >= 0) ? normals[ni] : [0, 0, 1];
            var col = (vi < array_length(colors)) ? colors[vi] : c_white;
    
            var vert = {
                x: pos[0], y: pos[1], z: pos[2],
                nx: nor[0], ny: nor[1], nz: nor[2],
                u: uv[0], v: uv[1],
                color: col,
                alpha: 1
            };
    
            array_push(currentVertices, vert);
            array_push(faceIndices, baseIndex + i - 1);
        }
    
        if (count > 3) {
            for (var i = 1; i < count - 1; i++) {
                if (reverseWinding) {
                    array_push(currentIndices, faceIndices[i + 1]);
                    array_push(currentIndices, faceIndices[i]);
                    array_push(currentIndices, faceIndices[0]);
                } else {
                    array_push(currentIndices, faceIndices[0]);
                    array_push(currentIndices, faceIndices[i]);
                    array_push(currentIndices, faceIndices[i + 1]);
                }
            }
        } else if (count == 3) {
            if (reverseWinding) {
                array_push(currentIndices, faceIndices[2]);
                array_push(currentIndices, faceIndices[1]);
                array_push(currentIndices, faceIndices[0]);
            } else {
                for (var j = 0; j < array_length(faceIndices); j++) {
                    array_push(currentIndices, faceIndices[j]);
                }
            }
        }
    }

    function _buildGeometries() {
        if (currentMesh != undefined) {
            currentMesh.geometry.vertices = currentVertices;
            currentMesh.geometry.index = currentIndices;
            currentMesh.geometry.build();
            if (currentMaterial != undefined) currentMesh.material = currentMaterial;
            
            array_push(meshes, currentMesh);
            root.add(currentMesh);
        }
    }
    
    function setMaterials(materials) {
        self.materials = materials;
    }
}
