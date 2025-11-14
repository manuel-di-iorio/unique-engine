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
projectLoaded = false;

// Initialize project
project = new Project();

// Setup UI and 3D scene
scrSetupUI();
scrSetup3D();

// Initialize asset manager
assetManager = new UeAssetManager();


// Center container for load button
ui.Center = new UiNode({
    name: "Center",
    width: "100%",
    height: "100%",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center"
});
ui.add(ui.Center);

with (ui.Center) {
    function onDraw() {
        draw_set_color(global.UI_COL_BOX);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
    }
}

// Load Project Button
ui.Center.LoadButton = new UiButton("Load Game Maker Project", {
    padding: 10
});

with (ui.Center.LoadButton) {
    // Button click handler - loads project and rebuilds UI
    onClick(function() {
        var selectedFile = get_open_filename("Game Maker Project (.yyp)|*.yyp", "");
        if (selectedFile == "") return;
        
        // Store project path
        global.ProjectPath = selectedFile;
        global.ProjectLocation = filename_path(selectedFile);
        global.ProjectFiles = global.ProjectLocation + "datafiles";
        
        var projectName = filename_name(selectedFile);
        projectName = string_copy(projectName, 1, string_length(projectName) - 4);
        
        window_set_caption(projectName + " - Unique Engine");
        
        // Mark project as loaded and rebuild UI
        with (oSceneEditor) {
            projectLoaded = true;
            
            // Add UI elements
            ui.Center.remove();
            treeview = new EditorUiAssets(ui);
            inspector = new EditorUiInspector(ui);
            
            // Store reference to inspector in the scene editor
            oSceneEditor.inspector = inspector;
                
            // Add the UI elements
            ui.add(ui.Menu, ui.Assets, ui.Scene, ui.Inspector);
            ui.Scene.add(ui.SceneTools);
            
            // Initialize editor state
            global.EditorState.init({
                project,
                inspector,
                treeview: ui.Assets.Treeview,
                transformControls,
                objects
            });
        }
    });
}

ui.Center.add(ui.Center.LoadButton);

// Deprecated properties (kept for compatibility during migration)
// These should be accessed through global.EditorState instead
activeAsset = undefined;
tool = "view";

// Legacy functions - redirect to EditorState
function setActiveAsset(selectedAsset) {
    global.EditorState.setActiveAsset(selectedAsset);
    activeAsset = global.EditorState.activeAsset;
}

function unsetActiveAsset() {
    global.EditorState.clearActiveAsset();
    activeAsset = undefined;
    selectedObject = undefined;
}


