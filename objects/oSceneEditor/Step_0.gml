var ui = global.UI;

// Correctly resize the application surface to match the new window size
var winWNew = window_get_width();
var winHNew = window_get_height();
if ((winW != winWNew || winH != winHNew) && winWNew != 0 && winHNew != 0) {
    winW = winWNew;
    winH = winHNew;
    surface_resize(application_surface, winW, winH);
    ui.setSize(winW, winH).update();
    
    // Resize the views
    view_set_wport(0, winW);
    view_set_hport(0, winH);
    
    var uiScenePos = ui.Main.Scene.layout;
    view_set_xport(1, uiScenePos.left);
    view_set_yport(1, uiScenePos.top);
    view_set_wport(1, uiScenePos.width);
    view_set_hport(1, uiScenePos.height - uiScenePos.top - 1);
    
    camera.aspect = view_wport[1] / view_hport[1];
}

ui.update();

// Wrap the mouse coords when out of bounds
var winMouseX = window_mouse_get_x();
var winMouseY = window_mouse_get_y();

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

orbit.update(winMouseX, winMouseY);
