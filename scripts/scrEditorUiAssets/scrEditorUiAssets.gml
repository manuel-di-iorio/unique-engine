function EditorUiAssets(ui) constructor {
    self.ui = ui;
    
    ui.Assets = new UiNode({ name: "Assets", minWidth: 300, width: "20%", /*height: "30%",*/marginBottom: 62 }, { border: true });
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
        
    // Create new asset
    Treeview.onNewAsset = function(treeviewItem) {
        var assetType = treeviewItem.assetType;
        var asset;
        var assetId;
        switch (assetType) {
            case "texture": 
                asset = new UeTexture();
                assetId = global.UI_ASSETS_TEXTURES_ID++;
                array_push(oSceneEditor.projectTextures, asset);
            break;
            
            case "material": 
                asset = new UeMaterial(); 
                assetId = global.UI_ASSETS_MATERIALS_ID++;
                array_push(oSceneEditor.projectMaterials, asset);
            break;
            
            case "model": 
                asset = new UeMesh(); 
                asset.__rotationEuler = new UeEuler();
                assetId = global.UI_ASSETS_MODELS_ID++;
                array_push(oSceneEditor.projectModels, asset);
            break;
            
            case "light":
                asset = new UeLight(); 
                asset.__rotationEuler = new UeEuler();
                assetId = global.UI_ASSETS_LIGHTS_ID++;
                array_push(oSceneEditor.projectLights, asset);
            break;
            
            case "camera":
                asset = new UeObject3D();
                asset.isCamera = true;
                asset.type = "camera";
                asset.__rotationEuler = new UeEuler();
                assetId = global.UI_ASSETS_CAMERAS_ID++;
                array_push(oSceneEditor.projectCameras, asset);
            break;
            
            case "scene":   
                asset = new UeScene();
                assetId = global.UI_ASSETS_SCENES_ID++;
                array_push(oSceneEditor.projectScenes, asset);
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