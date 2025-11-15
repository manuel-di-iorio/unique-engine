function scrSetupUI() {
    scrUiResizeViewports();
    
    // Create the UI elements
    with (global.UI) {
        self.Main = new UiNode({ name: "Main", flexDirection: "row", flexWrap: "wrap", width: "100%", height: "100%", position: "absolute"  });

        self.Overlay = new UiNode({ name: "Overlay", flexDirection: "row", flexWrap: "wrap", width: "100%", height: "100%", position: "absolute" });
        
        self.add(self.Main, self.Overlay);
    }
    
    ui = global.UI.Main;
    
    // Create the editor UI elements
    menu = new EditorUiMenu(ui);   
    
    // Center container for load button
    ui.Center = new UiNode({
        name: "Center",
        width: "100%",
        height: "100%",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center"
    });

    with (ui.Center) {
        function onDraw() {
            draw_set_color(global.UI_COL_BOX);
            draw_rectangle(self.x1, self.y1, self.x2, self.y2, false);
        }
    }
    
    // Load Project Button
    ui.Center.WelcomeText = new UiText("Select the Load Game Maker Project icon on the menu bar to start");
    ui.Center.add(ui.Center.WelcomeText);

    ui.add(ui.Menu, ui.Center);
}


/// @function resizeViewports
/// @description Resize viewport and camera aspect when window or UI changes.
///              Handles both "fit" (letterbox/pillarbox) and "cover" (fill with crop) modes
///              while maintaining 16:9 aspect ratio for the game view.
function scrUiResizeViewports() {
    var ui = global.UI;

    winW = window_get_width();
    winH = window_get_height();

    surface_resize(application_surface, winW, winH);
    ui.setSize(winW, winH).update();
    
    // Resize the views
    view_set_wport(0, winW);
    view_set_hport(0, winH);

    if (!projectLoaded) return;
    var uiScenePos = ui.Main.Scene.layout;
    
    // Available container for the scene (inside the UI)
    var containerX = uiScenePos.left;
    var containerY = uiScenePos.top;
    var containerW = uiScenePos.width;
    var containerH = uiScenePos.height - uiScenePos.top - 1;

    // Maintain the desired aspect ratio: 16:9
    // Available modes:
    //  - "fit": maintains 16:9 within the container (letterbox/pillarbox)
    //  - "cover": maintains 16:9 but scales the view to cover the entire
    //             container and crops the excess (equivalent to CSS cover)
    var aspectMode = "cover"; // change to "fit" for previous behavior
    var desiredAspect = 16/9;
    var viewW = containerW;
    var viewH = containerH;
    var viewX = containerX;
    var viewY = containerY;

    // Calculate letterbox/pillarbox to fit the view to the container
    if (containerW > 0 && containerH > 0) {
        var containerAspect = containerW / containerH;
        
        // First calculate the "fit view" dimensions (the largest 16:9 view
        // that fits inside the container). We'll use this for both fit and cover
        // modes to calculate the zoom needed in cover mode.
        var fitViewW, fitViewH, fitViewX, fitViewY;
        if (containerAspect > desiredAspect) {
            // Pillarbox (vertical bars on sides)
            fitViewH = containerH;
            fitViewW = fitViewH * desiredAspect;
            fitViewX = containerX + (containerW - fitViewW) / 2;
            fitViewY = containerY;
        } else {
            // Letterbox (horizontal bars on top/bottom)
            fitViewW = containerW;
            fitViewH = fitViewW / desiredAspect;
            fitViewX = containerX;
            fitViewY = containerY + (containerH - fitViewH) / 2;
        }

        if (aspectMode == "fit") {
            // Fit mode: keep entire view visible with letterbox/pillarbox
            if (containerAspect > desiredAspect) {
                // Container wider than 16:9 -> side bars (pillarbox)
                viewH = containerH;
                viewW = viewH * desiredAspect;
                viewX = containerX + (containerW - viewW) / 2;
                viewY = containerY;
            } else {
                // Container taller than 16:9 -> top/bottom bars (letterbox)
                viewW = containerW;
                viewH = viewW / desiredAspect;
                viewX = containerX;
                viewY = containerY + (containerH - viewH) / 2;
            }
        } else {
            // Cover mode: scale the view to cover the entire container, maintaining
            // 16:9 aspect, then crop the excess centered.
            // In cover mode we don't move the viewport outside the container: we keep
            // the viewport equal to the container and instead zoom the camera (reducing
            // the FOV) to achieve the crop effect.
            viewW = containerW;
            viewH = containerH;
            viewX = containerX;
            viewY = containerY;
            
            // Calculate the scale needed to cover the container relative to the
            // fitView (value >= 1 when enlargement is needed)
            var scaleX = (fitViewW > 0) ? (containerW / fitViewW) : 1;
            var scaleY = (fitViewH > 0) ? (containerH / fitViewH) : 1;
            var zoomScale = max(scaleX, scaleY);
        }
    }

    // Set the view (position and size) with the result of the adaptation
    view_set_xport(1, viewX);
    view_set_yport(1, viewY);
    view_set_wport(1, viewW);
    view_set_hport(1, viewH);

    // Update the 3D camera aspect and request recalculation of the projection
    // (if the camera object exposes updateProjectionMatrix) - we use the aspect
    // corresponding to the actual view used for rendering
    if (viewW > 0 && viewH > 0) {
        camera.aspect = viewW / viewH;
        camera.updateProjectionMatrix();
    }
}
