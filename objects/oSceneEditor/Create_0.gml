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


// MOCKUP: Auto-load project for development
if (GM_build_type == "run") {
    var mockupProjectPath = "C:\\Users\\Manuel\\GameMakerProjects\\Unique Engine\\Unique Engine.yyp";
    if (file_exists(mockupProjectPath)) {
        projectManager.setProjectPath(mockupProjectPath);
        
        var ui = global.UI.Main;
        
        // Clear welcome screen
        ui.Center.destroy();
        ui.Center = undefined;
        delete ui.Center;
        
        ui.Scene = new UiNode({ name: "Scene", height: "100%", flex: 1, marginLeft: 5, marginRight: 5 }, { border: true, pointerEvents: true });
        
        editorManager.treeview = new EditorUiAssets(ui);
        editorManager.inspector = new EditorUiInspector(ui);
        editorManager.sceneTools = new EditorUiSceneTools(global.UI.Overlay);

        ui.add(ui.Assets, ui.Scene, ui.Inspector);
        
        projectManager.loaded = true;
      
        ui.Menu.SaveProjectBtn.show();
        ui.Menu.LoadProjectBtn.setMarginLeft(0);
    }
}

scrUiResizeViewports();
