function UiText(text = "", style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiText");
    self.text = text;
    self.autoResize = props[$ "autoResize"] ?? (style[$ "width"] == undefined && style[$ "height"] == undefined) ?? true;
    self.halign = fa_left;
    self.valign = fa_top;
    self.valueGetter = props[$ "valueGetter"];
    self.icon = props[$ "icon"];
    
    // Set the size of the button
    if (self.autoResize) {
        computeSize();
    }
    
    function computeSize() {
        draw_set_font(fText);
        var _w = string_width(self.text);
        if (self.icon != undefined) _w += sprite_get_width(self.icon) + 10;
        setSize(_w, string_height(self.text));
    }
    
    function onStep() {
        if (self.valueGetter != undefined) {
            var _newText = self.valueGetter();
            if (_newText != self.text) {
                self.text = _newText;
                computeSize();
            }
        }
    }
    
    function onDraw() {
        var _x = self.x1;
        
        if (self.icon) {
            draw_sprite(self.icon, 0, _x + 7, ~~mean(self.y1, self.y2));
            _x += 23;
        }
        
        draw_set_font(fText); draw_set_color(c_white); draw_set_halign(self.halign); draw_set_valign(self.valign);
        draw_text(_x, self.y1, self.text);
    }
}