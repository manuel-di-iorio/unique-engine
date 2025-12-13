function UeTexturePass(texture, opacity = 1) : UePass() constructor {
    self.map = texture;
    self.opacity = opacity;
    self.material = undefined;
    self.uniforms = {};
    self.__texture = new UeTexture();
    
    function build() {
      gml_pragma("forceinline");
      var _mat = self.material;
      if (_mat != undefined) {
        if (!_mat.uniforms[$ "opacity"] == undefined) {
          _mat.uniforms.opacity = { type: UE_UNIFORM_TYPE.FLOAT, value: self.opacity };
        }

        _mat.textures[$ "map"] = self.__texture;

        _mat.build();
      }
      return self;
    }

    function render(renderer, writeTarget, readTarget) {
        gml_pragma("forceinline");
        var _oldRenderTarget = renderer.getRenderTarget();
        renderer.setRenderTarget(self.renderToScreen ? undefined : writeTarget);

        if (self.clear) {
          renderer.clear();
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
        
        // Apply material / texture and draw with alpha
        var _mat = self.material;
        if (_mat != undefined) _mat.use();
        
        // Use draw_sprite_ext to apply alpha when drawing the cached sprite
        var _alpha = self.opacity != undefined ? self.opacity : 1;
        draw_sprite_ext(_tex.__cachedSprite, 0, 0, 0, _w / sprite_get_width(_tex.__cachedSprite), _h / sprite_get_height(_tex.__cachedSprite), 0, c_white, _alpha);

        // Restore renderer target
        renderer.setRenderTarget(_oldRenderTarget);
        
        // Restore state
        gpu_set_ztestenable(_ztest);
        gpu_set_zwriteenable(_zwrite);
        gpu_set_cullmode(_cull);
        gpu_set_blendenable(_blend);
        
        return self;
  }

  function dispose() {
    gml_pragma("forceinline");
    self.__texture.dispose();
    return self;
  }

  self.build();
}
