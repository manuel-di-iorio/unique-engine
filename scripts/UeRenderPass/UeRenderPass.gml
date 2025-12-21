function UeRenderPass(scene, camera, overrideMaterial = undefined, clearColor = c_white, clearAlpha = 1): UePass() constructor {
  self.clearColor = clearColor;
  self.clearAlpha = clearAlpha;
  self.clearDepth = false;
  self.camera = camera;
  self.scene = scene;
  self.overrideMaterial = overrideMaterial;

  function render(renderer, writeTarget, readTarget) {
    gml_pragma("forceinline");

    var oldOverrideMaterial;
    if (self.overrideMaterial != undefined) {
      oldOverrideMaterial = self.scene.overrideMaterial;
      self.scene.overrideMaterial = self.overrideMaterial;
    }
    
    var oldAutoClear = renderer.autoClear;
    renderer.autoClear = self.clear;

    var oldClearColor = renderer.getClearColor();
    var oldClearAlpha = renderer.getClearAlpha();
    renderer.setClearColor(self.clearColor, self.clearAlpha);
    
    var oldRenderTarget = renderer.getRenderTarget();
    renderer.setRenderTarget(self.renderToScreen ? undefined : writeTarget);
    
    // Apply camera to set view/projection matrices (essential for rendering to surfaces)
    camera_apply(self.camera.camera);

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
