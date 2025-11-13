/// @description Update UI and handle window resize

var ui = global.UI;

// Handle window resize
var winWNew = window_get_width();
var winHNew = window_get_height();
if ((winW != winWNew || winH != winHNew) && winWNew != 0 && winHNew != 0) {
    winW = winWNew;
    winH = winHNew;
    surface_resize(application_surface, winW, winH);
    ui.setSize(winW, winH).update();
}

// Update UI
ui.update();
