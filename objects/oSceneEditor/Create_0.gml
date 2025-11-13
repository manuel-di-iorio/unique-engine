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

// Initialize project
project = new Project();

// Setup UI and 3D scene
scrSetupUI();
scrSetup3D();

// Initialize asset manager
assetManager = new UeAssetManager();

// Initialize editor state with references
global.EditorState.init({
    project,
    inspector,
    treeview: ui.Assets.Treeview,
    transformControls,
    objects
});

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


