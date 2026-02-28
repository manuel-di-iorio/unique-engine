function editorTreeviewOnItemSelected(treeviewItem, focus = false) {
  var editorManager = global.editor.editorManager;

  if (treeviewItem == undefined || treeviewItem.asset == undefined) {
    editorManager.clearActiveAsset(true);
    return;
  }

  switch (treeviewItem.asset.type) {
    case "Mesh":
    case "Bone":
    case "Object3D":
      var currentAsset = treeviewItem.asset;

      // Check if the asset is part of a scene
      var isInScene = false;
      var curr = currentAsset;
      while (curr != undefined) {
        if (curr[$ "type"] == "Scene") {
          isInScene = true;
          break;
        }
        curr = curr.parent;
      }

      if (isInScene) {
        // Asset is inside a scene, allow selection and gizmo
        var rootAsset = currentAsset;
        var currSearch = currentAsset;

        while (currSearch.parent != undefined) {
          var parentType = currSearch.parent[$ "type"];

          if (parentType == "Scene") {
            rootAsset = currSearch.parent;
            break;
          }

          if (parentType == "Folder") {
            rootAsset = currSearch;
            break;
          }

          currSearch = currSearch.parent;
          if (currSearch.parent == undefined) {
            rootAsset = currSearch;
          }
        }

        editorManager.setActiveAsset(rootAsset, treeviewItem, treeviewItem.asset);
      } else {
        // Library asset (prefab/model): don't show in main view, just inspect.
        // Now we have the preview in the inspector, so we don't need to render it in the scene.
        editorManager.clearActiveAsset(true, false);
        editorManager.selectedTreeviewItem = treeviewItem;
      }
      break;

    case "Scene":
      editorManager.setActiveAsset(treeviewItem.asset, treeviewItem);
      break;

    default:
      // For other types (Texture, Material, Folder, etc.), clear the active 3D asset 
      // but keep the current scene loaded and MAINTAIN the treeview selection.
      editorManager.clearActiveAsset(true, false);
      editorManager.selectedTreeviewItem = treeviewItem;
      break;
  }

  // Inspect the asset
  if (editorManager.inspector != undefined) {
    editorManager.inspector.inspect(treeviewItem.asset, focus);
  }

  // Focus camera on the object if requested (only if it's in a scene)
  if (focus && (treeviewItem.asset[$ "isObject3D"] || treeviewItem.asset[$ "isMesh"])) {
    // Use the EditorManager's knowledge of the active scene to determine if we can focus
    if (editorManager.activeScene != undefined) {
      global.editor.sceneManager.orbit.focus(treeviewItem.asset);
    }
  }
};
