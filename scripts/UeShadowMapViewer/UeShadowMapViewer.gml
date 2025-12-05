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
        draw_surface_ext(self.light.shadow.map.surface, x1, y1, _scale_x, _scale_y, 0, c_white, 1);
    }
}