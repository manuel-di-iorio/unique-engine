function UiText(text, style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiText");
    self.text = text;
    self.autoResize = props[$ "autoResize"] ?? true;
    self.halign = fa_left;
    self.valign = fa_top;
    
    // Set the size of the button
    if (self.autoResize) {
        draw_set_font(fText)
        setSize(string_width(self.text), string_height(self.text));
    }
    
    function onDraw() {
        draw_set_font(fText); draw_set_color(c_white); draw_set_halign(self.halign); draw_set_valign(self.valign);
        draw_text(self.x1, self.y1, self.text);
    }
}