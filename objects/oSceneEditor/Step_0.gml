if (!enableUI) exit;

var ui = global.UI;
var uiMain = global.UI.Main;
var uiOverlay = global.UI.Overlay;

// Correctly resize the application surface to match the new window size
var winWNew = window_get_width();
var winHNew = window_get_height();
if ((winW != winWNew || winH != winHNew) && winWNew != 0 && winHNew != 0) {
    scrUiResizeViewports();
}

ui.update();

// Exit early if project not loaded
if (!projectManager.loaded) exit;

var uiScene = global.UI.Main.Scene;

var winMouseX = window_mouse_get_x();
var winMouseY = window_mouse_get_y();
var uiHasFocus = global.UI.hasAnyFocus();
var flythroughActive = sceneManager.orbit.flythroughActive;

// Update transform controls based on current tool
var currentTool = editorManager.activeTool;
switch (currentTool) {
    case "view": 
        sceneManager.transformControls.updateGizmo();
        sceneManager.orbit.update(winMouseX, winMouseY);
    break;
    case "move":
    case "rotate":
    case "scale":
        sceneManager.transformControls.update();

        if (!sceneManager.transformControls.dragging) {
            sceneManager.orbit.update(winMouseX, winMouseY);
        }
    break;
}

// Mesh picking
sceneManager.handleMeshPicking();

// editorManager.handleMouseWrap(winMouseX, winMouseY, winW, winH);

if (!uiHasFocus && !flythroughActive) {
   // Save project
   if (keyboard_check(vk_control) && keyboard_check_pressed(ord("S"))) {
       if (projectManager.hasUnsavedChanges) {
           projectManager.save();
       }
   }
   
   // Tool shortcuts
   if (keyboard_check_pressed(ord("Q"))) {
       editorManager.setTool("view");
       tool = "view";
       editorManager.sceneTools.updateToolButtons();
   }
   if (keyboard_check_pressed(ord("W"))) {
       editorManager.setTool("move");
       tool = "move";
       editorManager.sceneTools.updateToolButtons();
   }
    if (keyboard_check_pressed(ord("E"))) {
       editorManager.setTool("rotate");
       tool = "rotate";
       editorManager.sceneTools.updateToolButtons();
    }
    if (keyboard_check_pressed(ord("R"))) {
      editorManager.setTool("scale");
      tool = "scale";
      editorManager.sceneTools.updateToolButtons();
    }
    
    // Focus shortcut
    if (keyboard_check_pressed(ord("F"))) {
       var target = editorManager.gizmoTarget;
       if (target != undefined && (target[$ "isObject3D"] || target[$ "isMesh"])) {
           sceneManager.orbit.focus(target);
       }
    }
}

// Handle window close confirmation
if (window_command_check(window_command_close)) {
    if (projectManager.hasUnsavedChanges) {
        if (show_question("There are unsaved changes. Do you really want to exit?")) {
            game_end();
        }
    } else {
        game_end();
    }
}
