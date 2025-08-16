// UI Theme
global.UI_COL_BTN_HOVER    = #393B47;
global.UI_COL_BOX          = #191A21;
global.UI_COL_TREE_BG      = #2D3039;
global.UI_COL_SELECTED     = #5A657E;
global.UI_COL_INSPECTOR_BG = #282A36;
// #52B9B9 cyan
// #F012BE magenta

// Globals
global.UI_ID = 0;
global.UI_CLICK_START = undefined;

global.UI_ASSETS_TEXTURES_ID = 0;
global.UI_ASSETS_MATERIALS_ID = 0;
global.UI_ASSETS_MODELS_ID = 0;
global.UI_ASSETS_LIGHTS_ID = 0;
global.UI_ASSETS_CAMERAS_ID = 0;
global.UI_ASSETS_SCENES_ID = 0;

global.UI = new UiNode({ name: "Unique UI", flexDirection: "row", flexWrap: "wrap" });

enum UI_EVENT {
    wheelup,
    wheeldown,
    
    mousedown,
    mouseup,
    //mousemove,
    
    //mouseover,
    //mouseout,
    
    // enter/leave do not bubble
    //mouseenter,
    //mouseleave,
    click,
}