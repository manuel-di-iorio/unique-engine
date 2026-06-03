/// @desc UiBadge — small status indicator with colored background and label.
/// Variants: "default", "primary", "success", "warning", "danger", "info"
function UiBadge(text, style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiBadge");
    self.text    = text;
    self.variant = props[$ "variant"] ?? "default";
    self.dot     = props[$ "dot"]     ?? false; // Show as a dot (no text)
    
    // Size defaults if not specified
    if (style[$ "height"] == undefined) self.setHeight(self.dot ? 10 : 26);
    if (!self.dot && style[$ "width"] == undefined) {
        draw_set_font(fTextSmall);
        self.setWidth(string_width(text) + 24);
    } else if (self.dot) {
        self.setWidth(10);
        self.setHeight(10);
    }
    
    function __badge_colors() {
        var accent = global.UI_COL_TEXT_DIM;
        switch (self.variant) {
            case "primary": accent = global.UI_COL_PRIMARY; break;
            case "success": accent = global.UI_COL_SUCCESS; break;
            case "warning": accent = global.UI_COL_WARNING; break;
            case "danger":  accent = global.UI_COL_DANGER; break;
            case "info":    accent = #0EA5E9; break;
        }
        
        if (self.dot) {
            return { bg: accent, text: accent, border: accent };
        }

        return {
            bg: merge_color(accent, global.UI_COL_BG_CARD, 0.76),
            text: merge_color(accent, global.UI_COL_TEXT_MAIN, 0.12),
            border: merge_color(accent, global.UI_COL_BORDER, 0.45)
        };
    }
    
    self.onDraw = function() {
        var cols = __badge_colors();
        var r    = self.dot ? min(self.width, self.height) / 2 : 8;
        
        draw_set_color(cols.bg);
        if (self.dot) {
            draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, r, r, false);
        } else {
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        }
        
        if (!self.dot) {
            draw_set_color(cols.border);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, true);
        }
        
        if (!self.dot && self.text != undefined && self.text != "") {
            draw_set_font(fTextSmall);
            draw_set_color(cols.text);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text(floor(mean(self.x1, self.x2)), floor(mean(self.y1, self.y2)), self.text);
        }
    };
    
    /// @desc Updates the badge text and resizes.
    function setText(_text) {
        self.text = _text;
        if (!self.dot) {
            draw_set_font(fTextSmall);
            self.setWidth(string_width(_text) + 24);
        }
        global.UI.requestRedraw();
    }
    
    /// @desc Changes the badge variant.
    function setVariant(_variant) {
        self.variant = _variant;
        global.UI.requestRedraw();
    }
}
