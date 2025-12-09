function UeTexturePass(texture, opacity = 1) : UePass() constructor {
    self.map = texture;
    self.opacity = opacity;
    
    function render(renderer, writeTarget, readTarget) {
        gml_pragma("forceinline");
        
        if (self.renderToScreen != undefined) {
          surface_set_target(writeTarget.surface);
        }
        
        if (self.clear) {
          draw_clear_alpha(self.clearColor, self.clearAlpha);
        }
        
        // Save GPU state
        var _ztest = gpu_get_ztestenable();
        var _zwrite = gpu_get_zwriteenable();
        var _cull = gpu_get_cullmode();
        var _blend = gpu_get_blendenable();
        
        // Setup 2D state for blitting
        gpu_set_ztestenable(false);
        gpu_set_zwriteenable(false);
        gpu_set_cullmode(cull_noculling);
        gpu_set_blendenable(true);
        
        var _tex = self.map;
        
        // Determine dimensions
        var _w = renderer.width;
        var _h = renderer.height;
        if (!self.renderToScreen && writeTarget != undefined) {
            _w = writeTarget.width;
            _h = writeTarget.height;
        }
        
        draw_sprite_stretched(_tex.__cachedSprite, 0, 0, 0, _w, _h);
        
        if (self.renderToScreen != undefined) {
          surface_reset_target();
        }
        
        // Restore state
        gpu_set_ztestenable(_ztest);
        gpu_set_zwriteenable(_zwrite);
        gpu_set_cullmode(_cull);
        gpu_set_blendenable(_blend);
        
        return self;
    }
}
