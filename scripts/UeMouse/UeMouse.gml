/**
 * Mouse utils
 */
function UeMouse() constructor {
    gml_pragma("forceinline");
    self.view = 0;
    
    function get() {
        gml_pragma("forceinline");
     
        var mouseX = device_mouse_x_to_gui(0) - view_xport[self.view];
        var mouseY = device_mouse_y_to_gui(0) - view_yport[self.view];
        
        return {
            x: mouseX,
            y: mouseY,
            ndcX: (mouseX / view_wport[self.view]) * 2 - 1,
            ndcY: ((mouseY / view_hport[self.view]) * 2 - 1)
        };
    }
}
