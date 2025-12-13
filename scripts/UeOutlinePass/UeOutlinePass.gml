function UeOutlinePass(scene, camera, selectedObjects = []): UePass() constructor {
  // Outline material using the provided shader
  self.material = new UeMaterial({
    shader: sh_ue_outline_pass,
    blending: false,
  });
  self.uniforms = {};
  self.material.uniforms = self.uniforms;
  self.renderScene = scene;
  self.renderCamera = camera;
  self.selectedObjects = selectedObjects;
  self.fullscreenQuad = undefined;

  // Optional outline parameters
  self.visibleEdgeColor = [1, 1, 1];
  self.edgeGlow = 0;
  self.edgeStrength = 3;
  self.edgeThickness = 1;
  self.hiddenEdgeColor = [0.1, 0.04, 0.02];
  self.pulsePeriod = 0;
  self.thickness = 1;

  function build() {
    gml_pragma("forceinline");
    self.material.uniforms = self.uniforms;

    if (self.uniforms != undefined) {
       self.uniforms[$ "visibleEdgeColor"] = { type: UE_UNIFORM_TYPE.ARRAY, value: self.visibleEdgeColor };
       self.uniforms[$ "thickness"] = { type: UE_UNIFORM_TYPE.FLOAT, value: self.thickness };
       self.uniforms[$ "edgeStrength"] = { type: UE_UNIFORM_TYPE.FLOAT, value: self.edgeStrength };
       self.uniforms[$ "edgeGlow"] = { type: UE_UNIFORM_TYPE.FLOAT, value: self.edgeGlow };
       self.uniforms[$ "hiddenEdgeColor"] = { type: UE_UNIFORM_TYPE.ARRAY, value: self.hiddenEdgeColor };
       self.uniforms[$ "texelSize"] = { type: UE_UNIFORM_TYPE.VEC2, value: [1, 1] };
    }

    self.material.build();
    self.fullscreenQuad = new UeFullscreenQuad(self.material);
    return self;
  }

  function render(renderer, writeTarget, readTarget) {
    gml_pragma("forceinline");

    var _oldRT = renderer.getRenderTarget();
    renderer.setRenderTarget(self.renderToScreen ? undefined : writeTarget);

     if (!surface_exists(readTarget.surface)) {
      readTarget.create();
    }

    if (self.clear) renderer.clear();

    // Calculate texel size from the read target
    self.material.setUniform("texelSize", [1 / readTarget.width, 1 / readTarget.height]);
    var _gpuState = gpu_get_state();
    
    // Set up orthographic camera for fullscreen quad rendering
    var _oldView = view_current;
    var _orthoCamera = new UeOrthographicCamera({
      left: 0,
      right: readTarget.width,
      top: 0,
      bottom: readTarget.height,
      near: -1,
      far: 1,
      view: 0
    });
    _orthoCamera.setPosition(readTarget.width / 2, readTarget.height / 2, 0);
    _orthoCamera.target.set(readTarget.width / 2, readTarget.height / 2, 0);
    _orthoCamera.upX = 0;
    _orthoCamera.upY = 1;
    _orthoCamera.upZ = 0;
    _orthoCamera.updateMatrixWorld();
    _orthoCamera.updateProjectionMatrix();
    
    // Render using fullscreen quad
    self.fullscreenQuad.render(renderer);
    
    // Restore camera
    if (_oldView != undefined) {
      view_set_camera(_oldView, camera_get_active());
    }
    _orthoCamera.dispose();

    renderer.setRenderTarget(_oldRT);
    gpu_set_state(_gpuState);
    return self;
  }

  function dispose() {
    gml_pragma("forceinline");
    if (self.fullscreenQuad != undefined) {
      self.fullscreenQuad.dispose();
      self.fullscreenQuad = undefined;
    }
    return self;
  }

  self.build();
}

