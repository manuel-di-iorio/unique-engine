/**
 * UeTransformControls constructor
 * Provides interactive gizmo controls to translate, rotate, and scale 3D objects.
 * @param {UeCamera} camera - Camera used for raycasting and projection.
 * @param {Object} data - Optional initial settings.
 */
function UeTransformControls(camera, data = {}) : UeControls(data) constructor {
    // === BASE PROPERTIES ===
    self.camera = camera;             // Camera for raycasting calculations
    self.axis = undefined;            // Currently selected axis: "X", "Y", "Z" or undefined
    self.dragging = false;            // Flag to indicate if dragging is in progress
    self.size = 50;                   // Gizmo visual size multiplier
    self.mode = "translate";          // Current transform mode: "translate", "rotate", or "scale"
    self.space = "world";             // Transform space: "world" or "local"

    // === BOUNDS AND SNAP SETTINGS ===
    self.minX = -infinity; self.minY = -infinity; self.minZ = -infinity;
    self.maxX =  infinity; self.maxY =  infinity; self.maxZ =  infinity;

    self.translationSnap = undefined; // Increment step for translation snapping
    self.rotationSnap = undefined;    // Increment step for rotation snapping (radians)
    self.scaleSnap = undefined;       // Increment step for scale snapping

    // === AXIS VISIBILITY ===
    self.showX = true;                // Show X axis gizmo line
    self.showY = true;                // Show Y axis gizmo line
    self.showZ = true;                // Show Z axis gizmo line

    // === INTERNAL HELPERS ===
    self._raycaster = new UeRaycaster();  // Raycaster for mouse picking
    self._root = new UeMesh();         // Root Object3D for the gizmo

    self._plane = new UePlane();           // Plane used for intersection during dragging

    // Temporary vectors for dragging calculations
    self.pointStart = new UeVector3();
    self.pointEnd = new UeVector3();
    self.delta = new UeVector3();

    // Store object's initial transform at drag start
    self._positionStart = new UeVector3();
    self._rotationStart = new UeQuaternion();
    self._scaleStart = new UeVector3();

    /**
     * Builds the gizmo visual lines for the axes according to current size and visibility.
     */
    function buildGizmo() {
        gml_pragma("forceinline");
        clearGizmo();  // Remove previous gizmo geometry to avoid memory leaks
        
        var axisLength = self.size * 1.5;

        // Create X axis line if visible
        if (self.showX) {
            var geoX = new UeLineGeometry({ color: c_red });
            geoX.setPositions([0,0,0, -axisLength,0,0]);
            geoX.build();
            var meshX = new UeLine(geoX);
            meshX.name = "X";                       // Name used for raycast identification
            self._root.add(meshX);
        }
        
        // Create Y axis line if visible
        if (self.showY) {
            var geoY = new UeLineGeometry({ color: c_blue });
            geoY.setPositions([0,0,0, 0,-axisLength,0]);
            geoY.build();
            var meshY = new UeLine(geoY);
            meshY.name = "Y";
            self._root.add(meshY);
        }
        
        // Create Z axis line if visible
        if (self.showZ) {
            var geoZ = new UeLineGeometry({ color: c_green });
            geoZ.setPositions([0,0,0, 0,0,axisLength]); // Line along Z axis
            geoZ.build();
            var meshZ = new UeLine(geoZ);
            meshZ.name = "Z";
            self._root.add(meshZ);
        }

        self._root.visible = false; // Gizmo starts hidden until attached to an object
    }

    /**
     * Updates the gizmo's position and orientation to match the attached object's transform.
     */
    function update() {
        gml_pragma("forceinline");
        if (!self.object) return;

        // Set gizmo root position to the object's position
        self._root.position.copy(self.object.position);

        // Rotate gizmo to match object's rotation if in local space,
        // otherwise reset gizmo rotation to identity for world space mode
        if (self.space == "local") {
            self._root.rotation.copy(self.object.rotation);
        } else {
            self._root.rotation.identity();
        }
    }

    /**
     * Updates the currently hovered/selected axis by performing raycast on gizmo lines.
     */
    function updateInteraction() {
        gml_pragma("forceinline");
        var intersects = self._raycaster.intersectObjects(self._root.children);
     
        if (array_length(intersects) > 0) {
            self.axis = intersects[0].object.name;  // Set axis to hit object's name (X, Y, Z)
        } else {
            self.axis = undefined;                  // No axis hovered
        }
    }

    /**
     * Attaches the transform controls to a 3D object, enabling manipulation.
     * @param {UeObject3D} object - The target object to control.
     * @returns {self}
     */
    function attach(object) {
        gml_pragma("forceinline");
        self.object = object;
        self._root.visible = true;   // Show gizmo
        update();                    // Sync gizmo transform with object
        return self;
    }

    /**
     * Detaches the transform controls from the current object and hides the gizmo.
     * @returns {self}
     */
    function detach() {
        gml_pragma("forceinline");
        self._root.visible = false;  // Hide gizmo
        self.axis = undefined;
        self.object = undefined;
        return self;
    }

    /**
     * Handles pointer down event to start dragging the selected axis if possible.
     */
    function onPointerDown() {
        gml_pragma("forceinline");
        if (!self.object || self.dragging) return;

        // Setup raycaster from current mouse position
        self._raycaster.setFromCamera(self.camera);
        updateInteraction();  // Update which axis is hovered

        if (self.axis != undefined) {
            self.dragging = true;

            // Determine plane normal based on selected axis for dragging
            var axisVec = new UeVector3();
            switch (self.axis) {
                case "X": 
                    axisVec.set(1,0,0); 
                    break;
                case "Y": 
                    axisVec.set(0,1,0); 
                    break;
                case "Z": 
                    axisVec.set(0,0,1); 
                    break;
            }

            // Rotate plane normal by object's rotation if in local space
            if (self.space == "local") {
                axisVec.applyQuaternion(self.object.rotation);
            }

            // Calculate the plane normal perpendicular to the camera direction
            var camDir = self.camera.getWorldDirection();
            var planeNormal = camDir.clone().cross(axisVec).cross(axisVec).normalize();
            self._plane.setFromNormalAndCoplanarPoint(planeNormal, self.object.position);

            // Calculate initial intersection point of ray and plane
            var intersectionPoint = self._raycaster.ray.intersectPlane(self._plane);
            if (intersectionPoint == undefined) {
                // No intersection found; cancel dragging
                self.dragging = false;
                return;
            }
            self.pointStart.copy(intersectionPoint);

            // Save the initial transform state before dragging begins
            self._positionStart.copy(self.object.position);
            self._rotationStart.copy(self.object.rotation);
            self._scaleStart.copy(self.object.scale);
        }
    }

    /**
     * Handles pointer move event to update dragging transform.
     */
    function onPointerMove() {
        gml_pragma("forceinline");
        if (!self.dragging) return;

        // Update raycaster for current mouse position
        self._raycaster.setFromCamera(self.camera);

        // Calculate intersection with drag plane
        var intersectionPoint = self._raycaster.ray.intersectPlane(self._plane);
        if (intersectionPoint == undefined) return;

        self.pointEnd.copy(intersectionPoint);

        // Calculate drag delta vector between current and start points
        self.delta.copy(self.pointEnd).sub(self.pointStart);

        applyTransform();  // Apply transform change to object based on delta
        update();          // Update gizmo transform to match object
    }

    /**
     * Handles pointer up event to stop dragging.
     */
    function onPointerUp() {
        gml_pragma("forceinline");
        self.dragging = false;
        self.axis = undefined;
    }

    /**
     * Applies the transformation (translate, rotate, scale) to the attached object based on drag delta.
     */
    function applyTransform() {
        gml_pragma("forceinline");
        if (!self.object) return;
    
        if (self.mode == "translate") {
            var newPos = self._positionStart.clone();
    
            var delta = self.delta.clone();
            
            if (self.space == "local") {
                // Trasforma il delta dal world space al local space dell'oggetto
                var invRotation = self.object.rotation.clone().invert();
                delta.applyQuaternion(invRotation);
            }
    
            // Apply delta only along the selected axis
            if (self.axis == "X") newPos.x += delta.x;
            else if (self.axis == "Y") newPos.y += delta.y;
            else if (self.axis == "Z") newPos.z += delta.z;
  
            // Snap translation if enabled
            if (self.translationSnap != undefined) {
                if (self.axis == "X") newPos.x = round(newPos.x / self.translationSnap) * self.translationSnap;
                else if (self.axis == "Y") newPos.y = round(newPos.y / self.translationSnap) * self.translationSnap;
                else if (self.axis == "Z") newPos.z = round(newPos.z / self.translationSnap) * self.translationSnap;
            }
    
            // Clamp to configured limits
            newPos.x = clamp(newPos.x, self.minX, self.maxX);
            newPos.y = clamp(newPos.y, self.minY, self.maxY);
            newPos.z = clamp(newPos.z, self.minZ, self.maxZ);
    
            // Apply position change
            self.object.position.copy(newPos);
        }
        else if (self.mode == "rotate") {
            var axisVec = new UeVector3();
            if (self.axis == "X") axisVec.set(1,0,0);
            else if (self.axis == "Y") axisVec.set(0,1,0);
            else if (self.axis == "Z") axisVec.set(0,0,1);
            else return; // no axis selected
    
            if (self.space == "local") {
                axisVec.applyQuaternion(self.object.rotation);
            }
    
            // Usa la proiezione del delta sull'asse perpendicolare
            var deltaLength = self.delta.length();
            var angle = deltaLength * 0.01; // Fattore di sensibilità per la rotazione
            
            if (self.rotationSnap != undefined) {
                angle = round(angle / self.rotationSnap) * self.rotationSnap;
            }
    
            // Create quaternion for rotation around axisVec by angle
            var q = new UeQuaternion();
            q.setFromAxisAngle(axisVec, angle);
    
            self.object.rotation.multiplyQuaternions(q, self._rotationStart);
        }
        else if (self.mode == "scale") {
            var newScale = self._scaleStart.clone();
            var delta = self.delta.clone();
    
            var scaleFactor = 1.0 + (delta.length() * 0.01); // Fattore di sensibilità
            
            if (self.space == "local") {
                var invRotation = self.object.rotation.clone().invert();
                delta.applyQuaternion(invRotation);
            }
    
            // Apply scale factor only to the selected axis
            if (self.axis == "X") newScale.x = self._scaleStart.x * scaleFactor;
            else if (self.axis == "Y") newScale.y = self._scaleStart.y * scaleFactor;
            else if (self.axis == "Z") newScale.z = self._scaleStart.z * scaleFactor;
    
            // Snap scale if enabled
            if (self.scaleSnap != undefined) {
                if (self.axis == "X") newScale.x = round(newScale.x / self.scaleSnap) * self.scaleSnap;
                else if (self.axis == "Y") newScale.y = round(newScale.y / self.scaleSnap) * self.scaleSnap;
                else if (self.axis == "Z") newScale.z = round(newScale.z / self.scaleSnap) * self.scaleSnap;
            }
    
            // Clamp scale to configured limits
            newScale.x = clamp(newScale.x, max(0.01, self.minX), self.maxX);
            newScale.y = clamp(newScale.y, max(0.01, self.minY), self.maxY);
            newScale.z = clamp(newScale.z, max(0.01, self.minZ), self.maxZ);
    
            self.object.scale.copy(newScale);
        }
    }

    // === API METHODS ===

    /**
     * Returns the root Object3D node of the gizmo for attaching to the scene.
     * @returns {UeObject3D}
     */
    function getHelper() { 
        gml_pragma("forceinline");
        return self._root; 
    }
    
    /**
     * Returns the raycaster instance used for picking.
     * @returns {UeRaycaster}
     */
    function getRaycaster() {
        gml_pragma("forceinline"); 
        return self._raycaster; 
    }
    
    /**
     * Returns the current transform mode.
     * @returns {string} "translate", "rotate", or "scale"
     */
    function getMode() {
        gml_pragma("forceinline");
        return self.mode; 
    }
    
    /**
     * Sets the transform mode.
     * @param {string} mode - "translate", "rotate", or "scale"
     * @returns {self}
     */
    function setMode(mode) {
        gml_pragma("forceinline"); 
        self.mode = mode; 
        return self; 
    }
    
    /**
     * Sets the translation snap increment.
     * @param {number} value
     * @returns {self}
     */
    function setTranslationSnap(value) {
        gml_pragma("forceinline"); 
        self.translationSnap = value; 
        return self; 
    }
    
    /**
     * Sets the rotation snap increment (radians).
     * @param {number} value
     * @returns {self}
     */
    function setRotationSnap(value) {
        gml_pragma("forceinline"); 
        self.rotationSnap = value; 
        return self; 
    }
    
    /**
     * Sets the scale snap increment.
     * @param {number} value
     * @returns {self}
     */
    function setScaleSnap(value) { 
        gml_pragma("forceinline");
        self.scaleSnap = value; 
        return self; 
    }
    
    /**
     * Sets the visual size of the gizmo and rebuilds it.
     * @param {number} value
     * @returns {self}
     */
    function setSize(value) {
        gml_pragma("forceinline");
        self.size = value;
        buildGizmo();  // Rebuild gizmo geometry with new size
        return self;
    }
    
    /**
     * Sets the transform space: "world" or "local" and updates the gizmo rotation.
     * @param {string} value
     * @returns {self}
     */
    function setSpace(value) {
        gml_pragma("forceinline");
        self.space = value;
        update(); // Update gizmo to match new space setting
        return self;
    }
    
    /**
     * Resets the transform of the attached object to its state at drag start.
     * Only active while dragging.
     * @returns {self}
     */
    function reset() {
        gml_pragma("forceinline");
        if (!self.object || !self.dragging) return self;
        
        self.object.position.copy(self._positionStart);
        self.object.rotation.copy(self._rotationStart);
        self.object.scale.copy(self._scaleStart);
        self.pointStart.copy(self.pointEnd);
        update();
        return self;
    }
    
    /**
     * Clears and disposes of the gizmo geometry and children.
     */
    function clearGizmo() {
        gml_pragma("forceinline");
        var _children = self._root.children;
        var count = array_length(_children);
        for (var i = count - 1; i >= 0; i--) {
            var child = _children[i];
            var geometry = child[$ "geometry"];
            if (geometry != undefined) {
                child.geometry.dispose();  // Dispose geometry to free memory
            }
        }
        self._root.clear();  // Remove all children from gizmo root
    } 

    // Build initial gizmo on creation
    buildGizmo();
    
    return self;
}