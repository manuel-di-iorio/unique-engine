function scrSetupUI() {
    // Win size
    winW = window_get_width();
    winH = window_get_height();
    
    // Create the UI elements
    with (global.UI) {
        self.Main = new UiNode({ name: "Main", flexDirection: "row", flexWrap: "wrap", width: "100%", height: "100%", position: "absolute"  });
        self.Overlay = new UiNode({ name: "Overlay", flexDirection: "row", flexWrap: "wrap", width: "100%", height: "100%", position: "absolute" });
        self.add(self.Main, self.Overlay);
    }
    
    ui = global.UI.Main;
    ui.Scene = new UiNode({ name: "Scene", height: "100%", flex: 1, marginLeft: 5, marginRight: 5 }, { border: true, pointerEvents: true });
    ui.SceneTools = new UiNode({ name: "SceneTools", width: 300, height: 40, position: "absolute" });
    
    menu = new EditorUiMenu(ui);
    treeview = new EditorUiAssets(ui);
    inspector = new EditorUiInspector(ui);
        
    // Add the UI elements
    ui.add(ui.Menu, ui.Assets, ui.Scene, ui.Inspector);
    ui.Scene.add(ui.SceneTools);
}