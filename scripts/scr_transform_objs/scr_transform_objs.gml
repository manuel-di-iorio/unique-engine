/**
 * Transform the objects based on the gizmos input
 */
function scr_transform_objs() {
    if (selectedGizmo == -1) return;
	var mouseSensY = settings.mouse.ysens;
    
	var prevX = selectedObj.x;
	var prevY = selectedObj.y;
	var prevZ = selectedObj.z;
	
    /** Translate **/
    switch (selectedGizmo.gizmo) {
        case GizmoComponent.translateX:
			selectedObj.x += winMouse3DX - winOldMouse3DX;
        break;
        
        case GizmoComponent.translateY:
            selectedObj.y += winMouse3DY - winOldMouse3DY;
        break;
        
        case GizmoComponent.translateZ:
            selectedObj.z -= (winMouseY - winOldMouseY) / (4 / mouseSensY);
        break;
        
		// Plane X
        case GizmoComponent.translatePlaneYZ:
            selectedObj.y += winMouse3DY_planeX - winOldMouse3DY_planeX;		
			selectedObj.z += winMouse3DZ_planeX - winOldMouse3DZ_planeX;		
        break;
        
		// Plane Y
        case GizmoComponent.translatePlaneXZ:
			selectedObj.x += winMouse3DX_planeY - winOldMouse3DX_planeY;			
			selectedObj.z += winMouse3DZ_planeY - winOldMouse3DZ_planeY;		
        break;
        
		// Plane Z
        case GizmoComponent.translatePlaneXY:
            selectedObj.x += winMouse3DX - winOldMouse3DX;
            selectedObj.y += winMouse3DY - winOldMouse3DY;
        break;
    }
	
	// Detect a transform change
	if (prevX != selectedObj.x || prevY != selectedObj.y || prevZ != selectedObj.z) {
		scr_on_object_change(selectedObj);		
	}
}
