/// @description Project Manager - Main project management class

function ProjectManager() constructor {
    self.loaded = false;
    self.changes = {}; // Struct with UUID as key
    self.hasUnsavedChanges = false;
    self.projectPath = "";           // Full path to .yyp file
    self.projectLocation = "";       // Directory containing the .yyp
    self.projectDatafiles = "";      // Path to datafiles folder
    self.projectName = "Untitled";
    
    /**
     * Set the project path and update related paths
     */
    function setProjectPath(path) {
        self.projectPath = path;
        self.projectLocation = filename_path(path);
        self.projectDatafiles = self.projectLocation + "datafiles";
        
        var projectName = filename_name(path);
        projectName = string_copy(projectName, 1, string_length(projectName) - 4);
        self.projectName = projectName;
        
        self.updateWindowCaption();
    }
    
    /**
     * Update window caption with unsaved changes indicator
     */
    function updateWindowCaption() {
        var caption = self.projectName + " - Unique Engine";
        if (self.hasUnsavedChanges) {
            caption += "*";
        }
        window_set_caption(caption);
    }
    
    /**
     * Save the entire project
     */
    function save() {
        saver.save(self);
    }
    
    /**
     * Load project from disk
     */
    function load() {
        loader.load(self);
    }
    
    /**
     * Mark project as saved
     */
    function markAsSaved() {
        self.hasUnsavedChanges = false;
        self.changes = {};
        self.updateWindowCaption();
    }
    
    /**
     * Mark project as unsaved
     */
    function markAsUnsaved() {
        self.hasUnsavedChanges = true;
        self.updateWindowCaption();
    }
    
    /**
     * Clear changes
     */
    function clear() {
        self.changes = {};
        self.hasUnsavedChanges = false;
    }
    
    /**
     * Clear entire project
     */
    function clearProject() {
        var ui = global.UI.Main;
        self.clear();
        oSceneEditor.assetManager.clear();
        oSceneEditor.editorManager.clear();
        oSceneEditor.sceneManager.clear();
        ui.Inspector.destroy();
        ui.Assets.destroy();
        ui.Scene.destroy();
    }
    
    function autoLoad() {
       // Auto-load project from settings
       if (file_exists("settings.json")) {
          var buf = buffer_load("settings.json");
          var jsonString = buffer_read(buf, buffer_text);
          buffer_delete(buf);
          
          try {
              var settings = json_parse(jsonString);
              if (settings[$ "lastProject"] != undefined) {
                  scrEditorLoadProject(settings.lastProject);
              }
          } catch (e) {
              show_debug_message("FAILED TO PARSE settings.json");
              show_debug_message("CONTENT: " + jsonString);
          }
       } 
    }

    saver = new ProjectSaver();
    loader = new ProjectLoader();
    
}
