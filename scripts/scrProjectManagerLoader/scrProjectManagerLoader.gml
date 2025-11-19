function ProjectLoader() constructor {
    
    /**
     * Load project from ue.json
     * @param {Struct} projectManager - The project manager instance
     */
    function load(projectManager) {
      var projectDir = projectManager.projectDatafiles + "/Unique Project/";
      var projectJsonPath = projectDir + "project.json";

      // Check if project file exists
      if (!file_exists(projectJsonPath)) {
          show_debug_message("Project file not found. Project path set, but no assets to load.");
          return;
      }

      var projectData = __readJson(projectJsonPath);
    //   __loadAssets(projectData, projectDir);
      projectManager.markAsSaved();
      show_debug_message("Project loaded successfully!");
    }

    function __readJson(filePath) {
        var buf = buffer_load(filePath);
        var jsonString = buffer_read(buf, buffer_text);
        buffer_delete(buf);
        return json_decode(jsonString);
    }
}

