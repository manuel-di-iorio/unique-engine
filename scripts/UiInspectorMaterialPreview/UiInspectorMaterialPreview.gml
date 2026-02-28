function UiInspectorMaterialPreview(style = {}, props = {}): UiNode(style, props) constructor {
  self.asset = props[$ "asset"];
  self.previewSprite = undefined;
  self.renderSize = 150;

  // Listen for changes in the material// Listen for changes in the mesh or its material
  self.onAssetChanged = function (event) {
    self.updatePreview();
  };

  global.editor.events.on("assetChanged", self.onAssetChanged);

  self.updatePreview = function () {
    if (self.asset == undefined) return;

    var _renderer = new UeRenderer();
    var _scene = new UeScene();
    var _camera = new UePerspectiveCamera({ fov: 45, near: 0.1, far: 1000, aspect: 1 });
    var _target = new UeRenderTarget(self.renderSize, self.renderSize);

    // Setup lights
    var _ambient = new UeAmbientLight(c_white, 0.5);
    var _dirLight = new UeDirectionalLight(c_white, 0.8, { x: 100, y: 100, z: 100 });
    _scene.add(_ambient, _dirLight);

    // Setup sphere with the material
    var _geom = new UeSphereGeometry(50, { lats: 32, lons: 32 });
    var _mesh = new UeMesh(_geom, self.asset);
    _mesh.setRotation(90, 0, 0);
    _scene.add(_mesh);

    // Position camera to see the sphere
    vec3_set(_camera.position, 0, -150, 0);
    vec3_set(_camera.target, 0, 0, 0);
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

    // Convert to sprite
    if (self.previewSprite != undefined) {
      sprite_delete(self.previewSprite);
    }
    self.previewSprite = sprite_create_from_surface(_target.surface, 0, 0, self.renderSize, self.renderSize, false, false, 0, 0);

    // Cleanup resources
    _geom.dispose();
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
      global.editor.events.off("assetChanged", self.onAssetChanged);
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
