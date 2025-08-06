function UiText(text, style = {}, props = {}): UiNode(style, props) constructor {
    self.text = text;
    self.autoResize = props[$ "autoResize"] ?? true;
    self.halign = fa_left;
    self.valign = fa_top;
    self.hoverable = false;
    
    // Set the size of the button
    if (self.autoResize) {
        draw_set_font(fText)
        setSize(string_width(self.text), string_height(self.text));
    }
    
    function draw(x1, y1, x2, y2, hovered, xp1, yp1, xp2, yp2) {
        draw_set_font(fText); draw_set_color(c_white); draw_set_halign(self.halign); draw_set_valign(self.valign);
        draw_text(x1, y1, self.text);
    }
}