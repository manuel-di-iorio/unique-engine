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
    ui.Menu.SaveProjectBtn = new UiButton(sprUiSave, { display: "none", padding: 10, marginLeft: 80, marginRight: 15, width: 15, height: 15 }, { tooltip: "Save project (Ctrl+S)" });    
    
    ui.Menu.SaveProjectBtn.onClick(function() {
        with (oSceneEditor) {
            if (projectManager != undefined) {
                projectManager.save();
            }
        }
    });
    ui.Menu.add(ui.Menu.SaveProjectBtn);

    // Load Project Button
    ui.Menu.LoadProjectBtn = new UiButton(sprUiLoad, { marginLeft: 80, padding: 10, marginRight: 15, width: 15, height: 15 }, { enableRipple: false, tooltip: "Load project" });    
    ui.Menu.add(ui.Menu.LoadProjectBtn);
    
    ui.Menu.LoadProjectBtn.onClick(function() {
        with (oSceneEditor) {
            var selectedFile = get_open_filename("Game Maker Project (.yyp)|*.yyp", "");
            if (selectedFile == "") return;

            scrEditorLoadProject(selectedFile);
        }
    });
}
