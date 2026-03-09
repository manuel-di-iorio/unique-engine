if (projectManager.loaded && view_current == 1) {
  var sm = sceneManager;
  var rw = view_wport[1];
  var rh = view_hport[1];

  if (sm.isTransforming()) {
    // RENDER DIRECTLY TO SCREEN DURING TRANSFORMATION (HIGHER PERFORMANCE/INTERACTIVITY)
    sm.renderer.render(sm.scene, sm.camera);
    sm.needsUpdate = true; // Request surface update when transformation stops
  } else {
    // SURFACE CACHING LOGIC (OPTIMIZATION)
    if (sm.autoUpdate || sm.needsUpdate || !surface_exists(sm.surface)) {
      if (!surface_exists(sm.surface)) {
        sm.surface = surface_create(rw, rh);
      } else if (surface_get_width(sm.surface) != rw || surface_get_height(sm.surface) != rh) {
        surface_resize(sm.surface, rw, rh);
      }

      surface_set_target(sm.surface);
      camera_apply(sm.camera.camera);
      draw_clear_alpha(0, 0);
      sm.renderer.render(sm.scene, sm.camera);
      surface_reset_target();

      sm.needsUpdate = false;
    }

    if (surface_exists(sm.surface)) {
      var old_view = matrix_get(matrix_view);
      var old_proj = matrix_get(matrix_projection);

      matrix_set(matrix_view, matrix_build_identity());
      matrix_set(matrix_projection, matrix_build_projection_ortho(rw, -rh, -1, 1));

      draw_surface(sm.surface, -rw / 2, -rh / 2);

      matrix_set(matrix_view, old_view);
      matrix_set(matrix_projection, old_proj);
    }
  }
}
