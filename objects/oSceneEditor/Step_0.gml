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
    case EDITOR_TOOL.View: 
        sceneManager.transformControls.updateGizmo();
        sceneManager.orbit.update(winMouseX, winMouseY);
    break;
    case EDITOR_TOOL.Move:
    case EDITOR_TOOL.Rotate:
    case EDITOR_TOOL.Scale:
        sceneManager.transformControls.update();

        if (!sceneManager.transformControls.dragging) {
            sceneManager.orbit.update(winMouseX, winMouseY);
        }
    break;
}

// Mesh picking
var _pickHit = sceneManager.handleMeshPicking();

// Rectangle selection (marquee select)
var _guiMouseX = device_mouse_x_to_gui(0);
var _guiMouseY = device_mouse_y_to_gui(0);

if (uiScene.hovered && !sceneManager.orbit.transforming && !flythroughActive) {
    // Start rect select: left click in scene with no gizmo interaction and no pick hit
    if (mouse_check_button_pressed(mb_left) && !sceneManager.transformControls.dragging 
        && sceneManager.transformControls.hoveredAxis == undefined && !_pickHit) {
        sceneManager.__rectSelectPending = true;
        sceneManager.__rectSelectPendingX = _guiMouseX;
        sceneManager.__rectSelectPendingY = _guiMouseY;
    }
    
    // Begin actual rect select after a small drag threshold
    if (sceneManager.__rectSelectPending && mouse_check_button(mb_left) && !sceneManager.rectSelectActive) {
        if (point_distance(_guiMouseX, _guiMouseY, sceneManager.__rectSelectPendingX, sceneManager.__rectSelectPendingY) > 5) {
            sceneManager.rectSelectBegin(sceneManager.__rectSelectPendingX, sceneManager.__rectSelectPendingY);
            sceneManager.__rectSelectPending = false;
        }
    }
    
    // Update rect select during drag
    if (sceneManager.rectSelectActive) {
        sceneManager.rectSelectUpdate(_guiMouseX, _guiMouseY);
    }
}

// Cancel pending on mouse release
if (!mouse_check_button(mb_left)) {
    sceneManager.__rectSelectPending = false;
    
    // End rect select
    if (sceneManager.rectSelectActive) {
        sceneManager.rectSelectEnd();
    }
}

// Update multi-selection box helpers
if (global.editor.selectionManager != undefined) {
    global.editor.selectionManager.updateBoxHelpers();
}

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
       editorManager.setTool(EDITOR_TOOL.View);
       editorManager.sceneTools.updateToolButtons();
   }
   if (keyboard_check_pressed(ord("W"))) {
       editorManager.setTool(EDITOR_TOOL.Move);
       editorManager.sceneTools.updateToolButtons();
   }
    if (keyboard_check_pressed(ord("E"))) {
       editorManager.setTool(EDITOR_TOOL.Rotate);
       editorManager.sceneTools.updateToolButtons();
    }
    if (keyboard_check_pressed(ord("R"))) {
      editorManager.setTool(EDITOR_TOOL.Scale);
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
