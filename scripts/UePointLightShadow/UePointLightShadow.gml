/**
 * Shadow configuration for point lights.
 * Uses a cube shadow map approach packed into a 3x2 atlas.
 * This allows omnidirectional shadow casting from point lights using a single texture.
 */
function UePointLightShadow(data = {}): UeLightShadow(data) constructor {
  var _near = data[$ "near"] ?? 0.5;
  var _far = data[$ "far"] ?? 500;

  // 6 cameras for the 6 faces of the cube
  self.cameras = array_create(6);
  for (var i = 0; i < 6; i++) {
    self.cameras[i] = new UePerspectiveCamera({
      fov: 90,
      aspect: 1,
      near: _near,
      far: _far
    });
  }

  // Single shadow map (atlas) - 3x2 grid of faces
  self.map = new UeShadowMap(sh_ue_point_shadow, mapSize.width * 3, mapSize.height * 2);

  // Temporary surface for rendering individual faces
  self.__faceSurface = -1;

  // Shader uniforms for sh_ue_point_shadow
  self.__uLightPosLoc = shader_get_uniform(sh_ue_point_shadow, "u_lightPos");
  self.__uNearLoc = shader_get_uniform(sh_ue_point_shadow, "u_near");
  self.__uFarLoc = shader_get_uniform(sh_ue_point_shadow, "u_far");

  // Face directions
  // Ordered as: -Z, Z, -Y, Y, -X, X
  self.__targets = [
    [0, 0, -1], [0, 0, 1],   // 0, 1 (-Z, Z)
    [0, -1, 0], [0, 1, 0],   // 2, 3 (-Y, Y)
    [-1, 0, 0], [1, 0, 0]    // 4, 5 (-X, X)
  ];

  // Up vectors for each face (matching world Up = [0, 0, -1])
  self.__ups = [
    [0, 1, 0], [0, -1, 0],  // For Z faces, Up is Y+ / Y-
    [0, 0, -1], [0, 0, -1],  // For Y faces, Up is Z-
    [0, 0, -1], [0, 0, -1]   // For X faces, Up is Z-
  ];

  /**
   * Updates the shadow map size.
   * @param {number} width - New face width
   * @param {number} height - New face height
   */
  function updateMapSize(width, height) {
    gml_pragma("forceinline");
    mapSize.width = width;
    mapSize.height = height;
    self.map.width = width * 3;
    self.map.height = height * 2;
    self.map.create();
    return self;
  }

  /**
   * Updates all 6 shadow cameras based on light position.
   * @param {Struct} light - The point light source
   */
  function updateMatrices(light) {
    gml_pragma("forceinline");

    // Use world position for shadow cameras
    var lp = global.UE_VEC3_TEMP1;
    light.updateWorldMatrix(true, false);
    light.getWorldPosition(lp);

    for (var i = 0; i < 6; i++) {
      var cam = self.cameras[i];
      var targetRel = self.__targets[i];
      var upRel = self.__ups[i];

      // Position at light
      vec3_copy(cam.position, lp);

      // Look at target
      cam.target[0] = lp[0] + targetRel[0];
      cam.target[1] = lp[1] + targetRel[1];
      cam.target[2] = lp[2] + targetRel[2];

      // Set up vector
      cam.upX = upRel[0];
      cam.upY = upRel[1];
      cam.upZ = upRel[2];

      // Update matrices
      cam.updateMatrixWorld();
    }
    return self;
  }

  /**
   * Renders the faces of the shadow map into the atlas.
   */
  function render(light, scene, camera, __queue, __shadowIdx) {
    gml_pragma("forceinline");

    // Update all cameras and matrices first
    self.updateMatrices(light);

    if (!surface_exists(self.map.surface)) self.map.create();
    if (!surface_exists(self.__faceSurface)) {
      self.__faceSurface = surface_create(mapSize.width, mapSize.height, surface_r32float);
    }

    // Prepare the atlas surface
    surface_set_target(self.map.surface);
    draw_clear(c_white);
    surface_reset_target();

    for (var i = 0; i < 6; i++) {
      var cam = self.cameras[i];

      // 1. Render face to temporary surface
      surface_set_target(self.__faceSurface);
      draw_clear(c_white);

      // Check if shader exists before setting
      if (shader_is_compiled(sh_ue_point_shadow)) {
        global.UE_RENDERER_ACTIVE_SHADOW_SHADER = sh_ue_point_shadow;
        shader_set(sh_ue_point_shadow);

        // Set uniforms for linear depth
        var lp = global.UE_VEC3_TEMP1;
        light.getWorldPosition(lp);
        shader_set_uniform_f_array(self.__uLightPosLoc, lp);
        shader_set_uniform_f(self.__uNearLoc, cam.near);
        shader_set_uniform_f(self.__uFarLoc, cam.far);
      }

      // Apply camera for this face
      cam.updateProjectionMatrix(); // Assicuriamoci che la proiezione sia aggiornata
      camera_apply(cam.camera);

      // Render objects
      var _frustum = cam.getFrustum();
      global.UE_RENDERER_ACTIVE_SHADOW_CAMERA = cam;
      
      for (var j = 0; j < __shadowIdx; j++) {
        var object = __queue[j];

        // Se non proietta ombre o non ha una mesh, saltiamo
        if (!object.castShadow || object.geometry == undefined) continue;

        // Frustum culling
        if (object.frustumCulled) {
          var s = object.__intersectionSphere;
          if (s != undefined && !frustum_intersects_sphere(_frustum, s)) {
            continue;
          }
        }

        var _onBeforeShadow = object[$ "onBeforeShadow"];
        var _onAfterShadow = object[$ "onAfterShadow"];
        
        if (_onBeforeShadow != undefined) _onBeforeShadow();
        object.render();
        if (_onAfterShadow != undefined) _onAfterShadow();
      }

      surface_reset_target();

      // 2. Copy the face to the atlas (3x2 grid)
      surface_set_target(self.map.surface);

      shader_reset();
      var _filter = gpu_get_tex_filter();
      gpu_set_tex_filter(false);
      gpu_set_blendenable(false);

      // Calculate atlas position
      var _col = i % 3;
      var _row = floor(i / 3);
      var _ax = _col * mapSize.width;
      var _ay = _row * mapSize.height;

      draw_surface(self.__faceSurface, _ax, _ay);

      gpu_set_blendenable(true);
      gpu_set_tex_filter(_filter);

      surface_reset_target();
    }

    return self;
  }

  /**
   * Disposes of all resources.
   */
  function dispose() {
    gml_pragma("forceinline");
    for (var i = 0; i < 6; i++) {
      self.cameras[i].dispose();
    }
    if (surface_exists(self.__faceSurface)) {
      surface_free(self.__faceSurface);
    }
    self.map.dispose();
    return self;
  }
}
