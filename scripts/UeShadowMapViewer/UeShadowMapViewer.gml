function UeShadowMapViewer(light, data = {}) constructor {
    self.light = light;
    self.enabled = data[$ "enabled"] ?? true;
    self.width = data[$ "width"] ?? 256;
    self.height = data[$ "height"] ?? 256;
    
    /**
     * Renders the viewer.
     */
    static render = function(camera, x1, y1) {
        if (!self.enabled) return;
        if (!self.light || !self.light.shadow || !self.light.shadow.map) return;
        
        // Ensure surface exists
        if (!surface_exists(self.light.shadow.map.surface)) return;

        var _surface_width = self.light.shadow.map.width;
        var _surface_height = self.light.shadow.map.height;
        var _scale_x = self.width / _surface_width;
        var _scale_y = self.height / _surface_height;
        
        // Draw the surface
        // Flip Y for spot lights
        if(self.light[$ "isSpotLight"]) {
            draw_surface_ext(self.light.shadow.map.surface, x1, y1 + self.height, _scale_x, -_scale_y, 0, c_white, 1);
        } else {
            draw_surface_ext(self.light.shadow.map.surface, x1, y1, _scale_x, _scale_y, 0, c_white, 1);
        }
        
        // Draw labels for point lights
        if (self.light[$ "isPointLight"]) {
            var faceW = (self.width / 3);
            var faceH = (self.height / 2);
            var labels = ["-Z", "+Z", "-Y", "+Y", "-X", "+X"];
            
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            
            for (var i = 0; i < 6; i++) {
                var fx = x1 + (i % 3) * faceW;
                var fy = y1 + floor(i / 3) * faceH;
                
                draw_set_color(c_maroon);
                draw_rectangle(fx, fy, fx + faceW - 1, fy + faceH - 1, true);
                
                draw_set_color(c_ltgray);
                draw_text(fx + faceW / 2, fy + faceH / 2, labels[i]);
            }
        }
    }
}
