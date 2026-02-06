function scrEditorLoadProject(projectPath) {
    if (!file_exists(projectPath)) return;

    var ui = global.UI.Main;
    var pm = oSceneEditor.projectManager;
    var em = oSceneEditor.editorManager;

    // Clear editor UI components if they exist (Welcome screen)
    if (ui[$ "Center"] != undefined) {
        ui.Center.destroy();
        ui.Center = undefined;
        delete ui.Center;

        if (ui.Menu[$ "SaveProjectBtn"] != undefined) ui.Menu.SaveProjectBtn.show();
        if (ui.Menu[$ "LoadProjectBtn"] != undefined) ui.Menu.LoadProjectBtn.setMarginLeft(0);
    } else {
        // If we are already in a project, clear it
        pm.clearProject();
    }

    // Store project paths in ProjectManager
    pm.setProjectPath(projectPath);

    // Recreate the UI elements
    ui.Scene = new UiNode({ name: "Scene", height: "100%", flex: 1, marginLeft: 5, marginRight: 5 }, { border: true, pointerEvents: true, dropzone: true });
    
    // Handle drop on scene (instance model)
    ui.Scene.onDrop = function(draggedNode) {
        var draggedItem = draggedNode.parent;
        if (draggedItem != undefined && draggedItem[$ "assetType"] != undefined) {
            // Only allow dropping assets that are already in a scene (instances)
            if (!__editorTreeview_isAssetInScene(draggedItem.asset)) {
                 return false;
            }

            if (draggedItem.assetType == "Mesh" || draggedItem.assetType == "Object3D") {
                var activeSceneItem = oSceneEditor.editorManager.activeSceneTreeviewItem;
                if (activeSceneItem != undefined) {
                    return editorTreeviewOnAssetDrop(draggedItem, activeSceneItem);
                }
            }
        }
        return false;
    };

    em.treeview = new EditorUiAssets(ui);
    em.inspector = new EditorUiInspector(ui);
    em.sceneTools = new EditorUiSceneTools(global.UI.Overlay);

    ui.add(ui.Assets, ui.Scene, ui.Inspector);

    pm.loaded = true;
    pm.load();

    scrUiResizeViewports();

    // Save to settings.json
    var settings = {
        lastProject: projectPath
    };
    var jsonStr = json_stringify(settings);
    var buf = buffer_create(string_byte_length(jsonStr), buffer_fixed, 1);
    buffer_write(buf, buffer_text, jsonStr);
    buffer_save(buf, "settings.json");
    buffer_delete(buf);
}
