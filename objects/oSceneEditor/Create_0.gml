// Antialiasing
if (display_aa >= 8) {
    display_reset(8, true);
} else if (display_aa >= 4) {
    display_reset(4, true);
}

device_mouse_dbclick_enable(false);
randomize();

// Maximize the window
runLater(function() {
    window_command_run(window_command_maximize);
}, 12);

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
enableUI = true;

// Setup UI and 3D scene
scrSetupUI();
sceneManager = new SceneManager();
assetManager = new AssetManager();
projectManager = new ProjectManager();
editorManager = new EditorManager();

projectManager.autoLoad();
scrUiResizeViewports();