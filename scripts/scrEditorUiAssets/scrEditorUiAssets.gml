function EditorUiAssets(ui) constructor {
    self.ui = ui;
    
    ui.Assets = new UiNode({ name: "Assets", minWidth: 300, width: "20%", marginBottom: 62 }, { border: true });
    ui.Assets.Treeview = new UiTreeview({ marginTop: 35, flex: 1, height: "90%", flexDirection: "column" });
    
    ui.Assets.add(ui.Assets.Treeview);
        
    ui.Assets.onDraw = method(ui.Assets, function() {
        draw_set_color(global.UI_COL_INPUT_BG);
        draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        
        draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_font(fText);
        draw_text(self.x1 + 20, self.y1 + 8, "Assets");
    });
        
    /** Events */
    var Treeview = ui.Assets.Treeview;
    Treeview.enableScrollbar();
        
    Treeview.onNewAsset = editorTreeviewOnNewAsset;
    Treeview.onRemoveItem = editorTreeviewOnRemoveAsset;
    Treeview.onItemSelected = editorTreeviewOnItemSelected;
    Treeview.onAssetDrop = editorTreeviewOnAssetDrop; 
}
