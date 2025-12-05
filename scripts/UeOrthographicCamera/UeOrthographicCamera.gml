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
        var w = abs(right - left);
        var h = abs(top - bottom);
        matrix_build_projection_ortho(w, h, near, far, global.UE_DUMMY_ARRAY16);
        projectionMatrix.fromArray(global.UE_DUMMY_ARRAY16);
        projectionMatrixInverse.copy(projectionMatrix);
    	camera_set_proj_mat(camera, projectionMatrix.data);
    }
    
    // Build the orthographic projection
    updateProjectionMatrix();
}
