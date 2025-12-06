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
    target = new UeVector3(data[$ "xt"] ?? 0, data[$ "yt"] ?? 1, data[$ "zt"] ?? 0);
    
    // Camera up vector
    upX = data[$ "upX"] ?? global.UE_OBJECT3D_DEFAULT_UP.x;
    upY = data[$ "upY"] ?? global.UE_OBJECT3D_DEFAULT_UP.y;
    upZ = data[$ "upZ"] ?? global.UE_OBJECT3D_DEFAULT_UP.z;
    
    // Matrices
    matrixWorldInverse = new UeMatrix4();
    projectionMatrix = new UeMatrix4();
    projectionMatrixInverse = new UeMatrix4();
    
    /**
     * Updates the camera's world matrix and view matrix.
     * This method calculates the view matrix using lookat transformation.
     */
    function updateMatrixWorld() {
        gml_pragma("forceinline");
        matrix_build_lookat(
            position.x, position.y, position.z,  // From
            target.x, target.y, target.z, // To
            upX, upY, upZ, // Up
            global.UE_DUMMY_ARRAY16
        )
        matrixWorldInverse.fromArray(global.UE_DUMMY_ARRAY16);
        matrixWorld.copy(matrixWorldInverse).invert();
        camera_set_view_mat(camera, global.UE_DUMMY_ARRAY16);
    }
    
    /**
     * Updates the camera's projection matrix.
     * This is an abstract method that must be implemented by subclasses.
     */
    function updateProjectionMatrix() {
        // Abstract method - to be implemented by subclasses
        show_error("UeCamera.updateProjectionMatrix() must be implemented by subclass", true);
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
