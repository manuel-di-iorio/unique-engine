function scrSetupUI() {
    // Colors
    uiColBg = #21222C;
    uiColBox = #191A21;
    uiColTreeBg = #2D3039;
    uiColSelected = #5A657E;
    
    // Win size
    winW = window_get_width();
    winH = window_get_height(); 
    
    // Maximize the window
    call_later(3, time_source_units_frames, function() {
        window_command_run(window_command_maximize);
    });
    
    // Create the UI elements
    var ui = global.UI;
    ui.Menu = new UiNode({ name: "Menu", width: "100%", height: 50, flexDirection: "row", alignItems: "center", paddingLeft: 10, paddingRight: 10, marginBottom: 10  }, { hoverable: false });
    ui.Hierarchy = new UiNode({ name: "Hierarchy", width: "20%", paddingTop: 5, paddingBottom: 5 }, { border: true, hoverable: false });
    ui.Scene = new UiNode({ name: "Scene", height: "100%", flex: 1, margin: 1, marginLeft: 5, marginRight: 5 }, { border: true });
    ui.SceneTools = new UiNode({ name: "SceneTools", width: 300, height: 40, position: "absolute" }, { hoverable: false });
    ui.Inspector = new UiNode({ name: "Inspector", width: "20%", paddingTop: 5, paddingBottom: 5, margin: 1 }, { border: true, hoverable: false });
    ui.Menu.Logo = new UiSprite(sprDemoLogo, { marginRight: 30 });
    ui.Menu.NewProjectBtn = new UiButton(sprUiNew, { padding: 5, marginRight: 15, width: 15, height: 15 }, { autoResize: false });
    ui.Menu.LoadProjectBtn = new UiButton(sprUiLoad, { padding: 5, marginRight: 15, width: 15, height: 15 }, { autoResize: false });
    ui.Menu.SaveProjectBtn = new UiButton(sprUiSave, { padding: 5, marginRight: 15, width: 15, height: 15 }, { autoResize: false });
    ui.Hierarchy.Title = new UiText("Hierarchy", { margin: 5, marginLeft: 10, marginRight: 10 });
    ui.Hierarchy.Treeview = new UiTreeview({ flex: 1, height: "100%", flexDirection: "column", margin: 10 }, { hoverable: false });
    ui.Inspector.Title = new UiText("Inspector", { margin: 5, marginLeft: 10, marginRight: 10 });
    
    ui.Menu.NewProjectBtn.onClick = function() {
        objects.clear();
        projectLocation = undefined;
        projectFiles = undefined;
        projectEdited = false;
    };
    
    ui.Menu.LoadProjectBtn.onClick = function() {
        //projectLocation = get_open_filename("Game Maker Project (.yyp)|*.yyp", "");
        projectLocation = "C:\\Users\\Manuel\\GameMakerProjects\\Unique Engine\\Unique Engine.yyp";
        if (projectLocation == "") return;
            
        projectFiles = projectLocation + "\\datafiles";
        projectEdited = false;
        
        var _name = filename_name(projectLocation);
        //projectName = string_copy(_name, 1, string_length(_name)-4);
        //window_set_caption($"{projectName} - Unique Engine");
        window_set_caption("New project - Unique Engine");
    };
    
    ui.Menu.SaveProjectBtn.onClick = function() {
        show_message("@todo");
        
        projectEdited = false;
    };
    
    // Add the UI elements
    ui.add(ui.Menu, ui.Hierarchy, ui.Scene, ui.Inspector);
    ui.Menu.add(ui.Menu.Logo, ui.Menu.NewProjectBtn, ui.Menu.LoadProjectBtn, ui.Menu.SaveProjectBtn);
    ui.Hierarchy.add(ui.Hierarchy.Title, ui.Hierarchy.Treeview);
    ui.Scene.add(ui.SceneTools);
    ui.Inspector.add(ui.Inspector.Title);
    
    ui.update();
}