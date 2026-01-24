function UiInspectorMeshPreview(style = {}, props = {}): UiNode(style, props) constructor {
  self.asset = props[$ "asset"];
  self.previewSprite = undefined;
  self.renderSize = 256;

  // Listen for changes in the mesh or its material
  self.onAssetChanged = function (event) {
    self.updatePreview();
  };

  oSceneEditor.events.on("assetChanged", self.onAssetChanged);

  self.updatePreview = function () {
    if (self.asset == undefined) return;

    if (self.previewSprite != undefined) {
      sprite_delete(self.previewSprite);
      self.previewSprite = undefined;
    }

    var _renderer = new UeRenderer({
      toneMapping: UE_TONE_MAPPING.REINHARD
    });
    var _scene = new UeScene();
    var _camera = new UePerspectiveCamera({ fov: 45, near: 0.1, far: 10000, aspect: 1 });
    var _target = new UeRenderTarget(self.renderSize, self.renderSize);

    // Setup lights
    var _ambient = new UeAmbientLight(c_white, 0.5);
    var _dirLight = new UeDirectionalLight(c_white, 0.8, { x: 100, y: 100, z: 100 });
    _scene.add(_ambient, _dirLight);

    // Temporarily add the asset to the preview scene without reparenting
    // This allows us to render the entire subtree of the asset
    array_push(_scene.children, self.asset);

    // Auto-center and fit camera using the entire subtree bounding box
    var _bbox = box3_create();
    box3_set_from_object(_bbox, self.asset);

    var _center = box3_get_center(_bbox, vec3_create());
    var _size = box3_get_size(_bbox, vec3_create());
    var _maxDim = max(_size[0], _size[1], _size[2]);

    if (_maxDim <= 0) _maxDim = 1; // Fallback for empty objects

    // Position camera to see the mesh center with a more frontal angle
    var _dist = (_maxDim / (2 * tan(degtorad(_camera.fov) / 2))) * 1.5;
    // Looking from slightly side/top but mostly front (-Y is front)
    vec3_set(_camera.position, _center[0] + _dist * 0.25, _center[1] - _dist * 1.5, _center[2] + _dist * 0.25);
    vec3_set(_camera.target, _center[0], _center[1], _center[2]);
    _camera.updateMatrixWorld();

    // Render
    _renderer.setRenderTarget(_target);

    // Clear surface
    if (!surface_exists(_target.surface)) _target.create();
    surface_set_target(_target.surface);
    draw_clear_alpha(global.UI_COL_INPUT_BG, 1);

    // Apply camera matrices
    camera_apply(_camera.camera);

    _renderer.render(_scene, _camera);
    surface_reset_target();
    _renderer.setRenderTarget(undefined);

    // Remove the asset from the preview scene
    array_pop(_scene.children);

    // Convert to sprite
    if (self.previewSprite != undefined) {
      sprite_delete(self.previewSprite);
    }
    self.previewSprite = sprite_create_from_surface(_target.surface, 0, 0, self.renderSize, self.renderSize, false, false, 0, 0);

    // Cleanup resources
    _target.dispose();
  }

  self.onDraw = function () {


    var _w = self.x2 - self.x1;
    var _h = self.y2 - self.y1;

    // Background box
    draw_set_color(global.UI_COL_INPUT_BG);
    draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);

    if (self.previewSprite != undefined) {
      var _scale = min(_w / self.renderSize, _h / self.renderSize);

      var _drawW = self.renderSize * _scale;
      var _drawH = self.renderSize * _scale;
      var _drawX = self.x1 + (_w - _drawW) / 2;
      var _drawY = self.y1 + (_h - _drawH) / 2;

      draw_sprite_ext(self.previewSprite, 0, _drawX, _drawY, _scale, _scale, 0, c_white, 1);
    }

    draw_set_color(global.UI_COL_BOX);
    draw_rectangle(self.x1, self.y1, self.x2, self.y2, true);
  }

  self.onDestroy = function () {
    if (self.asset != undefined) {
      oSceneEditor.events.off("assetChanged", self.onAssetChanged);
    }

    if (self.previewSprite != undefined) {
      sprite_delete(self.previewSprite);
      self.previewSprite = undefined;
    }
  };

  if (self.previewSprite == undefined) {
    self.updatePreview();
  }
}
