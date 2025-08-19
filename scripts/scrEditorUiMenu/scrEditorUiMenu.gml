function EditorUiMenu(ui) constructor {
    self.ui = ui;
    
    ui.Menu = new UiNode({ name: "Menu", width: "100%", height: 50, flexDirection: "row", alignItems: "center", paddingLeft: 10, paddingRight: 10, marginBottom: 10  });
    ui.Menu.NewProjectBtn = new UiButton(sprUiNew, { padding: 5, marginLeft: 80, marginRight: 15, width: 15, height: 15 }, { autoResize: false });
    ui.Menu.LoadProjectBtn = new UiButton(sprUiLoad, { padding: 5, marginRight: 15, width: 15, height: 15 }, { autoResize: false });
    ui.Menu.SaveProjectBtn = new UiButton(sprUiSave, { padding: 5, marginRight: 15, width: 15, height: 15 }, { autoResize: false });
    
    ui.Menu.add(ui.Menu.NewProjectBtn, ui.Menu.LoadProjectBtn, ui.Menu.SaveProjectBtn); 
    
    ui.Menu.onDraw = method(ui.Menu, function() {
        draw_sprite(sprDemoLogo, 0, 35, ~~mean(self.y1, self.y2));
    });
    
    // Events
    ui.Menu.NewProjectBtn.onClick(function() {
        global.UI_ASSETS_TEXTURES_ID = 0;
        global.UI_ASSETS_MATERIALS_ID = 0;
        global.UI_ASSETS_MODELS_ID = 0;
        global.UI_ASSETS_LIGHTS_ID = 0;
        global.UI_ASSETS_CAMERAS_ID = 0;
        global.UI_ASSETS_SCENES_ID = 0;
        window_set_caption("Unique Engine");
        ui.destroyChildren();
        instance_destroy(oSceneEditor);
        instance_create_layer(0, 0, "Instances", oSceneEditor);
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
}