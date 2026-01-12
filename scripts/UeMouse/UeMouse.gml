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

    /**
     * Projects a 3D world-space position to 2D screen coordinates.
     * @param {Array<Real>} worldPos - The 3D position in world space.
     * @param {Struct} camera - The camera object used for projection.
     * @returns {Struct|Undefined} A struct {x, y} with screen coordinates, or undefined if outside viewing frustum.
     */
    function worldToScreen(worldPos, camera) {
        gml_pragma("forceinline");
        
        var temp = global.UE_VEC3_TEMP0;
        vec3_set(temp, worldPos[0], worldPos[1], worldPos[2]);
        vec3_project(temp, camera);
        
        // Check if the point is within the NDC cube.
        // NDC Z depends on the platform/API, but usually 0..1 or -1..1.
        // We use a broad check for clipping.
        if (temp[2] < -1 || temp[2] > 1) return undefined;
        
        var vw = view_wport[self.view];
        var vh = view_hport[self.view];
        var vx = view_xport[self.view];
        var vy = view_yport[self.view];
        
        return {
            x: vx + (temp[0] * 0.5 + 0.5) * vw,
            y: vy + (temp[1] * 0.5 + 0.5) * vh
        };
    }

    /**
     * Unprojects screen coordinates into a 3D world-space position.
     * @param {Real} screenX - The X screen coordinate.
     * @param {Real} screenY - The Y screen coordinate.
     * @param {Struct} camera - The camera object used for unprojection.
     * @param {Real} depth - The depth (-1 to 1) to unproject at. -1 is near plane, 1 is far plane. Default is 0.
     * @returns {Array<Real>} A new 3D vector in world space.
     */
    function screenToWorld(screenX, screenY, camera, depth = 0) {
        gml_pragma("forceinline");
        
        var vw = view_wport[self.view];
        var vh = view_hport[self.view];
        var vx = view_xport[self.view];
        var vy = view_yport[self.view];
        
        var ndcX = ((screenX - vx) / vw) * 2 - 1;
        var ndcY = ((screenY - vy) / vh) * 2 - 1; 
        var ndcZ = depth;
        
        var worldPos = vec3_create(ndcX, ndcY, ndcZ);
        vec3_unproject(worldPos, camera);
        
        return worldPos;
    }
}
