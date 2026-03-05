time_source_destroy(time_source_global, true);

if (variable_instance_exists(self, "sceneManager") && sceneManager != undefined && surface_exists(sceneManager.surface)) {
    surface_free(sceneManager.surface);
}
