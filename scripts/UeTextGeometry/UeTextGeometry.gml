/**
 * UeTextGeometry
 * Creates a 3D mesh from a string using a GameMaker font.
 *
 * @param {String} text
 * @param {Asset.GMFont} font
 * @param {Struct} data
 */
function UeTextGeometry(text = "", font = -1, data = {}): UeGeometry(data) constructor {
    self.text = text;
    self.font = font;

    // ---- Default material flags ----
    if (data[$"transparent"] == undefined) data.transparent = true;

    // ---- Typography settings ----
    self.halign     = data[$"halign"] ?? fa_left;
    self.valign     = data[$"valign"] ?? fa_top;
    self.lineHeight = data[$"lineHeight"] ?? 1.0;
    self.spacing    = data[$"spacing"] ?? 1;
    self.fontSize   = data[$"size"] ?? 1.0;
    self.useKerning = data[$"kerning"] ?? false;

    self.textColor  = data[$"color"] ?? c_white;
    self.textAlpha  = data[$"alpha"] ?? 1;

    // ---- Vertex format (P,U,C) ----
    self.format = data[$"format"] ?? global.UE_VFORMAT_PUC;

    self.__fontTexture = undefined;

    // ==========================================================
    // SET TEXT
    // ==========================================================
    function setText(_text) {
        gml_pragma("forceinline");

        self.text = _text;
        

        var len = string_length(_text);
        // ---- Cache glyphs ----
        for (var i = 1; i <= len; i++) {
            var cc = string_ord_at(_text, i);
            if (cc > 32) font_cache_glyph(self.font, cc);
        }

        var info = font_get_info(self.font);
        if (info == undefined) return self;

        var glyphs = info.glyphs;
        var tex    = info.texture;
        
        // ---- Check if texture is ready ----
        // if (tex == -1 || !texture_is_ready(tex)) {
        //     log("Font texture not ready yet, skipping geometry build");
        //     return self;
        // }

        var texW = (tex != -1) ? texture_get_width(tex)  : 1;
        var texH = (tex != -1) ? texture_get_height(tex) : 1;
        log("Font texture loaded:", tex, "Size:", texW, "x", texH);

        // ---- Space width ----
        var spaceShift = info.size * 0.25;
        var gSpace = glyphs[$" "];
        if (gSpace != undefined) {
            spaceShift = gSpace.shift;
        }

        // ---- Split lines ----
        var lines = string_split(_text, "\n");
        var lineCount = array_length(lines);

        // ---- Preallocate (6 vertices per glyph) ----
        var maxVerts = len * 6;
        var posArr = array_create(maxVerts * 3);
        var uvArr  = array_create(maxVerts * 2);
        var colArr = array_create(maxVerts * 2);

        var _pi = 0, ui = 0, ci = 0;

        // ---- Vertical alignment ----
        var baseLineStep = info.size * lineHeight;
        var totalHeight  = (lineCount - 1) * baseLineStep;

        var startZ = 0;
        if (valign == fa_middle) startZ = totalHeight * 0.5;
        else if (valign == fa_bottom) startZ = totalHeight;

        // ==================================================
        // BUILD GEOMETRY
        // ==================================================
        for (var l = 0; l < lineCount; l++) {
            var line = lines[l];
            var lc   = string_length(line);

            // ---- Measure line width ----
            var lineWidth = 0;
            for (var c = 1; c <= lc; c++) {
                var ch = string_char_at(line, c);
                var g  = glyphs[$ ch] ?? glyphs[$ string(ord(ch))];

                if (g != undefined) {
                    lineWidth += (g.shift + spacing) * fontSize;
                } else if (ch == " ") {
                    lineWidth += (spaceShift + spacing) * fontSize;
                }
            }

            var cursorX = 0;
            if (halign == fa_center) cursorX = -lineWidth * 0.5;
            else if (halign == fa_right) cursorX = -lineWidth;

            var lineTopZ = (startZ - l * baseLineStep);

            // ---- Characters ----
            for (var c = 1; c <= lc; c++) {
                var ch = string_char_at(line, c);
                var g  = glyphs[$ ch] ?? glyphs[$ string(ord(ch))];

                if (g == undefined) {
                    if (ch == " ") cursorX += (spaceShift + spacing) * fontSize;
                    continue;
                }

                if (g.x < 0 || g.y < 0) {
                    cursorX += (g.shift + spacing) * fontSize;
                    continue;
                }

                var x1 = cursorX + g.offset * fontSize;
                var x2 = x1 + g.w * fontSize;
                var z1 = (lineTopZ - g.yoffset) * fontSize;
                var z2 = z1 - g.h * fontSize;

                var u1 = g.x / texW;
                var v1 = g.y / texH;
                var u2 = (g.x + g.w) / texW;
                var v2 = (g.y + g.h) / texH;

                // ---- Positions (XZ plane, Y=0) ----
                // CCW Winding: BL -> BR -> TR, BL -> TR -> TL
                // BL
                posArr[_pi++] = x1; posArr[_pi++] = 0; posArr[_pi++] = z2;
                // BR
                posArr[_pi++] = x2; posArr[_pi++] = 0; posArr[_pi++] = z2;
                // TR
                posArr[_pi++] = x2; posArr[_pi++] = 0; posArr[_pi++] = z1;
                
                // BL
                posArr[_pi++] = x1; posArr[_pi++] = 0; posArr[_pi++] = z2;
                // TR
                posArr[_pi++] = x2; posArr[_pi++] = 0; posArr[_pi++] = z1;
                // TL
                posArr[_pi++] = x1; posArr[_pi++] = 0; posArr[_pi++] = z1;

                // ---- UVs ----
                uvArr[ui++] = u1; uvArr[ui++] = v2; // BL
                uvArr[ui++] = u2; uvArr[ui++] = v2; // BR
                uvArr[ui++] = u2; uvArr[ui++] = v1; // TR

                uvArr[ui++] = u1; uvArr[ui++] = v2; // BL
                uvArr[ui++] = u2; uvArr[ui++] = v1; // TR
                uvArr[ui++] = u1; uvArr[ui++] = v1; // TL

                // ---- Colors ----
                for (var k = 0; k < 6; k++) {
                    colArr[ci++] = textColor;
                    colArr[ci++] = textAlpha;
                }

                cursorX += (g.shift + spacing) * fontSize;

                // ---- Kerning ----
                if (useKerning && c < lc && is_array(g.kerning)) {
                    var nextChar = string_ord_at(line, c + 1);
                    var kern = g.kerning;
                    for (var k = 0, kl = array_length(kern); k < kl; k += 2) {
                        if (kern[k] == nextChar) {
                            cursorX += kern[k + 1] * fontSize;
                            break;
                        }
                    }
                }
            }
        }

        // ---- Trim arrays ----
        array_resize(posArr, _pi);
        array_resize(uvArr,  ui);
        array_resize(colArr, ci);

        position = posArr;
        uv       = uvArr;
        color    = colArr;

        computeBoundingBox();
        computeBoundingSphere();

        build();
        return self;
    }

    // ==========================================================
    // FONT TEXTURE
    // ==========================================================
    function getFontTexture() {
        if (__fontTexture != undefined) return __fontTexture;

        var info = font_get_info(self.font);
        if (info == undefined) return undefined;

        __fontTexture = new UeTexture();
        __fontTexture.__cachedTexture = info.texture;
        log(texture_get_width(info.texture));
        return __fontTexture;
    }

    if (text != "") setText(text);
}
