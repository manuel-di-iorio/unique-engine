function UeShaderPass(material, textureUniformName = "map"): UePass() constructor {
  self.material = material;
  self.textureUniformName = textureUniformName;
  self.uniforms = {};
  self.__texture = new UeTexture();

  function build() {
    gml_pragma("forceinline");
    var _mat = self.material;
    if (_mat != undefined) {
      _mat.uniforms = self.uniforms;
      _mat.textures[$ self.textureUniformName] = self.__texture;
      _mat.build();
    }
    return self;
  }

  function render(renderer, writeTarget, readTarget) {
    gml_pragma("forceinline");
    self.__texture.__cachedTexture = surface_get_texture(readTarget.surface);

    var _oldRT = renderer.getRenderTarget();
    renderer.setRenderTarget(self.renderToScreen ? undefined : writeTarget);

    if (self.clear) renderer.clear();

    var _mat = self.material;
    if (_mat != undefined) _mat.use();

    draw_surface(readTarget.surface, 0, 0);

    renderer.setRenderTarget(_oldRT);
    return self;
  }

  function dispose() {
    gml_pragma("forceinline");
    self.material.dispose();
    self.__texture.dispose();
    return self;
  }

  self.build();
}
