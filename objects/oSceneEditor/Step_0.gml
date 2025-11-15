var ui = global.UI;

// Correctly resize the application surface to match the new window size
var winWNew = window_get_width();
var winHNew = window_get_height();
if ((winW != winWNew || winH != winHNew) && winWNew != 0 && winHNew != 0) {
    scrUiResizeViewports();
}

ui.update();

// Exit early if project not loaded
if (!projectLoaded) exit;

var winMouseX = window_mouse_get_x();
var winMouseY = window_mouse_get_y();

// Update transform controls based on current tool
var currentTool = global.EditorState.activeTool;
switch (currentTool) {
    case "view": 
        transformControls.updateGizmo();
        orbit.update(winMouseX, winMouseY);
    break;
    case "move":
    case "rotate":
    case "scale":
        transformControls.update();
    break;
}

// Wrap the mouse coords when out of bounds
if (mouse_button != mb_none && orbit.transforming) {
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
        
        orbit._prevMouseX = winMouseX;
        orbit._prevMouseY = winMouseY;
    }
}

// Only handle shortcuts when no UI element has focus
var uiHasFocus = global[$ "UiFocusManager"] != undefined && global.UiFocusManager.hasAnyFocus();

if (!uiHasFocus) {
    if (keyboard_check_pressed(ord("Q"))) {
        global.EditorState.setTool("view");
        tool = "view";
    }
    if (keyboard_check_pressed(ord("W"))) {
        global.EditorState.setTool("move");
        tool = "move";
    }
    if (keyboard_check_pressed(ord("E"))) {
        global.EditorState.setTool("rotate");
        tool = "rotate";
    }
    if (keyboard_check_pressed(ord("R"))) {
        global.EditorState.setTool("scale");
        tool = "scale";
    }
}
