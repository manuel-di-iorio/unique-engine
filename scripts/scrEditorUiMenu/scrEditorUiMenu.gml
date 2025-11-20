function EditorUiMenu(ui) constructor {
    self.ui = ui;
    
    ui.Menu = new UiNode({ name: "Menu", width: "100%",  flexDirection: "row", alignItems: "center", 
    paddingHorizontal: 10, paddingVertical: 20, marginBottom: 0  });

    ui.Menu.onDraw = method(ui.Menu, function() {
        draw_set_color(global.UI_COL_INPUT_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        
        draw_sprite(sprDemoLogo, 0, 35, (self.y1 + self.y2) / 2);
    });

    // Save Project Button
    ui.Menu.SaveProjectBtn = new UiButton(sprUiSave, { display: "none", padding: 5, marginLeft: 80, marginRight: 20, width: 15, height: 15 });    
    
    ui.Menu.SaveProjectBtn.onClick(function() {
        with (oSceneEditor) {
            if (projectManager != undefined) {
                projectManager.save();
            }
        }
    });
    ui.Menu.add(ui.Menu.SaveProjectBtn);

    // Load Project Button
    ui.Menu.LoadProjectBtn = new UiButton(sprUiLoad, { marginLeft: 80, padding: 5, marginRight: 20, width: 15, height: 15 }, { enableRipple: false });    
    ui.Menu.add(ui.Menu.LoadProjectBtn);
    
    ui.Menu.LoadProjectBtn.onClick(function() {
        with (oSceneEditor) {
            var selectedFile = get_open_filename("Game Maker Project (.yyp)|*.yyp", "");
            if (selectedFile == "") return;

            var ui = global.UI.Main;

            // Clear editor UI components if they exist
            if (ui[$ "Center"] != undefined) {
                ui.Center.destroy();
                ui.Center = undefined;
                delete ui.Center;

                ui.Menu.SaveProjectBtn.show();
                ui.Menu.LoadProjectBtn.setMarginLeft(0);
            
            } else {
                projectManager.clearProject();
            }
            
            // Store project paths in ProjectManager
            projectManager.setProjectPath(selectedFile);            
            
            // Recreate the UI elements
            ui.Scene = new UiNode({ name: "Scene", height: "100%", flex: 1, marginLeft: 5, marginRight: 5 }, { border: true, pointerEvents: true });
            
            editorManager.treeview = new EditorUiAssets(ui);
            editorManager.inspector = new EditorUiInspector(ui);
            editorManager.sceneTools = new EditorUiSceneTools(global.UI.Overlay);

            ui.add(ui.Assets, ui.Scene, ui.Inspector);
            
            projectManager.loaded = true;
            
            // Load project assets
            projectManager.load();

            scrUiResizeViewports();
        }
    });
}
