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

global.UI = new UiNode({ name: "Unique UI" }, { root: true });
with (global.UI) {
    self.Main = new UiNode({ name: "Main", flexDirection: "row", flexWrap: "wrap", width: "100%", height: "100%", position: "absolute"  });
    self.Overlay = new UiNode({ name: "Overlay", flexDirection: "row", flexWrap: "wrap", width: "100%", height: "100%", position: "absolute" });
    self.add(self.Main, self.Overlay);
}


enum UI_EVENT {
    wheelup,
    wheeldown,
    
    mousedown,
    mouseup,
    click,
    
    mouseover,
    mouseout,

    // enter/leave do not bubble
    mouseenter,
    mouseleave,
}