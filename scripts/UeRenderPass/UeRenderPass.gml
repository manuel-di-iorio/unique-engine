function UeRenderPass(scene, camera, overrideMaterial = undefined, clearColor = c_white, clearAlpha = 1): UePass() constructor {
  self.clearColor = clearColor;
  self.clearAlpha = clearAlpha;
  self.clearDepth = false;
  self.camera = camera;
  self.scene = scene;
  self.overrideMaterial = overrideMaterial;

  function render(renderer, writeTarget, readTarget) {
    gml_pragma("forceinline");

    var oldAutoClear = renderer.autoClear;
    renderer.autoClear = false;

    var oldOverrideMaterial;
    if (self.overrideMaterial != undefined) {
        oldOverrideMaterial = self.scene.overrideMaterial;
        self.scene.overrideMaterial = self.overrideMaterial;
    }

    var oldClearColor = renderer.getClearColor();
    var oldClearAlpha = renderer.getClearAlpha();
    if (self.clearColor != undefined) {
        renderer.setClearColor(self.clearColor, self.clearAlpha);
    }

    if (self.clearDepth) {
      renderer.clearDepth();
    }

    var oldRenderTarget = renderer.getRenderTarget();
    renderer.setRenderTarget(self.renderToScreen ? undefined : writeTarget);

    if (self.clear) {
      renderer.clear(self.clearColor, self.clearDepth, false);
    }

    renderer.render(self.scene, self.camera);
    
    // Restore the previous values
    renderer.autoClear = oldAutoClear;
    if (self.clearColor != undefined) renderer.setClearColor(oldClearColor);
    if (self.clearAlpha != undefined) renderer.setClearAlpha(oldClearAlpha);
    renderer.setRenderTarget(oldRenderTarget);
    
    if (self.overrideMaterial != undefined) {
      self.scene.overrideMaterial = oldOverrideMaterial;
    }
    
    return self;
  }
}
