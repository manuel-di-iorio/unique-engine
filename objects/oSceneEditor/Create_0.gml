device_mouse_dbclick_enable(false);
randomize();

// Anti-aliasing
if (display_aa >= 8) {
    display_reset(8, false);
} else if (display_aa >= 4) {
    display_reset(4, false);
}

// Maximize the window
call_later(12, time_source_units_frames, function() {
    window_command_run(window_command_maximize);
});

// Asset ID counters (for naming new assets)
global.UI_ASSETS_TEXTURES_ID = 0;
global.UI_ASSETS_MATERIALS_ID = 0;
global.UI_ASSETS_MODELS_ID = 0;
global.UI_ASSETS_LIGHTS_ID = 0;
global.UI_ASSETS_CAMERAS_ID = 0;
global.UI_ASSETS_SCENES_ID = 0;
global.UI_ASSETS_INSTANCE_ID = 0;
global.UI_ASSETS_FOLDERS_ID = 0;

uiDebug = false;

// Setup UI and 3D scene
scrSetupUI();
sceneManager = new SceneManager();
assetManager = new AssetManager();
projectManager = new ProjectManager();
editorManager = new EditorManager();


// Auto-load project from settings
if (file_exists("settings.json")) {
    var buf = buffer_load("settings.json");
    var jsonString = buffer_read(buf, buffer_text);
    buffer_delete(buf);
    
    var settings = json_parse(jsonString);
    if (settings[$ "lastProject"] != undefined) {
        scrEditorLoadProject(settings.lastProject);
    }
}

scrUiResizeViewports();
