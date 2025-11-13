/// @description Initialize Project Manager UI

// UI Theme colors (same as oSceneEditor)
global.UI_COL_BTN_HOVER        = #393B47;
global.UI_COL_BOX              = #191A21;
global.UI_COL_TREE_BG          = #2D3039;
global.UI_COL_SELECTED         = #5A657E;
global.UI_COL_INSPECTOR_BG     = #282A36;
global.UI_COL_INPUT_BG         = #21222C;
global.UI_COL_SELECTION        = #464a53;
global.UI_COL_CHECKBOX_HOVER   = #8993a0;
global.UI_COL_DROPDOWN_LIST_BG = #181818;
global.UI_COL_BORDER           = #1a1a1a;

// Window dimensions
winW = window_get_width();
winH = window_get_height();

// Initialize UniqueUI
global.UI.setSize(winW, winH);

// Main container
ui = new UiNode({
    name: "Main",
    width: "100%",
    height: "100%",
    flexDirection: "column"
});

ui.onDraw = method(ui, function() {
    draw_set_color(global.UI_COL_BOX);
    draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
});

global.UI.add(ui);

// Header with logo and version
ui.Header = new UiNode({
    name: "Header",
    width: "100%",
    height: 60,
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "space-between",
    paddingLeft: 20,
    paddingRight: 20
});

ui.Header.onDraw = method(ui.Header, function() {
    draw_set_color(global.UI_COL_INPUT_BG);
    draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
});

ui.add(ui.Header);

// Logo (left side)
ui.Header.Logo = new UiSprite(sprDemoLogo, {
    width: sprite_get_width(sprDemoLogo),
    height: sprite_get_height(sprDemoLogo)
});
ui.Header.add(ui.Header.Logo);

// Version text (right side)
ui.Header.Version = new UiText("v" + string(global.UE_VERSION), {}, {
    color: c_gray,
    halign: fa_right
});
ui.Header.add(ui.Header.Version);

// Center container for the button
ui.Center = new UiNode({
    name: "Center",
    width: "100%",
    height: "100%",
    flexDirection: "column",
    alignItems: "center",
    justifyContent: "center"
});
ui.add(ui.Center);

// Load Project Button
ui.Center.LoadButton = new UiButton(undefined, {
    width: 300,
    height: 60,
    padding: 10
});

ui.Center.LoadButton.Text = new UiText("Load Game Maker Project", {}, {
    color: c_white
});
ui.Center.LoadButton.add(ui.Center.LoadButton.Text);

ui.Center.add(ui.Center.LoadButton);

// Button click handler
ui.Center.LoadButton.onClick(function() {
    var selectedFile = get_open_filename("Game Maker Project (.yyp)|*.yyp", "");
    if (selectedFile == "") return;
    
    // Store project path
    global.ProjectPath = selectedFile;
    global.ProjectLocation = filename_path(selectedFile);
    global.ProjectFiles = global.ProjectLocation + "datafiles";
    
    var projectName = filename_name(selectedFile);
    projectName = string_copy(projectName, 1, string_length(projectName) - 4);
    
    window_set_caption(projectName + " - Unique Engine");
    
    // Destroy this manager and create the main editor
    instance_destroy();
    instance_create_layer(0, 0, "Instances", oSceneEditor);
});

// Initial update
global.UI.update();
