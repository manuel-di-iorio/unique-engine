function scrSetupUI() {
    // Win size
    winW = window_get_width();
    winH = window_get_height(); 
    
    // Maximize the window
    call_later(3, time_source_units_frames, function() {
        window_command_run(window_command_maximize);
    });
    
    // Create the UI elements
    var ui = global.UI;
    ui.Menu = new UiNode({ name: "Menu", width: "100%", height: 50, flexDirection: "row", alignItems: "center", paddingLeft: 10, paddingRight: 10, marginBottom: 10  });
    ui.Assets = new UiNode({ name: "Assets", width: "20%", /*height: "30%",*/marginBottom: 62 }, { border: true });
    ui.Scene = new UiNode({ name: "Scene", height: "100%", flex: 1, marginLeft: 5, marginRight: 5 }, { border: true, pointerEvents: true });
    ui.SceneTools = new UiNode({ name: "SceneTools", width: 300, height: 40, position: "absolute" });
    ui.Inspector = new UiNode({ name: "Inspector", width: "20%", marginBottom: 62 }, { border: true });
    ui.Menu.Logo = new UiSprite(sprDemoLogo, { marginRight: 30 });
    ui.Menu.NewProjectBtn = new UiButton(sprUiNew, { padding: 5, marginRight: 15, width: 15, height: 15 }, { autoResize: false });
    ui.Menu.LoadProjectBtn = new UiButton(sprUiLoad, { padding: 5, marginRight: 15, width: 15, height: 15 }, { autoResize: false });
    ui.Menu.SaveProjectBtn = new UiButton(sprUiSave, { padding: 5, marginRight: 15, width: 15, height: 15 }, { autoResize: false });
    ui.Assets.Title = new UiText("Assets", { margin: 5, marginLeft: 10, marginRight: 10 });
    ui.Assets.Treeview = new UiTreeview({ flex: 1, height: "90%", flexDirection: "column" });
    ui.Inspector.Title = new UiText("Inspector", { margin: 5, marginLeft: 10, marginRight: 10 });
    ui.Inspector.Content = new UiNode({ name: "Inspector.Content", flex: 1, height: "100%", flexDirection: "column" });
    
    ui.Menu.NewProjectBtn.onClick(function() {
        window_set_caption("Unique Engine");
        objects.clear(); // Clear the 3D object of the current scene
        projectLocation = undefined; // Path of the .yyp file
        projectFiles = undefined; // Path of the included files
        projectEdited = false;
        
        // Clear the treeview assets
        var assets = ["Textures", "Materials", "Objects", "Scenes"];
        var Treeview = global.UI.Assets.Treeview;
        Treeview.scrollTop = 0;
        Treeview.selectedItems = [];
        for (var i = 0, l = array_length(assets); i < l; i++) {
            var asset = assets[i];
            var treeviewAsset = Treeview[$ asset];
            treeviewAsset.selected = false;
            treeviewAsset.Arrow.visible = false;
            treeviewAsset.Items.clear();
            treeviewAsset.collapseItem();
        }
    });
    
    ui.Menu.LoadProjectBtn.onClick(function() {
        //projectLocation = get_open_filename("Game Maker Project (.yyp)|*.yyp", "");
        projectLocation = "C:\\Users\\Manuel\\GameMakerProjects\\Unique Engine\\Unique Engine.yyp";
        if (projectLocation == "") return;
            
        projectFiles = projectLocation + "\\datafiles";
        projectEdited = false;
        
        var _name = filename_name(projectLocation);
        //projectName = string_copy(_name, 1, string_length(_name)-4);
        //window_set_caption($"{projectName} - Unique Engine");
        window_set_caption("New project - Unique Engine*");
    });
    
    ui.Menu.SaveProjectBtn.onClick(function() {
        show_message("@todo");
        
        projectEdited = false;
    });
    
    ui.Inspector.Content.draw = method(ui.Inspector.Content, function() {
        draw_set_color(global.UI_COL_INSPECTOR_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
    });
    
    // Add the UI elements
    ui.add(ui.Menu, ui.Assets, ui.Scene, ui.Inspector);
    ui.Menu.add(ui.Menu.Logo, ui.Menu.NewProjectBtn, ui.Menu.LoadProjectBtn, ui.Menu.SaveProjectBtn);
    ui.Assets.add(ui.Assets.Title, ui.Assets.Treeview);
    ui.Scene.add(ui.SceneTools);
    ui.Inspector.add(ui.Inspector.Title, ui.Inspector.Content);
    
    ui.Assets.Treeview.enableScrollbar();
}