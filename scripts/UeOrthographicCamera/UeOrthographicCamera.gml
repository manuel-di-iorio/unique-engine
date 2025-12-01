/**
 * Camera that uses orthographic projection.
 * In this projection mode, an object's size in the rendered image stays constant 
 * regardless of its distance from the camera.
 * @extends UeCamera
 */
function UeOrthographicCamera(data = {}): UeCamera(data) constructor {
    isOrthographicCamera = true;
    type = "OrthographicCamera";
    
    // Get viewport dimensions for default frustum calculation
    var viewWidth = view_wport[view];
    var viewHeight = view_hport[view];
    
    // Orthographic frustum parameters
    left   = data[$ "left"]   ?? -viewWidth / 2;
    right  = data[$ "right"]  ?? viewWidth / 2;
    top    = data[$ "top"]    ?? viewHeight / 2;
    bottom = data[$ "bottom"] ?? -viewHeight / 2;
    near   = data[$ "near"]   ?? 0.1;
    far    = data[$ "far"]    ?? 2000;
    zoom   = data[$ "zoom"]   ?? 1;
    
    /**
     * Updates the camera's projection matrix using orthographic projection.
     * The zoom factor is applied to scale the frustum.
     */
    function updateProjectionMatrix() {
        gml_pragma("forceinline");
        var dx = (right - left) / (2 * zoom);
        var dy = (top - bottom) / (2 * zoom);
        var cx = (right + left) / 2;
        var cy = (top + bottom) / 2;
        
        var _left = cx - dx;
        var _right = cx + dx;
        var _top = cy + dy;
        var _bottom = cy - dy;
        
        matrix_build_projection_ortho(_left, _right, _bottom, _top, near, far, global.UE_DUMMY_ARRAY16);
        projectionMatrix.fromArray(global.UE_DUMMY_ARRAY16);
        projectionMatrixInverse.copy(projectionMatrix).invert();
        camera_set_proj_mat(camera, projectionMatrix.data);
    }
    
    // Build the orthographic projection
    updateProjectionMatrix();
}
