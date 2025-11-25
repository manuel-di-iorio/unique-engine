/**
 * UeTransformControls constructor
 * Provides interactive gizmo controls to translate, rotate, and scale 3D objects.
 * @param {Struct} camera - Camera used for raycasting and projection.
 * @param {Struct} data - Optional initial settings.
 */
function UeTransformControls(camera, data = {}) : UeControls(data) constructor {
    // === BASE PROPERTIES ===
    self.camera = camera;             // Camera for raycasting calculations
    self.hoveredAxis = undefined;     // Currently hovered axis object
    self.selectedAxis = undefined;    // Currently selected axis object
    self.axis = undefined;            // Currently selected axis object name (X, Y, Z, etc..)
    self.dragging = false;            // Flag to indicate if dragging is in progress
    self.size = 1;                    // Gizmo visual size multiplier
    self.mode = "move";               // Current transform mode: "move", "rotate", or "scale"
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
    self._root = new UeMesh();         // Root object    
    self._plane = new UePlane();       // Plane used for intersection during dragging

    // Temporary vectors for dragging calculations
    self.pointStart = new UeVector3();
    self.pointEnd = new UeVector3();
    self.delta = new UeVector3();

    // Store object's initial transform at drag start
    self._positionStart = new UeVector3();
    self._rotationStart = new UeQuaternion();
    self._scaleStart = new UeVector3();
    self._positionStartWorld = new UeVector3();
    
    // === Build properties ===
    __xVec = new UeVector3(1, 0, 0);  // Unit vector for X axis
    __yVec = new UeVector3(0, 1, 0);  // Unit vector for Y axis
    __zVec = new UeVector3(0, 0, 1);  // Unit vector for Z axis

    self.onDrag = data[$ "onDrag"] ?? undefined;
    self.onDragEnd = data[$ "onDragEnd"] ?? undefined;
    
    // Base material for all gizmo components with transparency and depth testing disabled
    __matMesh = new UeMeshBasicMaterial({
        depthTest: false,
        depthWrite: false,
        transparent: true
    });
    
    /**
     * Computes the visual dimensions of the gizmo axes based on the current size setting.
     * These calculations determine the proportions of arrows, planes, and interactive elements.
     */
    function __computeAxesSize() {
        __axisLength = self.size * 0.8;          // Total length of each axis arrow
        __axisLengthHalf = __axisLength * .5;    // Half the axis length for positioning
        __axisLineWidth = .3;                    // Width/thickness of axis lines (reduced from 0.7)
        __axisOffset = 1;                        // Offset from origin for axis positioning
        __planeOpacity = 0.3;                    // Transparency level for plane handles
        __planeDepth = .2;                       // Thickness of plane interaction handles
        __planeSize = __axisLength * 0.3;        // Size of square plane handles
    }
    
    /**
     * Attaches the transform controls to a 3D object, enabling manipulation.
     * @param {UeObject3D} object - The target object to control.
     * @returns {self}
     */
    function attach(object) {
        gml_pragma("forceinline");
        self.object = object;
        
        // Ensure object's world matrix is up-to-date so gizmo uses correct world transforms
        if (object.updateWorldMatrix != undefined) {
            object.updateWorldMatrix(true, false);
        }

        // Auto-scale gizmo based on object's bounding sphere radius for better visual proportion
        var objectBox = object[$ "geometry"] != undefined ? object.geometry[$ "boundingBox"] : undefined;
        if (objectBox != undefined) {
            // Use bounding sphere radius for more accurate sizing
            // This gives us the distance from center to furthest corner
            var center = objectBox.getCenter();
            var size = objectBox.getSize();
            // Calculate radius as half the diagonal (distance from center to corner)
            var radius = size.length() * 0.5;
            self.size = radius * 0.5; // Use half the radius so gizmo doesn't overwhelm the object
        } else {
            // Default size if bounding box not available
            self.size = 8;
        }
        __computeAxesSize();
            
        build();
        updateGizmo();
        return self;
    }

    /**
     * Detaches the transform controls from the current object and hides the gizmo.
     * @returns {self}
     */
    function detach() {
        gml_pragma("forceinline");
        self.hoveredAxis = undefined;
        self.selectedAxis = undefined;
        self.axis = undefined;
        self.object = undefined;
        self.clearGizmo(self._root);
        return self;
    } 
    
    /**
     * Builds the gizmo visual lines for the axes according to current size and visibility.
     * Creates arrow geometries for each axis and plane handles for multi-axis manipulation.
     */
    function build() {
        gml_pragma("forceinline");
        clearGizmo(self._root);  // Remove previous gizmo geometry to avoid memory leaks
        self._gizmo = new UeMesh(); // Interactable gizmo container
        self._root.add(self._gizmo);
        var _baseLength = __axisLengthHalf + __axisOffset;
        
        // Create X axis line (Red)
        var geoX = new UeArrowGeometry(__axisLineWidth, __axisLength, 10, 0.25, { color: c_red });
        geoX.boundingBox = new UeBox3();
        geoX.computeBoundingBox();
        var meshX = new UeMesh(geoX, __matMesh.clone());
        meshX.name = "X";
        meshX.rotation.setFromAxisAngle(__zVec, 180);  // Rotate to point in positive X direction
        meshX.position.x = -_baseLength;
        meshX.raycastOrder = 0;  // Higher priority for raycasting (axes before planes)
        self._gizmo.add(meshX);
        
        // Create Y axis line (Blue)
        var geoY = new UeArrowGeometry(__axisLineWidth, __axisLength, 10, 0.25, { color: #2277B3 });
        geoY.boundingBox = new UeBox3();
        geoY.computeBoundingBox();
        var meshY = new UeMesh(geoY, __matMesh.clone());
        meshY.name = "Y";
        meshY.rotation.setFromAxisAngle(__zVec, 270);  // Rotate to point in positive Y direction
        meshY.position.y = -_baseLength;
        meshY.raycastOrder = 0;
        self._gizmo.add(meshY);
        
        // Create Z axis line (Green/Lime)
        var geoZ = new UeArrowGeometry(__axisLineWidth, __axisLength, 10, 0.25, { color: c_lime });
        geoZ.boundingBox = new UeBox3();
        geoZ.computeBoundingBox();
        var meshZ = new UeMesh(geoZ, __matMesh.clone());
        meshZ.name = "Z";
        meshZ.rotation.setFromAxisAngle(__yVec, -90);  // Rotate to point in positive Z direction
        meshZ.position.z = _baseLength;
        meshZ.raycastOrder = 0;
        self._gizmo.add(meshZ); 
        
        // === ADDITIONAL PLANES FOR COMBINED AXES ===
        // These planes allow dragging along two axes simultaneously
        
        // XZ plane (Blue) - allows movement along X and Z axes simultaneously
        var geoXZ = new UeBoxGeometry(__planeSize, __planeSize, __planeDepth, { color: #2277B3, alpha: __planeOpacity });
        geoXZ.boundingBox = new UeBox3();
        geoXZ.computeBoundingBox();
        var meshXZ = new UeMesh(geoXZ, __matMesh.clone());
        meshXZ.name = "XZ";
        meshXZ.raycastOrder = 1;  // Lower priority than individual axes
        self._gizmo.add(meshXZ);
        
        // YZ plane (Red) - allows movement along Y and Z axes simultaneously
        var geoYZ = new UeBoxGeometry(__planeSize, __planeSize, __planeDepth, { color: c_red, alpha: __planeOpacity });
        geoYZ.boundingBox = new UeBox3();
        geoYZ.computeBoundingBox();
        var meshYZ = new UeMesh(geoYZ, __matMesh.clone());
        meshYZ.name = "YZ";
        meshYZ.raycastOrder = 1;
        self._gizmo.add(meshYZ);
        
        // XY plane (Green) - allows movement along X and Y axes simultaneously
        var geoXY = new UeBoxGeometry(__planeSize, __planeSize, __planeDepth, { color: c_lime, alpha: __planeOpacity });
        geoXY.boundingBox = new UeBox3();
        geoXY.computeBoundingBox();
        var meshXY = new UeMesh(geoXY, __matMesh.clone());
        meshXY.name = "XY";
        meshXY.raycastOrder = 1;
        self._gizmo.add(meshXY);

        // === Add the center cube (XYZ) ===
        // Center cube allows free movement in all three axes simultaneously
        // Use axisLineWidth for proportional sizing instead of axisOffset to avoid oversized cubes
        var cubeSize = __axisLineWidth * 3;
        var geoBox = new UeBoxGeometry(cubeSize, cubeSize, cubeSize, { color: c_ltgray });
        geoBox.boundingBox = new UeBox3();
        geoBox.computeBoundingBox();
        var meshBox = new UeMesh(geoBox, __matMesh.clone());
        meshBox.name = "XYZ";
        meshBox.renderOrder = -1;   // Render behind other elements
        meshBox.raycastOrder = 2;   // Lowest raycast priority
        self._gizmo.add(meshBox);
    }
    
    /**
     * Updates the gizmo's position and orientation to match the attached object's transform and camera direction.
     * In world space, plane handles are positioned relative to camera to maintain visibility.
     * Automatically scales the gizmo based on distance from camera to maintain consistent apparent size.
     */
    function updateGizmo() {
        gml_pragma("forceinline");

        if (!self.object) return;

        // Ensure object's world matrix is updated so world-space queries are correct
        if (self.object.updateWorldMatrix != undefined) {
            self.object.updateWorldMatrix(true, false);
        }

        // Set gizmo root position to the object's world position
        var _wp = global.UE_DUMMY_VECTOR3;
        self.object.getWorldPosition(_wp);
        self._root.position.copy(_wp);

        // Calculate distance-based scale to maintain consistent apparent size (billboard-like behavior)
        var distance = self.camera.position.distanceTo(_wp);
        
        // Use a perspective-correct scaling formula
        // The scale should be proportional to distance to maintain constant apparent size
        var baseScale = 0.15;  // Base size multiplier - increased for better visibility
        var referenceDistance = 10;  // Reference distance for scaling
        
        // Calculate scale that makes gizmo appear same size regardless of distance
        // Scale increases with distance to compensate for perspective
        var distanceScale = (distance / referenceDistance) * baseScale;
        
        // Apply the distance-based scale to the entire gizmo
        self._root.scale.set(distanceScale, distanceScale, distanceScale);

        if (self.space == "local") {
            // In local space, gizmo rotates with the object's world rotation
            var _wq = global.UE_DUMMY_QUATERNION;
            self.object.getWorldQuaternion(_wq);
            self._root.rotation.copy(_wq);
        } else {
            // In world space, position plane handles based on camera direction for optimal visibility
            var camDir = self.camera.getWorldDirection();
            
            // XZ plane positioning - place on the side of the gizmo facing away from camera
            var meshXZ = self._gizmo.getObjectByName("XZ");    
            meshXZ.rotation.setFromAxisAngle(__xVec, 90);  // Orient plane horizontally
            meshXZ.position.x = (camDir.x < 0) ? -__planeSize : __planeSize;
            meshXZ.position.z = (camDir.z < 0) ? -__planeSize : __planeSize;
                 
            // YZ plane positioning
            var meshYZ = self._gizmo.getObjectByName("YZ");
            meshYZ.rotation.setFromAxisAngle(__yVec, 90);  // Orient plane vertically
            meshYZ.position.y = (camDir.y < 0) ? -__planeSize : __planeSize;
            meshYZ.position.z = (camDir.z < 0) ? -__planeSize : __planeSize;
            
            // XY plane positioning
            var meshXY = self._gizmo.getObjectByName("XY");
            meshXY.rotation.setFromAxisAngle(__zVec, 0);   // Keep plane facing camera
            meshXY.position.z = 0;
            meshXY.position.x = (camDir.x < 0) ? -__planeSize : __planeSize;
            meshXY.position.y = (camDir.y < 0) ? -__planeSize : __planeSize;
        }
    }

    /**
     * Updates the currently hovered/selected axis by performing raycast on gizmo lines.
     * Handles visual feedback (scaling and emissive highlighting) for interactive elements.
     */
    function updateInteraction() {
        gml_pragma("forceinline");
        
        self._raycaster.setFromCamera(self.camera);
        
        if (!self.dragging) {
            // Reset scale and emissive properties of all axes when not dragging
            for (var i = 0, l = array_length(self._gizmo.children); i < l; i++) {
                var child = self._gizmo.children[i];
                child.scale.set(1, 1, 1);
                child.material.uniforms.ueEmissive.value = [0, 0, 0];
            }
            
            // Perform raycasting to find intersected gizmo elements
            var intersects = self._raycaster.intersectObjects(self._gizmo.children, false, false);
            
            // Sort intersections by raycast priority first, then by distance
            // This ensures axes have priority over planes, and closer objects over farther ones
            array_sort(intersects, function(a, b) {
                var pa = a.object.raycastOrder;
                var pb = b.object.raycastOrder;
                
                if (pa != pb) {
                    return pb - pa;  // Higher raycastOrder = higher priority
                } else {
                    return a.distance - b.distance;  // Closer objects preferred when same priority
                }
            });
         
            if (array_length(intersects) > 0) {
                // Highlight the hovered axis with slight scaling
                var hovered = intersects[0].object;
                hovered.scale.set(1.05, 1.05, 1.05);
                self.hoveredAxis = hovered;
            } else {
                self.hoveredAxis = undefined;
            } 
        }
    }

    /**
     * Handles pointer down event to start dragging the selected axis if possible.
     * Sets up the drag plane based on the selected axis and camera orientation.
     */
    function onPointerDown() {
        gml_pragma("forceinline");
        if (self.hoveredAxis == undefined || self.dragging) return;

        self.dragging = true;
        self.selectedAxis = self.hoveredAxis;
        self.axis = self.selectedAxis.name;

        // Determine axis vector based on selected axis for mathematical calculations
        var axisVec = undefined;
        switch (self.axis) {
            case "X": axisVec = __xVec; break; 
            case "Y": axisVec = __yVec; break; 
            case "Z": axisVec = __zVec; break;
        }
        
        // Visual feedback: reset scale and add yellow emissive highlight
        self.selectedAxis.scale.set(1, 1, 1);
        self.selectedAxis.material.uniforms.ueEmissive.value = [1, 1, 0];

        // Transform axis vector to local space if needed
        if (self.space == "local" && (self.axis == "X" || self.axis == "Y" || self.axis == "Z")) {
            axisVec.applyQuaternion(self.object.rotation);
        }

        // Calculate the optimal plane for dragging based on camera direction and selected axis
        var camDir = self.camera.getWorldDirection(); 
        var _planeNormal = camDir;
        
        if (self.axis == "X" || self.axis == "Y" || self.axis == "Z") {
            // For single axis: create plane perpendicular to both camera direction and axis
            // Mathematical explanation: cross(camDir, axis) gives perpendicular vector,
            // then cross that with axis again to get plane normal that contains the axis
            _planeNormal = camDir.clone().cross(axisVec).cross(axisVec).normalize();
        } else if (self.axis == "XZ" || self.axis == "YZ" || self.axis == "XY") {
            // For plane handles: use the plane's natural normal
            switch (self.axis) {
                case "XY": _planeNormal = __zVec.clone(); break; 
                case "XZ": _planeNormal = __yVec.clone(); break;
                case "YZ": _planeNormal = __xVec.clone(); break;
            }
        
            // Transform normal to local space if needed
            if (self.space == "local") {
                _planeNormal.applyQuaternion(self.object.rotation);
            }
        
            // Flip plane normal if camera is looking from the wrong side
            // Dot product tells us if camera and normal are pointing in same direction
            var dot = camDir.dot(_planeNormal);
            if (dot > 0) {
                _planeNormal.negate();
            }
        }
        
        // Save the initial transform state before dragging begins for delta calculations
        self._positionStart.copy(self.object.position);
        self._rotationStart.copy(self.object.rotation);
        self._scaleStart.copy(self.object.scale);
        self.object.getWorldPosition(self._positionStartWorld);

        // Create the drag plane using the calculated normal and object position
        self._plane.setFromNormalAndCoplanarPoint(_planeNormal, self._positionStartWorld);

        // Calculate initial intersection point where mouse ray meets the drag plane
        var intersectionPoint = self._raycaster.ray.intersectPlane(self._plane);
        if (intersectionPoint == undefined) {
            // No intersection found; cancel dragging
            self.dragging = false;
            self.selectedAxis = undefined;
            self.axis = undefined;
            return;
        }
        self.pointStart.copy(intersectionPoint);
    }

    /**
     * Handles pointer move event to update dragging transform.
     * Calculates the drag delta and applies the appropriate transformation.
     */
    function onPointerMove() {
        gml_pragma("forceinline");
        if (!self.dragging) return;

        // Calculate current intersection with drag plane
        var intersectionPoint = self._raycaster.ray.intersectPlane(self._plane);
        if (intersectionPoint == undefined) return;

        self.pointEnd.copy(intersectionPoint);

        // Calculate drag delta vector between current and start points
        // This delta represents the movement in 3D space
        self.delta.copy(self.pointEnd).sub(self.pointStart);

        applyTransform();  // Apply transform change to object based on delta
        updateGizmo();     // Update gizmo transform to match object
        
        if (self.onDrag != undefined) self.onDrag();
    }

    /**
     * Handles pointer up event to stop dragging.
     */
    function onPointerUp() {
        gml_pragma("forceinline");

        if (self.dragging && self.onDragEnd != undefined) self.onDragEnd();

        self.dragging = false;
        self.selectedAxis = undefined;
        self.axis = undefined;
    }
    
    /**
     * Main update loop - handles mouse events and interaction updates.
     */
    function update() { 
        if (!self.object) return;
            
        // Update which axis is hovered based on mouse position
        updateInteraction();
        
        // Handle mouse events for dragging
        if (mouse_check_button_pressed(mb_left)) {
            onPointerDown();
        }
        if (mouse_check_button(mb_left)) {
            onPointerMove();
        }
        if (mouse_check_button_released(mb_left)) {
            onPointerUp();
        }
    }

    /**
     * Applies the transformation (move, rotate, scale) to the attached object based on drag delta.
     * Handles coordinate space conversion, axis constraints, snapping, and bounds clamping.
     */
    function applyTransform() {
        gml_pragma("forceinline");
        if (!self.object) return;
    
        if (self.mode == "move") {
            var worldDelta = self.delta.clone();
            
            // --- Constrain Delta to Axis ---
            if (self.space == "local") {
                // We need the object's world rotation to align the delta
                var objectWorldRot = new UeQuaternion();
                self.object.getWorldQuaternion(objectWorldRot);
                var invRot = objectWorldRot.clone().invert();
                
                // Transform world delta to "aligned" space
                worldDelta.applyQuaternion(invRot);
                
                // Apply constraints
                if (self.axis == "X") worldDelta.set(worldDelta.x, 0, 0);
                else if (self.axis == "Y") worldDelta.set(0, worldDelta.y, 0);
                else if (self.axis == "Z") worldDelta.set(0, 0, worldDelta.z);
                else if (self.axis == "XY") worldDelta.z = 0;
                else if (self.axis == "XZ") worldDelta.y = 0;
                else if (self.axis == "YZ") worldDelta.x = 0;
                
                // Transform back to world space
                worldDelta.applyQuaternion(objectWorldRot);
            } else {
                // World space constraints
                if (self.axis == "X") worldDelta.set(worldDelta.x, 0, 0);
                else if (self.axis == "Y") worldDelta.set(0, worldDelta.y, 0);
                else if (self.axis == "Z") worldDelta.set(0, 0, worldDelta.z);
                else if (self.axis == "XY") worldDelta.z = 0;
                else if (self.axis == "XZ") worldDelta.y = 0;
                else if (self.axis == "YZ") worldDelta.x = 0;
            }

            // Calculate Target World Position
            var targetWorldPos = self._positionStartWorld.clone().add(worldDelta);
            
            // Convert to Parent Local Space
            if (self.object.parent != undefined) {
                var parentInv = new UeMatrix4().copy(self.object.parent.matrixWorld).invert();
                targetWorldPos.applyMatrix4(parentInv);
            }
            
            // Apply to object (targetWorldPos is now the new local position)
            var newPos = targetWorldPos;
            
            // Apply snapping (on local position for consistency with previous behavior, or we could snap worldDelta)
            // For now, keeping local snapping as it maps to the grid usually expected in local editing
            if (self.translationSnap != undefined) {
                if (self.axis == "X") newPos.x = round(newPos.x / self.translationSnap) * self.translationSnap;
                else if (self.axis == "Y") newPos.y = round(newPos.y / self.translationSnap) * self.translationSnap;
                else if (self.axis == "Z") newPos.z = round(newPos.z / self.translationSnap) * self.translationSnap;
                else if (self.axis == "XYZ") {
                    newPos.x = round(newPos.x / self.translationSnap) * self.translationSnap;
                    newPos.y = round(newPos.y / self.translationSnap) * self.translationSnap;
                    newPos.z = round(newPos.z / self.translationSnap) * self.translationSnap;
                }
            }
    
            // Clamp to configured limits
            newPos.x = clamp(newPos.x, self.minX, self.maxX);
            newPos.y = clamp(newPos.y, self.minY, self.maxY);
            newPos.z = clamp(newPos.z, self.minZ, self.maxZ);
    
            // Apply the final position change to the object
            self.object.position.copy(newPos);
        }
        
        // Note: Rotation and scaling modes are commented out but would follow similar patterns:
        // - Rotation: Convert drag delta to angular rotation around the selected axis
        // - Scaling: Convert drag delta to scale factors with proper sensitivity
        
        //else if (self.mode == "rotate") {
            //var axisVec = new UeVector3();
            //if (self.axis == "X") axisVec.set(1,0,0);
            //else if (self.axis == "Y") axisVec.set(0,1,0);
            //else if (self.axis == "Z") axisVec.set(0,0,1);
            //else return; // no axis selected
    //
            //if (self.space == "local") {
                //axisVec.applyQuaternion(self.object.rotation);
            //}
    //
            //// Use delta projection for rotation sensitivity
            //var deltaLength = self.delta.length();
            //var angle = deltaLength * 0.01; // Sensitivity factor for rotation
            //
            //if (self.rotationSnap != undefined) {
                //angle = round(angle / self.rotationSnap) * self.rotationSnap;
            //}
    //
            //// Create quaternion for rotation around axisVec by angle
            //var q = new UeQuaternion();
            //q.setFromAxisAngle(axisVec, angle);
    //
            //self.object.rotation.multiplyQuaternions(q, self._rotationStart);
        //}
        //else if (self.mode == "scale") {
            //var newScale = self._scaleStart.clone();
            //var delta = self.delta.clone();
    //
            //var scaleFactor = 1.0 + (delta.length() * 0.01); // Sensitivity factor
            //
            //if (self.space == "local") {
                //var invRotation = self.object.rotation.clone().invert();
                //delta.applyQuaternion(invRotation);
            //}
    //
            //// Apply scale factor only to the selected axis
            //if (self.axis == "X") newScale.x = self._scaleStart.x * scaleFactor;
            //else if (self.axis == "Y") newScale.y = self._scaleStart.y * scaleFactor;
            //else if (self.axis == "Z") newScale.z = self._scaleStart.z * scaleFactor;
    //
            //// Snap scale if enabled
            //if (self.scaleSnap != undefined) {
                //if (self.axis == "X") newScale.x = round(newScale.x / self.scaleSnap) * self.scaleSnap;
                //else if (self.axis == "Y") newScale.y = round(newScale.y / self.scaleSnap) * self.scaleSnap;
                //else if (self.axis == "Z") newScale.z = round(newScale.z / self.scaleSnap) * self.scaleSnap;
            //}
    //
            //// Clamp scale to configured limits (prevent negative scaling)
            //newScale.x = clamp(newScale.x, max(0.01, self.minX), self.maxX);
            //newScale.y = clamp(newScale.y, max(0.01, self.minY), self.maxY);
            //newScale.z = clamp(newScale.z, max(0.01, self.minZ), self.maxZ);
    //
            //self.object.scale.copy(newScale);
        //}
    } 
    
    // === API METHODS ===

    /**
     * Returns the root node of the gizmo for attaching to the scene.
     * @returns {Struct}
     */
    function getHelper() { 
        gml_pragma("forceinline");
        return self._root; 
    }
    
    /**
     * Returns the raycaster instance used for picking.
     * @returns {Struct}
     */
    function getRaycaster() {
        gml_pragma("forceinline"); 
        return self._raycaster; 
    }
    
    /**
     * Sets the transform mode.
     * @param {string} mode - "move", "rotate", or "scale"
     * @returns {self}
     */
    function setMode(mode) {
        gml_pragma("forceinline"); 
        self.mode = mode; 
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
        build();  // Rebuild gizmo geometry with new size
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
        updateGizmo(); // Update gizmo to match new space setting
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
        updateGizmo();
        return self;
    }
    
    /**
     * Recursively clears and disposes of the gizmo geometry and children.
     * Important for memory management to prevent geometry leaks.
     */
    function clearGizmo(node) {
        gml_pragma("forceinline");
         
        var _children = node.children;
        var count = array_length(_children);
        
        // Iterate backwards to safely remove children while iterating
        for (var i = count - 1; i >= 0; i--) {
            var child = _children[i];
            var geometry = child[$ "geometry"];
            if (geometry != undefined) {
                child.geometry.dispose();  // Dispose geometry to free GPU memory
            }
            clearGizmo(child);  // Recursively clear child nodes
        }
        
        node.clear();  // Remove all children from node
    }
    
    return self;
}
