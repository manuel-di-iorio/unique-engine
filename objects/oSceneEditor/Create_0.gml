device_mouse_dbclick_enable(false);

// Anti-aliasing
if (display_aa >= 8) {
    display_reset(8, false);
} else if (display_aa >= 4) {
    display_reset(4, false);
}

// Maximize the window
call_later(3, time_source_units_frames, function() {
    window_command_run(window_command_maximize);
});

// UI Theme
global.UI_COL_BTN_HOVER        = #393B47; // 57,59,71
global.UI_COL_BOX              = #191A21; // 25,26,33
global.UI_COL_TREE_BG          = #2D3039; // 45,48,57
global.UI_COL_SELECTED         = #5A657E; // 90,101,126
global.UI_COL_INSPECTOR_BG     = #282A36; // 40,42,54
global.UI_COL_INPUT_BG         = #21222C; // 33,34,44
global.UI_COL_SELECTION        = #464a53; // 53,57,66
global.UI_COL_CHECKBOX_HOVER   = #8993a0; // 137,147,160
global.UI_COL_DROPDOWN_LIST_BG = #181818; // 24,24,24

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
        global.ProjectPath = mockupProjectPath;
        global.ProjectLocation = filename_path(mockupProjectPath);
        global.ProjectFiles = global.ProjectLocation + "datafiles";
        
        window_set_caption("Unique Engine");
        
        var ui = global.UI.Main;
        
        // Clear welcome screen
        ui.Center.destroy();
        ui.Center = undefined;
        delete ui.Center;
        
        ui.Scene = new UiNode({ name: "Scene", height: "100%", flex: 1, marginLeft: 5, marginRight: 5 }, { border: true, pointerEvents: true });
        
        editorManager.treeview = new EditorUiAssets(ui);
        editorManager.inspector = new EditorUiInspector(ui);

        ui.add(ui.Assets, ui.Scene, ui.Inspector);
        
        projectManager.loaded = true;
      
        ui.Menu.SaveProjectBtn.show();
        ui.Menu.LoadProjectBtn.setMarginLeft(0);
    }
}

scrUiResizeViewports();
