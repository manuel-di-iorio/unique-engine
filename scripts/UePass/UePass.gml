function UePass() constructor {
  self.isPass = true;
  self.enabled = true;
  self.needsSwap = true;
  self.renderToScreen = false;
  self.clear = true;

  function render(renderer, writeTarget, readTarget) {
    gml_pragma("forceinline");
    show_debug_message("UePass.render() is not implemented in the derived class.");
    return self;
  }

  /** @abstract */
  function dispose() {
    gml_pragma("forceinline");
    show_debug_message("UePass.dispose() is not implemented in the derived class.");
    return self;
  }

  /** @abstract */
  function setSize(width, height) {
    gml_pragma("forceinline");
    show_debug_message("UePass.setSize() is not implemented in the derived class.");
    return self;
  }
}
