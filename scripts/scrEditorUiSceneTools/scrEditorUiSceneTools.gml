function EditorUiSceneTools(ui) constructor {
    self.ui = ui;
    
    // Create the container
    ui.SceneTools = new UiNode({
        name: "SceneTools",
        position: "absolute",
        top: 65,
        left: "21%",
        minWidth: 400,
        flexDirection: "row",
        alignItems: "center",
        justifyContent: "space-between",
        paddingVertical: 8,
        paddingHorizontal: 4
    });
    
    with (ui.SceneTools) {
       // Custom draw for background and shadow
       function onDraw() {
           draw_set_alpha(1);
           draw_set_color(global.UI_COL_BAR_BG);
           draw_roundrect_ext(self.x1, self.y1, self.x2, self.y2, 16, 16, false);
       }
       
       // Dynamic positioning logic
       self.onStep(function(layoutUpdated) {
         if (!layoutUpdated) return;
   
         var target = global.UI.Main.Scene;
   
         var newLeft = floor(target.x1 + 10);
         var newTop = floor(target.y1 + 10);       
         
         // Only update if position changed by more than 1 pixel to avoid loops
         if (abs(self.getLeft() - newLeft) > 1 || abs(self.getTop() - newTop) > 1) {
            self.setLeft(newLeft);
            self.setTop(newTop);
         }
       });
    }
    
    // Left container for Tools
    ui.SceneTools.Left = new UiNode({
        name: "Left",
        flexDirection: "row",
        alignItems: "center"
    });
    
    // Right container for Camera
    ui.SceneTools.Right = new UiNode({
        name: "Right",
        flexDirection: "row",
        alignItems: "center"
    });
    
    ui.SceneTools.add(ui.SceneTools.Left, ui.SceneTools.Right);
    
    // Button Style
    var btnStyle = { marginLeft: 5, marginRight: 5, width: 25, height: 25 };
    
    // View tool
    ui.SceneTools.BtnView = new UiButton(sprUiEye, btnStyle, { tooltip: "View tool (Q)" });
    ui.SceneTools.BtnView.onClick(function() {
        oSceneEditor.editorManager.setTool("view");
        self.updateToolButtons();
    });
    
    // Move tool
    ui.SceneTools.BtnMove = new UiButton(sprUiMove, btnStyle, { tooltip: "Move tool (W)" });
    ui.SceneTools.BtnMove.onClick(function() {
        oSceneEditor.editorManager.setTool("move");
        self.updateToolButtons();
    });

    // Rotate tool
    ui.SceneTools.BtnRotate = new UiButton(sprUiRotateModel, btnStyle, { tooltip: "Rotate tool (E)" });
    ui.SceneTools.BtnRotate.onClick(function() {
        oSceneEditor.editorManager.setTool("rotate");
        self.updateToolButtons();
    });

    // Scale tool
    ui.SceneTools.BtnScale = new UiButton(sprUiScaleModel, btnStyle, { tooltip: "Scale tool (R)" });
    ui.SceneTools.BtnScale.onClick(function() {
        oSceneEditor.editorManager.setTool("scale");
        self.updateToolButtons();
    });
    
    self.updateToolButtons = function() {
        var tool = oSceneEditor.editorManager.activeTool;
        ui.SceneTools.BtnView.selected = (tool == "view");
        ui.SceneTools.BtnMove.selected = (tool == "move");
        ui.SceneTools.BtnRotate.selected = (tool == "rotate");
        ui.SceneTools.BtnScale.selected = (tool == "scale");
        global.UI.requestRedraw();
    };
    
    // Initial update
    self.updateToolButtons();    

    ui.SceneTools.Left.add(ui.SceneTools.BtnView, ui.SceneTools.BtnMove, ui.SceneTools.BtnRotate, ui.SceneTools.BtnScale);
    
    // Toggle camera easing
    // ui.SceneTools.BtnCamAccel = new UiButton(sprUiCamera, btnStyle, { tooltip: "Toggle camera easing" });

    // with (ui.SceneTools.BtnCamAccel) {
    //     onClick(function() {
    //         var sm = oSceneEditor.sceneManager;
    //         if (sm.orbit != undefined) {
    //             // Toggle between 0.3 (Damped) and 1.0 (Linear)
    //             if (sm.orbit.dampingFactor >= 1.0) {
    //                 sm.orbit.dampingFactor = 0.3;
    //             } else {
    //                 sm.orbit.dampingFactor = 1.0;
    //             }
                
    //             self.selected = (sm.orbit.dampingFactor < 1.0);
    //             sm.orbit.enableDamping = self.selected;
    //             global.UI.requestRedraw();
    //             oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
    //         }
    //     });
    // }
    
    // Set initial state
    // if (oSceneEditor.sceneManager.orbit != undefined) {
    //     ui.SceneTools.BtnCamAccel.selected = (oSceneEditor.sceneManager.orbit.dampingFactor < 1.0);
    // }
    
    // self.updateDampingButton = function() {
    //     ui.SceneTools.BtnCamAccel.selected = (oSceneEditor.sceneManager.orbit.dampingFactor < 1.0);
    //     global.UI.requestRedraw();
    // };
    
    // Reset camera position
    ui.SceneTools.BtnResetCam = new UiButton(sprUiCenter, btnStyle, { tooltip: "Reset camera" });
    ui.SceneTools.BtnResetCam.onClick(function() {
        var sm = oSceneEditor.sceneManager;
        if (sm.camera != undefined) {
            // Reset to default position
            sm.camera.setPosition(100, -300, 70);
            sm.camera.lookAt(0, 0, 0);
            if (sm.orbit != undefined) {
                vec3_set(sm.orbit.target, 0, 0, 0);
                sm.orbit.reset(); 
            }
            oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
        }
    });

    // Toggle grid
    ui.SceneTools.BtnGrid = new UiButton(sprUiGrid, btnStyle, { tooltip: "Toggle grid" });
    
    with (ui.SceneTools.BtnGrid) {
        onClick(function() {
            var sm = oSceneEditor.sceneManager;
            sm.grid.visible = !sm.grid.visible;
            sm.gridEnabled = sm.grid.visible;
            self.selected = sm.grid.visible;
            global.UI.requestRedraw();
            oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
        });
    }
    
    // Set initial state
    ui.SceneTools.BtnGrid.selected = oSceneEditor.sceneManager.grid.visible;
    
    // Toggle box colliders
    ui.SceneTools.BtnBoxColliders = new UiButton(sprUiGizmos, btnStyle, { tooltip: "Toggle box colliders" });
    
    with (ui.SceneTools.BtnBoxColliders) {
        onClick(function() {
            var sm = oSceneEditor.sceneManager;
            sm.showBoxColliders = !sm.showBoxColliders;
            sm.boxHelper.visible = sm.showBoxColliders;
            self.selected = sm.showBoxColliders;
            global.UI.requestRedraw();
            oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
        });
    }
    
    // Set initial state
    ui.SceneTools.BtnBoxColliders.selected = oSceneEditor.sceneManager.showBoxColliders;

    // Toggle grid snap
    ui.SceneTools.BtnGridSnap = new UiButton(sprUiSnap, btnStyle, { tooltip: "Toggle grid snap when moving objects" });
    
    with (ui.SceneTools.BtnGridSnap) {
        onClick(function() {
            var sm = oSceneEditor.sceneManager;
            sm.gridSnapEnabled = !sm.gridSnapEnabled;
            self.selected = sm.gridSnapEnabled;
            
            // Sync with transform controls
            if (sm.transformControls != undefined) {
                sm.transformControls.snapEnabled = sm.gridSnapEnabled;
            }
            
            // If enabled, prompt for size (or just let it be)
            if (sm.gridSnapEnabled) {
                var newSize = get_integer("Grid snap size:", sm.gridSnapSize);
                if (newSize > 0) {
                    sm.gridSnapSize = newSize;
                    if (sm.transformControls != undefined) sm.transformControls.snapSize = newSize;
                }
            }
            
            global.UI.requestRedraw();
            oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
        });
    }
    
    ui.SceneTools.BtnGridSnap.selected = oSceneEditor.sceneManager.gridSnapEnabled;

    // Orbit settings
    ui.SceneTools.BtnOrbitSettings = new UiButton(sprUiSection, btnStyle, { tooltip: "Orbit controls settings" });
    ui.SceneTools.BtnOrbitSettings.onClick(function() {
        var sm = oSceneEditor.sceneManager;
        var orbit = sm.orbit;
        if (orbit != undefined) {
            var newPan = get_integer("Pan speed (default 10):", orbit.panSpeed) ?? 10;
            var newRot = get_integer("Rotation speed (default 10):", orbit.rotateSpeed) ?? 10;
            var newZoom = get_integer("Zoom speed (default 2):", orbit.zoomSpeed) ?? 2;
            
            orbit.panSpeed = min(999999, max(0.00001, newPan));
            orbit.rotateSpeed = min(999999, max(0.00001, newRot));
            orbit.zoomSpeed = min(999999, max(0.00001, newZoom));
            
            oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
        }
    });

    ui.SceneTools.Right.add(ui.SceneTools.BtnResetCam, /*ui.SceneTools.BtnCamAccel,*/ ui.SceneTools.BtnGrid, ui.SceneTools.BtnGridSnap, ui.SceneTools.BtnBoxColliders, ui.SceneTools.BtnOrbitSettings);

    self.updateGridButton = function() {
        ui.SceneTools.BtnGrid.selected = oSceneEditor.sceneManager.grid.visible;
        ui.SceneTools.BtnGridSnap.selected = oSceneEditor.sceneManager.gridSnapEnabled;
        global.UI.requestRedraw();
    };

    self.updateBoxCollidersButton = function() {
        ui.SceneTools.BtnBoxColliders.selected = oSceneEditor.sceneManager.showBoxColliders;
        global.UI.requestRedraw();
    };
    
    ui.add(ui.SceneTools);
}
