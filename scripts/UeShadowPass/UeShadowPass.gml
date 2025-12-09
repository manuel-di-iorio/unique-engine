function UeShadowPass(material, textureUniformName = "map"): UePass() constructor {
  self.material = material.clone();
  self.textureUniformName = textureUniformName;
  self.uniforms = {};
  self.__texture = new UeTexture();

  function build() {
    gml_pragma("forceinline");
    self.material.uniforms = self.uniforms;
    self.material.textures[$ self.textureUniformName] = self.__texture;
    self.material.build();
    return self;
  }

  function render(renderer, writeTarget, readTarget) {
    gml_pragma("forceinline");
    self.__texture.__cachedTexture = surface_get_texture(readTarget.surface);
    surface_set_target(writeTarget.surface);
    self.material.use();
    draw_surface(readTarget.surface, 0, 0);
    surface_reset_target();
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
