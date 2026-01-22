/**
 * UeTextGeometry
 * Creates a 3D mesh from a string using a GameMaker font.
 * 
 * @param {String} text The text to render
 * @param {Asset.GMFont} font The font asset to use
 * @param {Struct} data Configuration data (halign, valign, lineHeight, spacing, color, size, etc.)
 */
function UeTextGeometry(text = "", font = -1, data = {}): UeGeometry(data) constructor {
    self.data = data;
    self.text = text;
    self.font = font;
    self.halign = data[$ "halign"] ?? fa_left;
    self.valign = data[$ "valign"] ?? fa_top;
    self.lineHeight = data[$ "lineHeight"] ?? 1.0;
    self.spacing = data[$ "spacing"] ?? 0;
    self.fontSize = data[$ "size"] ?? 1.0; // Scale factor
    
    // Use PNUC format by default for text (Position, Normal, UV, Color)
    self.format = data[$ "format"] ?? global.UE_VFORMAT_PNUC;

    // Store parent build reference before overriding it
    super_build = build;
    
    build = function() {
        if (font == -1 || text == "") return self;
        
        // Ensure all characters are cached in the font's texture page
        var len = string_length(text);
        for (var i = 1; i <= len; i++) {
            var charCode = string_ord_at(text, i);
            if (charCode > 32) { 
                font_cache_glyph(font, charCode);
            }
        }
        
        var info = font_get_info(font);
        if (info == undefined) return self;
        
        var glyphs = info.glyphs;
        var tex = info.texture;
        
        // Safety: font without valid texture
        var texW = 1, texH = 1;
        if (tex != -1) {
            texW = texture_get_width(tex);
            texH = texture_get_height(tex);
        }
        
        var lines = string_split(text, "\n");
        var lineCount = array_length(lines);
        
        var posArr = [];
        var normArr = [];
        var uvArr = [];
        var colArr = [];
        var idxArr = [];
        
        var color = self.data[$ "color"] ?? c_white;
        var alpha = self.data[$ "alpha"] ?? 1.0;
        
        // Calculate total height for vertical alignment
        // Coordinate System: Z+ is Up (Sky), Y+ is Forward (Depth)
        var baseLineHeight = info.size * lineHeight;
        var totalHeight = (lineCount - 1) * baseLineHeight; // Adjusted for better baseline control
        
        var startZ = 0;
        if (valign == fa_middle) startZ = totalHeight * 0.5;
        else if (valign == fa_bottom) startZ = totalHeight;
        
        var vOffset = 0;
        
        for (var l = 0; l < lineCount; l++) {
            var line = lines[l];
            var charCount = string_length(line);
            
            // Calculate line width for horizontal alignment
            var lineWidth = 0;
            for (var c = 1; c <= charCount; c++) {
                var char = string_char_at(line, c);
                var g = glyphs[$ char];
                if (g != undefined) {
                    lineWidth += (g[$ "shift"] ?? 0) + spacing;
                    // Add kerning if applicable
                    if (c < charCount) {
                        var nextChar = string_char_at(line, c + 1);
                        var kerning = g[$ "kerning"];
                        if (is_array(kerning)) {
                            for (var k = 0; k < array_length(kerning); k += 2) {
                                if (kerning[k] == ord(nextChar)) {
                                    lineWidth += kerning[k+1];
                                    break;
                                }
                            }
                        }
                    }
                }
            }
            
            var startX = 0;
            if (halign == fa_center) startX = -lineWidth * 0.5;
            else if (halign == fa_right) startX = -lineWidth;
            
            var cursorX = startX;
            var cursorZ = startZ - (l * baseLineHeight);
            
            for (var c = 1; c <= charCount; c++) {
                var char = string_char_at(line, c);
                var g = glyphs[$ char];
                if (g == undefined) {
                    // Handle spaces by advancing cursor
                    if (char == " ") cursorX += (info.size * 0.25) + spacing;
                    continue;
                }
                
                var _gx = g[$ "x"] ?? -1;
                var _gy = g[$ "y"] ?? -1;
                
                // If the glyph is not in the texture yet (x/y = -1), skip it
                if (_gx == -1 || _gy == -1) {
                   cursorX += (g[$ "shift"] ?? 0) + spacing;
                   continue;
                }

                var _shift = g[$ "shift"] ?? 0;
                var _offset = g[$ "offset"] ?? 0;
                var _yoffset = g[$ "yoffset"] ?? 0;
                var _w = g[$ "w"] ?? 0;
                var _h = g[$ "h"] ?? 0;
                
                // Character quad bounds
                // Orientation: Upright facing Camera (Y-), so on XZ plane
                var x1 = cursorX + _offset;
                var z1 = cursorZ - _yoffset;
                var x2 = x1 + _w;
                var z2 = z1 - _h;
                
                // Apply font size scale
                x1 *= fontSize; x2 *= fontSize;
                z1 *= fontSize; z2 *= fontSize;
                
                // UVs
                var u1 = _gx / texW;
                var v1 = _gy / texH;
                var u2 = (_gx + _w) / texW;
                var v2 = (_gy + _h) / texH;
                
                // Add vertices (4 per char)
                // Plano XZ (Y=0), Normale (0, -1, 0)
                array_push(posArr, x1, 0, z1,  x2, 0, z1,  x2, 0, z2,  x1, 0, z2);
                array_push(normArr, 0, -1, 0,  0, -1, 0,   0, -1, 0,   0, -1, 0);
                array_push(uvArr, u1, v1,      u2, v1,    u2, v2,    u1, v2);
                array_push(colArr, color, alpha, color, alpha, color, alpha, color, alpha);
                
                // Indices (2 triangles)
                array_push(idxArr, vOffset, vOffset + 1, vOffset + 2, vOffset, vOffset + 2, vOffset + 3);
                
                vOffset += 4;
                
                // Advance cursor
                cursorX += _shift + spacing;
                // Kerning
                if (c < charCount) {
                    var nextChar = string_char_at(line, c + 1);
                    var kerning = g[$ "kerning"];
                    if (is_array(kerning)) {
                        for (var k = 0; k < array_length(kerning); k += 2) {
                            if (kerning[k] == ord(nextChar)) {
                                cursorX += kerning[k+1];
                                break;
                            }
                        }
                    }
                }
            }
        }
        
        self.position = posArr;
        self.normal = normArr;
        self.uv = uvArr;
        self.color = colArr;
        self.index = idxArr;
        
        // If the format includes bones, add dummy data
        if (format == global.UE_VFORMAT_PNUTCB) {
            var vcount = array_length(posArr) / 3;
            self.boneIndices = array_create(vcount * 4, 0);
            self.boneWeights = array_create(vcount * 4, 0);
        }
        
        // Compute bounds for proper culling
        computeBoundingBox();
        computeBoundingSphere();
        
        // Submit to GPU
        super_build();
        return self;
    }
    
    /**
     * Updates the text and rebuilds the geometry
     * @param {String} newText
     */
    setText = function(newText) {
        if (text == newText) return self;
        text = newText;
        build();
        return self;
    }

    // Initial build
    build();
}
