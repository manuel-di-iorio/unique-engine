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
    
    var uiScenePos = ui.Scene.getPosition(false);
    view_set_xport(1, uiScenePos.left);
    view_set_yport(1, uiScenePos.top);
    view_set_wport(1, uiScenePos.width);
    view_set_hport(1, uiScenePos.height - uiScenePos.top - 1);
    
    camera.aspect = view_wport[1] / view_hport[1];
}

ui.update();
orbit.update();