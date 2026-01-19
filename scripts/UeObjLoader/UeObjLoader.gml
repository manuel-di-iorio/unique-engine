function UeObjLoader() constructor {
    // Optional settings
    flipUV = true;
    reverseWinding = true;
    materials = {}; // Loaded with the UeMtlLoader

    function load(fname) {
        gml_pragma("forceinline");
        positions = array_create(99999);
        normals = array_create(99999);
        uvs = array_create(99999);
        colors = array_create(99999);
        positionsIdx = 0;
        normalsIdx = 0;
        uvsIdx = 0;
        colorsIdx = 0;

        currentMesh = undefined;
        currentMaterial = undefined;
        materialLibs = [];
        root = new UeObject3D();

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
        if (currentMesh != undefined) _endMesh();
        positions = undefined;
        normals = undefined;
        uvs = undefined;
        colors = undefined;

        return root;
    }

    function _startNewMesh(name) {
        gml_pragma("forceinline");

        if (currentMesh != undefined) _endMesh();

        // Prepara la nuova mesh
        currentMesh = new UeMesh();
        currentMesh.geometry = new UeGeometry({ canFreeze: false });
        currentVb = vertex_create_buffer();
        currentMesh.geometry.vb = currentVb;
        vertex_begin(currentVb, currentMesh.geometry.format.vf);
        currentMesh.name = name;

        currentVertices = [];
        currentIndices = [];
    }

    function _endMesh() {
        gml_pragma("forceinline");
        vertex_end(currentVb);
        root.add(currentMesh);
    }

    function _parseLine(line) {
        gml_pragma("forceinline");
        var tokens = string_split_ext(string_trim(line), [" "], true);
        var tokensLength = array_length(tokens);
        if (!tokensLength) return;
        var type = tokens[0];

        switch (type) {
            case "v":
                var xx = real(tokens[1]), yy = real(tokens[2]), zz = real(tokens[3]);
                positions[positionsIdx++] = [xx, yy, zz];

                if (tokensLength >= 7) {
                    colors[colorsIdx++] = make_color_rgb(real(tokens[4]) * 255, real(tokens[5]) * 255, real(tokens[6]) * 255);
                } else {
                    colors[colorsIdx++] = c_white;
                }
                break;

            case "vt":
                var u = real(tokens[1]), v = real(tokens[2]);
                if (flipUV) v = 1.0 - v;
                uvs[uvsIdx++] = [u, v];
                break;

            case "vn":
                normals[normalsIdx++] = [real(tokens[1]), real(tokens[2]), real(tokens[3])];
                break;

            case "f":
                if (currentMesh == undefined) _startNewMesh("default");
                _parseFace(tokens, tokensLength);
                break;

            case "o":
            case "g":
                _startNewMesh(tokens[1]);
                break;

            case "usemtl":
                currentMesh.material = materials[$ tokens[1]];
                break;

            case "mtllib":
                array_push(materialLibs, tokens[1]);
                break;
        }
    }

    function _parseFace(tokens, tokensLength) {
        gml_pragma("forceinline");
        var vb = currentVb;
        var count = tokensLength - 1;

        // Cache per i dati dei vertici della faccia (massimo 4 per quad)
        var faceVertices = array_create(count);

        // Prima pass: raccogli e prepara i dati dei vertici
        for (var i = 1; i <= count; i++) {
            var parts = string_split(tokens[i], "/");
            var partsCount = array_length(parts);
            var vi = real(parts[0]) - 1;
            var ti = (partsCount >= 2 && parts[1] != "") ? real(parts[1]) - 1 : -1;
            var ni = (partsCount >= 3 && parts[2] != "") ? real(parts[2]) - 1 : -1;

            var pos = positions[vi];
            var uv = (ti >= 0) ? uvs[ti] : [0, 0];
            var nor = (ni >= 0) ? normals[ni] : [0, 0, 1];
            var col = (vi < colorsIdx) ? colors[vi] : c_white;

            faceVertices[i - 1] = {
                x: pos[0], y: pos[1], z: pos[2],
                nx: nor[0], ny: nor[1], nz: nor[2],
                u: uv[0], v: uv[1],
                color: col
            };
        }

        // Second pass: scrivi direttamente nel vertex buffer
        if (count == 3) {
            // Triangolo semplice
            var indices = reverseWinding ? [2, 1, 0] : [0, 1, 2];
            for (var i = 0; i < 3; i++) {
                var v = faceVertices[indices[i]];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1); // Tangent
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights
            }
        } else if (count == 4) {
            // Quad - triangola in 2 triangoli
            if (reverseWinding) {
                // Primo triangolo: 0,3,1
                var v = faceVertices[0];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                v = faceVertices[3];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                v = faceVertices[1];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                // Secondo triangolo: 1,3,2
                v = faceVertices[1];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                v = faceVertices[3];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                v = faceVertices[2];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights
            } else {
                // Primo triangolo: 0,1,3
                var v = faceVertices[0];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                v = faceVertices[1];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                v = faceVertices[3];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                // Secondo triangolo: 1,2,3
                v = faceVertices[1];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                v = faceVertices[2];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights

                v = faceVertices[3];
                vertex_position_3d(vb, v.x, v.y, v.z);
                vertex_normal(vb, v.nx, v.ny, v.nz);
                vertex_texcoord(vb, v.u, v.v);
                vertex_float4(vb, 1, 0, 0, 1);
                vertex_color(vb, v.color, 1.0);
                vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                vertex_float4(vb, 0, 0, 0, 0); // Bone Weights
            }
        } else {
            // N-gon (fan triangulation)
            for (var i = 1; i < count - 1; i++) {
                var indices = reverseWinding ? [i + 1, i, 0] : [0, i, i + 1];

                for (var j = 0; j < 3; j++) {
                    var v = faceVertices[indices[j]];
                    vertex_position_3d(vb, v.x, v.y, v.z);
                    vertex_normal(vb, v.nx, v.ny, v.nz);
                    vertex_texcoord(vb, v.u, v.v);
                    vertex_float4(vb, 1, 0, 0, 1);
                    vertex_color(vb, v.color, 1.0);
                    vertex_float4(vb, 0, 0, 0, 0); // Bone Indices
                    vertex_float4(vb, 0, 0, 0, 0); // Bone Weights
                }
            }
        }
    }

    function setMaterials(materials) {
        gml_pragma("forceinline");
        self.materials = materials;
    }
}
