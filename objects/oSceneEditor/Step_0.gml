var ui = global.UI;

// Correctly resize the application surface to match the new window size
var winWNew = window_get_width();
var winHNew = window_get_height();
if ((winW != winWNew || winH != winHNew) && winWNew != 0 && winHNew != 0) {
    scrUiResizeViewports();
}

ui.update();

// Exit early if project not loaded
if (!projectManager.loaded) exit;

var winMouseX = window_mouse_get_x();
var winMouseY = window_mouse_get_y();

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
    break;
}

// Wrap the mouse coords when out of bounds
if (mouse_button != mb_none && sceneManager.orbit.transforming) {
    var fixMousePos = false;

    if (winMouseX < 1) {
        winMouseX = winW - 2;
        fixMousePos = true;
    } else if (winMouseY < 1) {
        winMouseY = winH - 2;
        fixMousePos = true;
    } else if (winMouseX > winW - 2) {
        winMouseX = 2;
        fixMousePos = true;
    } else if (winMouseY > winH - 1) {
        winMouseY = 2;
        fixMousePos = true;
    }

    if (fixMousePos) {
        window_mouse_set(winMouseX, winMouseY); 
        
        sceneManager.orbit._prevMouseX = winMouseX;
        sceneManager.orbit._prevMouseY = winMouseY;
    }
}

// Only handle shortcuts when no UI element has focus
var uiHasFocus = global.UI.focusManager.hasAnyFocus();

if (!uiHasFocus) {
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
    }
    if (keyboard_check_pressed(ord("W"))) {
        editorManager.setTool("move");
        tool = "move";
    }
    if (keyboard_check_pressed(ord("E"))) {
        editorManager.setTool("rotate");
        tool = "rotate";
    }
    if (keyboard_check_pressed(ord("R"))) {
        editorManager.setTool("scale");
        tool = "scale";
    }
}
