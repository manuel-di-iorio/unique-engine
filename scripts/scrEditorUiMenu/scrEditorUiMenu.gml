function EditorUiMenu(ui) constructor {
    self.ui = ui;
    
    ui.Menu = new UiNode({ name: "Menu", width: "100%",  flexDirection: "row", alignItems: "center", 
    paddingHorizontal: 10, paddingVertical: 20, marginBottom: 0  });

    ui.Menu.onDraw = method(ui.Menu, function() {
        draw_set_color(global.UI_COL_INPUT_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        
        draw_sprite_ext(sprLogoIcon, 0, 35, round((self.y1 + self.y2) / 2), .12, .12, 0, c_white, 1);
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
    
    // Undo Button
    ui.Menu.UndoBtn = new UiButton(sprUiUndo, { padding: 10, marginLeft: 30, width: 15, height: 15 }, { tooltip: "Undo (Ctrl+Z)" });
    ui.Menu.UndoBtn.onStep(method(ui.Menu.UndoBtn, function() {
        self.setEnabled(global.editor.undoManager.canUndo());
    }));
    ui.Menu.UndoBtn.onClick(function() {
        global.editor.undoManager.undo();
    });
    ui.Menu.add(ui.Menu.UndoBtn);
    
    // Redo Button
    ui.Menu.RedoBtn = new UiButton(sprUiRedo, { padding: 10, marginLeft: 5, width: 15, height: 15 }, { tooltip: "Redo (Ctrl+Y)" });
    ui.Menu.RedoBtn.onStep(method(ui.Menu.RedoBtn, function() {
        self.setEnabled(global.editor.undoManager.canRedo());
    }));
    ui.Menu.RedoBtn.onClick(function() {
        global.editor.undoManager.redo();
    });
    ui.Menu.add(ui.Menu.RedoBtn);
}
