function EditorUiSceneTools(ui) constructor {
    self.ui = ui;
    
    // Create the container
    ui.SceneTools = new UiNode({
        name: "SceneTools",
        position: "absolute",
        top: 65,
        left: "21%",
        minWidth: 300,
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
   
         var newLeft = target.x1 + 10;
         var newTop = target.y1 + 10;       
         
         if (self.getLeft() != newLeft || self.getTop() != newTop) {
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
    
    self.updateToolButtons = function() {
        var tool = oSceneEditor.editorManager.activeTool;
        ui.SceneTools.BtnView.selected = (tool == "view");
        ui.SceneTools.BtnMove.selected = (tool == "move");
        global.UI.needsRedraw = true;
    };
    
    // Initial update
    self.updateToolButtons();    

    ui.SceneTools.Left.add(ui.SceneTools.BtnView, ui.SceneTools.BtnMove);
    
    // Toggle camera easing
    ui.SceneTools.BtnCamAccel = new UiButton(sprUiCamera, btnStyle, { tooltip: "Toggle camera easing" });

    with (ui.SceneTools.BtnCamAccel) {
        onClick(function() {
            var sm = oSceneEditor.sceneManager;
            if (sm.orbit != undefined) {
                // Toggle between 0.3 (Damped) and 1.0 (Linear)
                if (sm.orbit.dampingFactor >= 1.0) {
                    sm.orbit.dampingFactor = 0.3;
                } else {
                    sm.orbit.dampingFactor = 1.0;
                }
                
                self.selected = (sm.orbit.dampingFactor < 1.0);
                sm.orbit.enableDamping = self.selected;
                global.UI.needsRedraw = true;
                oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
            }
        });
    }
    
    // Set initial state
    if (oSceneEditor.sceneManager.orbit != undefined) {
        ui.SceneTools.BtnCamAccel.selected = (oSceneEditor.sceneManager.orbit.dampingFactor < 1.0);
    }
    
    self.updateDampingButton = function() {
        ui.SceneTools.BtnCamAccel.selected = (oSceneEditor.sceneManager.orbit.dampingFactor < 1.0);
        global.UI.needsRedraw = true;
    };
    
    // Reset camera position
    ui.SceneTools.BtnResetCam = new UiButton(sprUiCenter, btnStyle, { tooltip: "Reset camera" });
    ui.SceneTools.BtnResetCam.onClick(function() {
        var sm = oSceneEditor.sceneManager;
        if (sm.camera != undefined) {
            // Reset to default position
            sm.camera.setPosition(100, -300, 70);
            sm.camera.lookAt(0, 0, 0);
            if (sm.orbit != undefined) {
                sm.orbit.target.set(0, 0, 0);
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
            global.UI.needsRedraw = true;
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
            global.UI.needsRedraw = true;
            oSceneEditor.projectManager.saver.saveEditorSettings(oSceneEditor.projectManager);
        });
    }
    
    // Set initial state
    ui.SceneTools.BtnBoxColliders.selected = oSceneEditor.sceneManager.showBoxColliders;

    ui.SceneTools.Right.add(ui.SceneTools.BtnResetCam, ui.SceneTools.BtnCamAccel, ui.SceneTools.BtnGrid, ui.SceneTools.BtnBoxColliders);

    self.updateGridButton = function() {
        ui.SceneTools.BtnGrid.selected = oSceneEditor.sceneManager.grid.visible;
        global.UI.needsRedraw = true;
    };

    self.updateBoxCollidersButton = function() {
        ui.SceneTools.BtnBoxColliders.selected = oSceneEditor.sceneManager.showBoxColliders;
        global.UI.needsRedraw = true;
    };
    
    ui.add(ui.SceneTools);
}
