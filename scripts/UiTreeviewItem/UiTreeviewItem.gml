function UiTreeviewItem(style = {}, props = {}): UiNode(style, props) constructor {
    self.label = props[$ "label"];
    self.type = props[$ "type"];
    self.deletable = props[$ "deletable"] ?? true;
    self.icon = props[$ "icon"];
    self.onSelect = props[$ "onSelect"];
    self.isSelected = false;
    self.collapsed = true;
    
    function draw(x1, y1, x2, y2, hovered, xp1, yp1, xp2, yp2) {
        var ym = ~~mean(y1, y2);
        
        if (hovered) {
            if (mouse_check_button_pressed(mb_left)) {
                self.onSelect(self);
            }
        }
        
        if (self.isSelected) {
            draw_set_color(oSceneEditor.uiColSelected);
            draw_rectangle(xp1, yp1, xp2, yp2, false);
        }
        
        draw_sprite(self.icon, 0, x1 + 7, ym);
        
        draw_set_halign(fa_left); draw_set_valign(fa_middle); draw_set_color(c_white);
        draw_text(x1 + 15 + 7, ym, self.label);
    }
}