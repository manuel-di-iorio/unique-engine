function ProjectManager() constructor {
  self.loaded = false;
  self.changes = [];
  self.hasUnsavedChanges = false;
  
  function save() {
    // TODO: Implement actual project save logic
    // This could include:
    // - Exporting assets to JSON
    // - Saving scene data
    // - Writing to project files
    show_debug_message("Project saved!");

    self.markAsSaved();
  }

  function markAsUnsaved() {
    self.hasUnsavedChanges = true;
  }

  function clear() {
    self.changes = [];
    self.hasUnsavedChanges = false;
  }

  function clearProject() {
    self.clear();
    oSceneEditor.assetManager.clear();
    oSceneEditor.editorManager.clear();
    oSceneEditor.sceneManager.clear();
  }
}
