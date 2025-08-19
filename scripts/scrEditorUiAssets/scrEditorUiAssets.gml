function EditorUiAssets(ui) constructor {
    self.ui = ui;
    
    ui.Assets = new UiNode({ name: "Assets", minWidth: 300, width: "20%", /*height: "30%",*/marginBottom: 62 }, { border: true });
    ui.Assets.Treeview = new UiTreeview({ marginTop: 35, flex: 1, height: "90%", flexDirection: "column" });
    
    ui.Assets.add(ui.Assets.Treeview);
        
    ui.Assets.onDraw = method(ui.Assets, function() {
        draw_set_color(c_white); draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_text(self.x1 + 20, self.y1 + 8, "Assets");
    });
        
    /** Events */
    var Treeview = ui.Assets.Treeview;
    Treeview.enableScrollbar();
        
    // Create new asset
    Treeview.onNewAsset = function(treeviewItem) {
        var assetType = treeviewItem.assetType;
        var asset;
        var assetId;
        switch (assetType) {
            case "texture": 
                asset = new UeTexture();
                assetId = global.UI_ASSETS_TEXTURES_ID++;
            break;
            
            case "material": 
                asset = new UeMaterial(); 
                assetId = global.UI_ASSETS_MATERIALS_ID++;
            break;
            
            case "model": 
                asset = new UeMesh(); 
                assetId = global.UI_ASSETS_MODELS_ID++;
            break;
            
            case "light":    
                asset = new UeLight(); 
                assetId = global.UI_ASSETS_LIGHTS_ID++;
            break;
            
            case "camera":
                asset = new UeObject3D();
                asset.isCamera = true;
                asset.type = "camera";
                assetId = global.UI_ASSETS_CAMERAS_ID++;
            break;
            
            case "scene":   
                asset = new UeScene();
                assetId = global.UI_ASSETS_SCENES_ID++;
            break;
        }
        
        var name = string_upper(string_char_at(assetType, 1)) + string_copy(assetType, 2, string_length(assetType) - 1) + string(assetId);
        treeviewItem.asset = asset; 
        asset.name = name;
    };
        
    Treeview.onItemSelected = function(treeviewItem) {
        oSceneEditor.inspector.inspect(treeviewItem.asset); 
    };
}