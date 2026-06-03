function UiInspectorMaterialPreview(style = {}, props = {}): UiNode(style, props) constructor {
  self.asset = props[$ "asset"];
  self.previewSprite = undefined;
  self.renderSize = 150;
  self.pointerEvents = true;

  // Preview rendering
  self.renderer = undefined;
  self.scene = undefined;
  self.camera = undefined;
  self.renderTarget = undefined;
  self.previewMesh = undefined;
  self.needsRender = true;
  
  // Custom orbit rotation
  self._dragging = false;
  self._prevMX = 0;
  self._prevMY = 0;
  self._azimuth = -pi / 2;
  self._elevation = 0;
  self._radius = 150;
  self._orbitCenter = vec3_create(0, 0, 0);

  // Listen for changes in the material
  self.onAssetChanged = function (event) {
    self.needsRender = true;
  };

  global.editor.events.on("assetChanged", self.onAssetChanged);

  self.setupPreview = function () {
    if (self.asset == undefined) return;

    // Cleanup old resources
    if (self.previewSprite != undefined) {
      sprite_delete(self.previewSprite);
      self.previewSprite = undefined;
    }

    // Create new resources
    self.renderer = new UeRenderer();
    self.scene = new UeScene();
    self.camera = new UePerspectiveCamera({ fov: 45, near: 0.1, far: 1000, aspect: 1 });
    self.renderTarget = new UeRenderTarget(self.renderSize, self.renderSize);

    // Setup lights
    var _ambient = new UeAmbientLight(c_white, 0.5);
    var _dirLight = new UeDirectionalLight(c_white, 0.8, { x: 100, y: 100, z: 100 });
    self.scene.add(_ambient, _dirLight);

    // Setup sphere with the material
    var _geom = new UeSphereGeometry(50, { lats: 32, lons: 32 });
    self.previewMesh = new UeMesh(_geom, self.asset);
    self.previewMesh.setRotation(90, 0, 0);
    self.scene.add(self.previewMesh);

    // Position camera using spherical coordinates
    self._azimuth = -pi / 2;
    self._elevation = 0;
    self._radius = 150;
    vec3_set(self._orbitCenter, 0, 0, 0);
    self._updateCameraFromSpherical();
    self._dragging = false;

    self.needsRender = true;
    self.renderPreview();
  }

  self.renderPreview = function() {
    if (self.asset == undefined || self.scene == undefined) return;

    self.renderer.setRenderTarget(self.renderTarget);

    // Clear surface
    if (!surface_exists(self.renderTarget.surface)) self.renderTarget.create();
    surface_set_target(self.renderTarget.surface);
    draw_clear_alpha(global.UI_COL_INSPECTOR_BG, 1);

    // Apply camera matrices
    camera_apply(self.camera.camera);

    self.renderer.render(self.scene, self.camera);
    surface_reset_target();
    self.renderer.setRenderTarget(undefined);

    // Convert to sprite
    if (self.previewSprite != undefined) {
      sprite_delete(self.previewSprite);
    }
    self.previewSprite = sprite_create_from_surface(self.renderTarget.surface, 0, 0, self.renderSize, self.renderSize, false, false, 0, 0);

    self.needsRender = false;
  }

  /// Reposition camera using current spherical coordinates
  self._updateCameraFromSpherical = function() {
    var _cosElev = cos(self._elevation);
    vec3_set(self.camera.position,
      self._orbitCenter[0] + self._radius * _cosElev * cos(self._azimuth),
      self._orbitCenter[1] + self._radius * _cosElev * sin(self._azimuth),
      self._orbitCenter[2] + self._radius * sin(self._elevation)
    );
    vec3_set(self.camera.target, self._orbitCenter[0], self._orbitCenter[1], self._orbitCenter[2]);
    self.camera.updateMatrixWorld();
  };

  // --- Mouse interaction via UI event system ---

  // Start drag on mouse down
  self.onMouseDown(function() {
    self._dragging = true;
    self._prevMX = window_mouse_get_x();
    self._prevMY = window_mouse_get_y();
    return true;
  });

  // Scroll wheel zoom - return true to stop propagation to parent scrollbar
  self.onWheelUp(function() {
    if (self.camera == undefined) return false;
    self._radius *= 0.9;
    self._radius = max(self._radius, 1);
    self._updateCameraFromSpherical();
    self.needsRender = true;
    return true;
  });

  self.onWheelDown(function() {
    if (self.camera == undefined) return false;
    self._radius *= 1.1;
    self._updateCameraFromSpherical();
    self.needsRender = true;
    return true;
  });

  // Per-frame step: handle drag continuation + render
  self.onStep(function() {
    if (self._dragging) {
      if (mouse_check_button(mb_left)) {
        var _mx = window_mouse_get_x();
        var _my = window_mouse_get_y();
        var _dx = _mx - self._prevMX;
        var _dy = _my - self._prevMY;

        if (_dx != 0 || _dy != 0) {
          self._azimuth -= _dx * 0.01;
          self._elevation += _dy * 0.01;
          self._elevation = clamp(self._elevation, -pi / 2 + 0.01, pi / 2 - 0.01);

          self._updateCameraFromSpherical();
          self.needsRender = true;
        }

        self._prevMX = _mx;
        self._prevMY = _my;
      } else {
        self._dragging = false;
      }
    }

    // Request UI redraw so onDraw is called and the surface gets updated
    if (self.needsRender) {
      self.requestRedraw();
    }
  });

  self.onDraw = function () {
    // Render in draw event (surface_set_target requires draw context)
    if (self.needsRender && self.camera != undefined) {
      self.renderPreview();
    }

    var _w = self.x2 - self.x1;
    var _h = self.y2 - self.y1;

    // Background box
    draw_set_color(global.UI_COL_INSPECTOR_BG);
    draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);

    if (self.previewSprite != undefined) {
      var _scale = min(_w / self.renderSize, _h / self.renderSize);

      var _drawW = self.renderSize * _scale;
      var _drawH = self.renderSize * _scale;
      var _drawX = self.x1 + (_w - _drawW) / 2;
      var _drawY = self.y1 + (_h - _drawH) / 2;

      draw_sprite_ext(self.previewSprite, 0, _drawX, _drawY, _scale, _scale, 0, c_white, 1);
    }

    draw_set_color(global.UI_COL_BORDER);
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

    if (self.renderTarget != undefined) {
      self.renderTarget.dispose();
      self.renderTarget = undefined;
    }

    self.previewMesh = undefined;
    self.renderer = undefined;
    self.scene = undefined;
    self.camera = undefined;
  };

  if (self.previewSprite == undefined) {
    self.setupPreview();
  }
}
