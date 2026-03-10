function editorTreeviewOnItemSelected(treeviewItem, focus = false) {
  var editorManager = global.editor.editorManager;
  var selMgr = global.editor.selectionManager;

  if (treeviewItem == undefined || treeviewItem.asset == undefined) {
    selMgr.clear();
    editorManager.clearActiveAsset(true);
    return;
  }

  // Single select: clear SelectionManager and set the one item
  selMgr.select(treeviewItem.asset, treeviewItem);

  var _type = treeviewItem.asset[$ "type"] ?? treeviewItem.asset[$ "assetType"];
  switch (_type) {
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

  // Focus camera on the object if requested (only if it's in a scene and not a Scene itself)
  if (focus && (treeviewItem.asset[$ "isObject3D"] || treeviewItem.asset[$ "isMesh"]) && !treeviewItem.asset[$ "isScene"]) {
    if (editorManager.activeScene != undefined) {
      global.editor.sceneManager.orbit.focus(treeviewItem.asset);
    }
  }
};

/// Handle multi-selection actions (Ctrl+click toggle, Shift+click range) from UiTreeview
/// @param {Struct} treeviewItem The item that was clicked
/// @param {String} mode "toggle" for Ctrl+click, "range" for Shift+click
function editorTreeviewOnMultiItemSelected(treeviewItem, mode) {
  var editorManager = global.editor.editorManager;
  var selMgr = global.editor.selectionManager;

  if (treeviewItem == undefined || treeviewItem.asset == undefined) return;
  
  var treeview = treeviewItem.treeview;

  if (mode == "toggle") {
    selMgr.toggle(treeviewItem.asset, treeviewItem);
  } else if (mode == "range") {
    selMgr.selectRange(treeview.lastClickedItem, treeviewItem, treeview);
  }
  
  // Update primary in EditorManager to match SelectionManager's primary
  var primary = selMgr.primaryAsset;
  var primaryTvItem = selMgr.primaryTreeviewItem;
  
  if (primary != undefined && primaryTvItem != undefined) {
    treeview.selectedItem = primaryTvItem;
    
    // Only set active asset if primary is a scene object
    switch (primary.type) {
      case "Mesh":
      case "Bone":
      case "Object3D":
        var isInScene = false;
        var curr = primary;
        while (curr != undefined) {
          if (curr[$ "type"] == "Scene") { isInScene = true; break; }
          curr = curr.parent;
        }
        
        if (isInScene) {
          var rootAsset = primary;
          var currSearch = primary;
          while (currSearch.parent != undefined) {
            var parentType = currSearch.parent[$ "type"];
            if (parentType == "Scene") { rootAsset = currSearch.parent; break; }
            if (parentType == "Folder") { rootAsset = currSearch; break; }
            currSearch = currSearch.parent;
            if (currSearch.parent == undefined) rootAsset = currSearch;
          }
          editorManager.setActiveAsset(rootAsset, primaryTvItem, primary);
        }
        break;
        
      case "Scene":
        editorManager.setActiveAsset(primary, primaryTvItem);
        break;
    }
    
    // Update inspector based on selection count
    if (editorManager.inspector != undefined) {
      if (selMgr.count() > 1) {
        editorManager.inspector.inspectMultiple(selMgr.selectedAssets, selMgr.primaryAsset);
      } else {
        editorManager.inspector.inspect(primary, false);
      }
    }
  } else {
    // Selection cleared
    selMgr.clear();
    editorManager.clearActiveAsset(true);
  }
  
  global.UI.requestRedraw();
};
