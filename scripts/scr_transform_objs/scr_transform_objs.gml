/**
 * Transform the objects based on the gizmos input
 */
function scr_transform_objs() {
    if (selectedGizmo == -1) return;
    
    /** Translate **/
    switch (selectedGizmo.gizmo) {
        case GizmoComponent.translateX:
            selectedObj.x += (winMouse3DX - winOldMouse3DX);
        break;
        
        case GizmoComponent.translateY:
            selectedObj.y += (winMouse3DY - winOldMouse3DY);
        break;
        
        case GizmoComponent.translateZ:
            selectedObj.z -= (winMouseY - winOldMouseY)/10;
        break;
        
        case GizmoComponent.translatePlaneYZ:
            selectedObj.y += winMouse3DY - winOldMouse3DY;
            selectedObj.z -= (winMouseY - winOldMouseY)/10;
        break;
        
        case GizmoComponent.translatePlaneXZ:
            selectedObj.x += winMouse3DX - winOldMouse3DX;
            selectedObj.z -= (winMouseY - winOldMouseY)/10;
        break;
        
        case GizmoComponent.translatePlaneXY:
            selectedObj.x += winMouse3DX - winOldMouse3DX;
            selectedObj.y += winMouse3DY - winOldMouse3DY;
        break;
    }
}
