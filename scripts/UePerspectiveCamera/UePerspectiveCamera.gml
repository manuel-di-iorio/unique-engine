/**
 * Camera that uses perspective projection.
 * This projection mode is designed to mimic the way the human eye sees.
 * Objects further from the camera appear smaller.
 * @extends UeCamera
 */
function UePerspectiveCamera(data = {}): UeCamera(data) constructor { 
    isPerspectiveCamera = true;
    type = "PerspectiveCamera";
    
    // Perspective-specific parameters
    fov  = data[$ "fov"]  ?? 60;
    near = data[$ "near"] ?? .1;
    far  = data[$ "far"]  ?? 2000;
    aspect = data[$ "aspect"] ?? view_wport[view] / view_hport[view];
    
    /**
     * Updates the camera's projection matrix using perspective projection.
     */
    function updateProjectionMatrix() {
      gml_pragma("forceinline");
      matrix_build_projection_perspective_fov(fov, aspect, near, far, projectionMatrix);
      
      mat4_copy(projectionMatrixInverse, projectionMatrix);
      matrix_inverse(projectionMatrixInverse, projectionMatrixInverse);
    	
      camera_set_proj_mat(camera, projectionMatrix);
    }
    
    // Build the perspective projection
    updateProjectionMatrix();
}
