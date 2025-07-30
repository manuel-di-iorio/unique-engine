function UeMtlLoader() constructor {
    materials = {};

    function load(path) {
        gml_pragma("forceinline");
        materials = {};
        baseDir = filename_path(path);

        var buffer = buffer_load(path);
        var size = buffer_get_size(buffer);
        var line = "", byte;

        var current = undefined;
        while (buffer_tell(buffer) < size) {
            byte = buffer_read(buffer, buffer_u8);
            if (byte == 10 || byte == 13) {
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
        _parseLine(line);
        buffer_delete(buffer);
        
        
        // Finalize all materials
        var keys = variable_struct_get_names(materials);
        for (var i = 0, l = array_length(keys); i < l; i++) {
            materials[$ keys[i] ].build();
        }
        
        return materials;
    }

    function _parseLine(line) {
        gml_pragma("forceinline");
        var tokens = string_split_ext(string_trim(line), [" "], true);

        if (!array_length(tokens)) return;
        var type = tokens[0];

        switch (type) {
            case "newmtl":
                var name = tokens[1];
                current = new UeMeshStandardMaterial();
                current.name = name;
                materials[$ name] = current;
                break;

            case "Ka": case "Kd": case "Ks": case "Ke": case "Tf":
                var r = real(tokens[1]), g = real(tokens[2]), b = real(tokens[3]);
                var color = make_color_rgb(r * 255, g * 255, b * 255);
                if (current != undefined) current[$ type] = color;
                break;

            case "Ns":
                if (current != undefined) current.shininess = real(tokens[1]);
                break;

            case "Ni": // Indice rifrazione
                if (current != undefined) current.ior = real(tokens[1]);
                break;

            case "illum": // Modello di illuminazione
                if (current != undefined) current.illum = real(tokens[1]);
                break;

            case "d": // dissolve (alpha)
                if (current != undefined) {
                    current.alpha = real(tokens[1]);
                    if (current.alpha != 1) current.transparent = true;
                }
                break;

            case "Tr": // transparency (inverted alpha)
                if (current != undefined) current.alpha = 1 - real(tokens[1]);
                break;

            case "map_Ka":
            case "map_Kd":
                if (current != undefined) {
                    var currentTex = current.textures[$ "map"];
                    if (currentTex != undefined) currentTex.dispose();
                    current.textures.map = _createTexture(tokens[1]);
                }
                break;

            case "map_bump":
            case "bump":
                if (current != undefined) {
                    var currentTex = current.textures[$ "bump"];
                    if (currentTex != undefined) currentTex.dispose();
                    current.textures.bump = _createTexture(tokens[1]);
                }
                break;
            
            case "map_Ks":
                if (current != undefined) {
                    var currentTex = current.textures[$ "specular"];
                    if (currentTex != undefined) currentTex.dispose();
                    current.textures.specular = _createTexture(tokens[1]);
                }
                break;
            
            case "map_d":
                if (current != undefined) {
                    var currentTex = current.textures[$ "alpha"];
                    if (currentTex != undefined) currentTex.dispose();
                    current.textures.alpha = _createTexture(tokens[1]);
                    current.transparent = true;
                }
                break;
            
            case "disp":
            case "map_disp":
            case "map_displacement":
                if (current != undefined) {
                    var currentTex = current.textures[$ "displacement"];
                    if (currentTex != undefined) currentTex.dispose();
                    current.textures.displacement = _createTexture(tokens[1]);
                }
                break;
        }
    }

    function _createTexture(fname) {
        gml_pragma("forceinline");
        var image = sprite_add(baseDir + fname, 1, false, false, 0, 0);
        if (image < 0) return undefined;
   
        return new UeTexture({ image });
    }
}
