global.UI_VERSION = "4.1.0";

// UI Theme — Modern Premium Palette
global.UI_COL_PRIMARY          = #2F6FEF;
global.UI_COL_PRIMARY_HOVER    = #215CDA;
global.UI_COL_BG_SIDEBAR       = #F8FAFC;
global.UI_COL_BG_MAIN          = #FBFCFF;
global.UI_COL_BG_CARD          = #FFFFFF;
global.UI_COL_TEXT_MAIN        = #13213A;
global.UI_COL_TEXT_DIM         = #60708D;
global.UI_COL_BORDER           = #DDE5F0;
global.UI_COL_BTN_HOVER        = #EDF3FF;
global.UI_COL_DROPDOWN_LIST_BG = #172338;
global.UI_COL_INSPECTOR_BG     = #EEF3FA;
global.UI_COL_SELECTION        = #3B82F6;
global.UI_COL_SUCCESS          = #23A75A;
global.UI_COL_WARNING          = #F59E0B;
global.UI_COL_DANGER           = #EF4444;
global.UI_COL_SCROLLBAR_THUMB  = #CBD5E1;

/// @desc Sets a scissor rect using GUI coordinates, automatically scaling them to real window/viewport space.
function __uui_set_scissor(x, y, w, h) {
    var factor_x = window_get_width() / max(1, display_get_gui_width());
    var factor_y = window_get_height() / max(1, display_get_gui_height());
    gpu_set_scissor(x * factor_x, y * factor_y, w * factor_x, h * factor_y);
}

// ── Dynamic Theme Management ───────────────────────────────────────────────
global.UI_THEMES = {};

global.UI_THEMES.dark = {
    primary: #3B82F6,
    primaryHover: #2563EB,
    bgSidebar: #0B0F19,
    bgMain: #0F172A,
    bgCard: #1E293B,
    textMain: #F8FAFC,
    textDim: #CBD5E1,
    border: #334155,
    btnHover: #334155,
    dropdownListBg: #1E293B,
    inspectorBg: #1E293B,
    selection: #3B82F6,
    success: #22C55E,
    warning: #F59E0B,
    danger: #EF4444,
    scrollbarThumb: #475569
};

global.UI_THEMES.light = {
    primary: #2F6FEF,
    primaryHover: #215CDA,
    bgSidebar: #F8FAFC,
    bgMain: #FBFCFF,
    bgCard: #FFFFFF,
    textMain: #13213A,
    textDim: #60708D,
    border: #DDE5F0,
    btnHover: #EDF3FF,
    dropdownListBg: #172338,
    inspectorBg: #EEF3FA,
    selection: #3B82F6,
    success: #23A75A,
    warning: #F59E0B,
    danger: #EF4444,
    scrollbarThumb: #CBD5E1
};

/// @desc Sets the active UI theme by name and requests a full redraw.
function ui_set_theme(themeName) {
    var t = global.UI_THEMES[$ themeName];
    if (t == undefined) return;
    global.UI_COL_PRIMARY          = t.primary;
    global.UI_COL_PRIMARY_HOVER    = t.primaryHover;
    global.UI_COL_BG_SIDEBAR       = t.bgSidebar;
    global.UI_COL_BG_MAIN          = t.bgMain;
    global.UI_COL_BG_CARD          = t.bgCard;
    global.UI_COL_TEXT_MAIN        = t.textMain;
    global.UI_COL_TEXT_DIM         = t.textDim;
    global.UI_COL_BORDER           = t.border;
    global.UI_COL_BTN_HOVER        = t.btnHover;
    global.UI_COL_DROPDOWN_LIST_BG = t.dropdownListBg;
    global.UI_COL_INSPECTOR_BG     = t.inspectorBg;
    global.UI_COL_SELECTION       = t.selection;
    global.UI_COL_SUCCESS         = t.success;
    global.UI_COL_WARNING         = t.warning;
    global.UI_COL_DANGER          = t.danger;
    global.UI_COL_SCROLLBAR_THUMB = t.scrollbarThumb;
    
    if (global.UI != undefined) {
        global.UI.requestRedraw();
    }
}
