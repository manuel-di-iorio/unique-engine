/**
 * Abstract base class for cameras.
 * This class is not intended to be used directly, but to be inherited from.
 * @extends UeObject3D
 */
function UeCamera(data = {}): UeObject3D(data) constructor {
    isCamera = true;
    type = "Camera";
    
    // GameMaker camera and view
    view = data[$ "view"] ?? 0;
    camera = camera_create();
    
    // Camera target (point the camera is looking at)
    target = vec3_create(data[$ "xt"] ?? 0, data[$ "yt"] ?? 1, data[$ "zt"] ?? 0);
    
    // Camera up vector
    upX = data[$ "upX"] ?? global.UE_DEFAULT_UP[VEC3.x];
    upY = data[$ "upY"] ?? global.UE_DEFAULT_UP[VEC3.y];
    upZ = data[$ "upZ"] ?? global.UE_DEFAULT_UP[VEC3.z];
    
    // Matrices
    matrixWorldInverse = mat4_create();
    projectionMatrix = mat4_create();
    projectionMatrixInverse = mat4_create();
    
    /**
     * Updates the camera's world matrix and view matrix.
     * This method calculates the view matrix using lookat transformation.
     */
    function updateMatrixWorld() {
      gml_pragma("forceinline");
      matrix_build_lookat(
          position[VEC3.x], position[VEC3.y], position[VEC3.z],  // From
          target[VEC3.x], target[VEC3.y], target[VEC3.z], // To
          upX, upY, upZ, // Up
          matrixWorldInverse
      )
      
      // Get the inverted matrix from the lookat matrix
      mat4_copy(matrixWorld, matrixWorldInverse);
      mat4_invert(matrixWorld);
      
      camera_set_view_mat(camera, matrixWorldInverse);
    }
    
    /**
     * Updates the camera's projection matrix.
     * This is an abstract method that must be implemented by subclasses.
     */
    function updateProjectionMatrix() {
        // Abstract method - to be implemented by subclasses
        show_debug_message("UeCamera.updateProjectionMatrix() is not implemented in the derived class.", true);
    }
    
    /**
     * Destroys the GameMaker camera instance.
     */
    function dispose() {
        gml_pragma("forceinline");
        camera_destroy(camera);
        camera = undefined;
        return self;
    }
    
    // Initialize position
    setPosition(data[$ "x"] ?? 0, data[$ "y"] ?? -100, data[$ "z"] ?? 0);
    
    // Setup view
    updateMatrixWorld();
    
    function use() {
        view_set_camera(view, camera);
        view_set_visible(view, true);
        return self;
    }
}
