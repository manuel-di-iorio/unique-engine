function UiInspectorMeshPreview(style = {}, props = {}): UiNode(style, props) constructor {
  self.asset = props[$ "asset"];
  self.previewSprite = undefined;
  self.previewObject = undefined;
  self.renderSize = 256;
  self.pointerEvents = true;

  // Preview rendering
  self.renderer = undefined;
  self.scene = undefined;
  self.camera = undefined;
  self.target = undefined;
  self.needsRender = true;
  
  // Custom orbit rotation
  self._dragging = false;
  self._prevMX = 0;
  self._prevMY = 0;
  self._azimuth = 0;
  self._elevation = 0;
  self._radius = 1;
  self._orbitCenter = vec3_create(0, 0, 0);

  // Listen for changes in the mesh or its material
  self.onAssetChanged = function (event) {
    self.setupPreview();
  };

  global.editor.events.on("assetChanged", self.onAssetChanged);

  self.setupPreview = function () {
    if (self.asset == undefined) return;

    // Cleanup old resources
    if (self.previewSprite != undefined) {
      sprite_delete(self.previewSprite);
      self.previewSprite = undefined;
    }
    if (self.renderer != undefined) {
      self.renderer = undefined;
    }

    // Create new resources
    self.renderer = new UeRenderer({
      toneMapping: UE_TONE_MAPPING.REINHARD
    });
    self.scene = new UeScene();
    self.camera = new UePerspectiveCamera({ fov: 45, near: 0.1, far: 10000, aspect: 1 });
    self.target = new UeRenderTarget(self.renderSize, self.renderSize);

    // Setup lights
    var _ambient = new UeAmbientLight(c_white, 0.5);
    var _dirLight = new UeDirectionalLight(c_white, 0.8, { x: 100, y: 100, z: 100 });
    self.scene.add(_ambient, _dirLight);

    // Force matrix update to ensure bounding box is computed correctly from local transform
    if (struct_exists(self.asset, "forceUpdate")) {
      self.asset.forceUpdate(true);
    }

    // Add the asset to the preview scene
    array_push(self.scene.children, self.asset);

    // Auto-center and fit camera using the entire subtree bounding box
    var _bbox = box3_create();
    box3_set_from_object(_bbox, self.asset);

    var _center, _size;
    if (box3_is_empty(_bbox)) {
        _center = vec3_create(0, 0, 0);
        _size = vec3_create(2, 2, 2);
    } else {
        _center = box3_get_center(_bbox, vec3_create());
        _size = box3_get_size(_bbox, vec3_create());
    }
    var _maxDim = max(_size[0], _size[1], _size[2]);

    if (_maxDim <= 0) _maxDim = 1; // Fallback for empty objects

    // Position camera to see the mesh center with a more frontal angle
    var _dist = (_maxDim / (2 * tan(degtorad(self.camera.fov) / 2))) * 1.5;
    
    // Looking from slightly side/top but mostly front (-Y is front)
    vec3_set(self.camera.position, _center[0] + _dist * 0.25, _center[1] - _dist * 1.5, _center[2] + _dist * 0.25);
    vec3_set(self.camera.target, _center[0], _center[1], _center[2]);
    self.camera.updateMatrixWorld();

    // Compute initial spherical coordinates from camera position
    var _dir = vec3_create(
      self.camera.position[0] - _center[0],
      self.camera.position[1] - _center[1],
      self.camera.position[2] - _center[2]
    );
    self._radius = vec3_length(_dir);
    self._azimuth = arctan2(_dir[1], _dir[0]);
    self._elevation = (self._radius == 0) ? 0 : arcsin(clamp(_dir[2] / self._radius, -1, 1));
    vec3_set(self._orbitCenter, _center[0], _center[1], _center[2]);
    self._dragging = false;

    self.needsRender = true;
    self.renderPreview();
  }

  self.renderPreview = function() {
    if (self.asset == undefined || self.scene == undefined) return;

    self.renderer.setRenderTarget(self.target);

    // Clear surface
    if (!surface_exists(self.target.surface)) self.target.create();
    surface_set_target(self.target.surface);
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
    self.previewSprite = sprite_create_from_surface(self.target.surface, 0, 0, self.renderSize, self.renderSize, false, false, 0, 0);

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

  self.updatePreview = function () {
    if (self.asset == undefined) return;
    self.setupPreview();
  }

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
    self._radius = max(self._radius, 0.01);
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

    self.previewObject = undefined;

    if (self.target != undefined) {
      self.target.dispose();
      self.target = undefined;
    }

    self.renderer = undefined;
    self.scene = undefined;
    self.camera = undefined;
  };

  if (self.previewSprite == undefined) {
    self.setupPreview();
  }
}
