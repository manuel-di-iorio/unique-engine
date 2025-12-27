/**
 * UeTransformControls constructor
 * Provides interactive gizmo controls to translate, rotate, and scale 3D objects.
 * @param {Struct} camera - Camera used for raycasting and projection.
 * @param {Struct} data - Optional initial settings.
 */
function UeTransformControls(camera, data = {}): UeControls(data) constructor {
    // === BASE PROPERTIES ===
    self.camera = camera;             // Camera for raycasting calculations
    self.hoveredAxis = undefined;     // Currently hovered axis object
    self.selectedAxis = undefined;    // Currently selected axis object
    self.axis = undefined;            // Currently selected axis object name (X, Y, Z, etc..)
    self.dragging = false;            // Flag to indicate if dragging is in progress
    self.size = 1.3;                  // Gizmo visual size multiplier
    self.mode = "view";               // Current transform mode: "view", "move", "rotate", or "scale"
    self.space = "world";             // Transform space: "world" or "local"

    // === BOUNDS AND SNAP SETTINGS ===
    self.minX = -infinity; self.minY = -infinity; self.minZ = -infinity;
    self.maxX = infinity; self.maxY = infinity; self.maxZ = infinity;

    self.translationSnap = undefined; // Increment step for translation snapping
    self.rotationSnap = undefined;    // Increment step for rotation snapping (radians)
    self.scaleSnap = undefined;       // Increment step for scale snapping

    self.gizmoMinScale = undefined;   // Minimum scale for the gizmo
    self.gizmoMaxScale = undefined;   // Maximum scale for the gizmo

    // === AXIS VISIBILITY ===
    self.showX = true;                // Show X axis gizmo line
    self.showY = true;                // Show Y axis gizmo line
    self.showZ = true;                // Show Z axis gizmo line

    // === INTERNAL HELPERS ===
    self._raycaster = new UeRaycaster();  // Raycaster for mouse picking
    self._raycasterRotate = new UeRaycaster();  // Raycaster for mouse picking
    self._raycasterRotate.params.Mesh.precise = true;
    self._root = new UeMesh();         // Root object    
    self._plane = plane_create();       // Plane used for intersection during dragging

    // Temporary vectors for dragging calculations
    self.pointStart = vec3_create();
    self.pointEnd = vec3_create();
    self.pointPrevious = vec3_create();  // Track previous point for incremental rotation
    self._rotationAngle = 0; // Accumulates total rotation angle during drag
    self.delta = vec3_create();

    // Store object's initial transform at drag start
    self._positionStart = vec3_create();
    self._rotationStart = quat_create();
    self._scaleStart = vec3_create();
    self._positionStartWorld = vec3_create();

    // === Build properties ===
    __xVec = vec3_create(1, 0, 0);  // Unit vector for X axis
    __yVec = vec3_create(0, 1, 0);  // Unit vector for Y axis
    __zVec = vec3_create(0, 0, 1);  // Unit vector for Z axis

    self.onDrag = data[$ "onDrag"] ?? undefined;
    self.onDragEnd = data[$ "onDragEnd"] ?? undefined;

    // Base material for all gizmo components with transparency and depth testing disabled
    __matMesh = new UeMeshStandardMaterial({
        depthTest: false,
        depthWrite: false,
        transparent: true,
        shader: sh_ue_gizmo
    });

    // Ensure ueEmissive uniform exists for highlighting (override if needed)
    if (__matMesh.uniforms[$ "ueEmissive"] == undefined) {
        __matMesh.uniforms.ueEmissive = { type: UE_UNIFORM_TYPE.ARRAY, value: [0, 0, 0] };
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

        /**
         * Computes the visual dimensions of the gizmo axes based on the current size setting.
         * These calculations determine the proportions of arrows, planes, and interactive elements.
         */
        __axisLength = self.size * 10;           // Total length of each axis arrow
        __axisLengthHalf = __axisLength * .5;    // Half the axis length for positioning
        __axisLineWidth = self.size * 0.4;       // Width/thickness of axis lines
        __axisOffset = self.size * 1.5;          // Offset from origin for axis positioning
        __planeOpacity = 0.3;                    // Transparency level for plane handles
        __planeDepth = self.size * 0.2;          // Thickness of plane interaction handles
        __planeSize = __axisLength * 0.35;       // Size of square plane handles

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
     * Creates different geometries based on the current mode (move or rotate).
     */
    function build() {
        gml_pragma("forceinline");
        clearGizmo(self._root);  // Remove previous gizmo geometry to avoid memory leaks
        self._gizmo = new UeMesh(); // Interactable gizmo container
        self._root.add(self._gizmo);

        if (self.mode == "move") {
            buildTranslateModeGizmo();
        } else if (self.mode == "rotate") {
            buildRotateModeGizmo();
        } else if (self.mode == "scale") {
            buildScaleModeGizmo();
        }
        return self;
    }

    /**
     * Builds the translate (move) mode gizmo with arrows and plane handles.
     */
    function buildTranslateModeGizmo() {
        gml_pragma("forceinline");
        var _baseLength = __axisLengthHalf + __axisOffset;

        // Create X axis line (Red)
        var geoX = new UeArrowGeometry(__axisLineWidth, __axisLength, 10, 0.25, { color: c_red });
        geoX.computeBoundingBox();
        var meshX = new UeMesh(geoX, __matMesh.clone());
        meshX.name = "X";
        quat_set_from_axis_angle(meshX.rotation, __zVec, 180);  // Rotate to point in positive X direction
        meshX.position[VEC3.x] = -_baseLength;
        meshX.raycastOrder = 0;  // Higher priority for raycasting (axes before planes)
        self._gizmo.add(meshX);

        // Create Y axis line (Blue)
        var geoY = new UeArrowGeometry(__axisLineWidth, __axisLength, 10, 0.25, { color: #2277B3 });
        geoY.computeBoundingBox();
        var meshY = new UeMesh(geoY, __matMesh.clone());
        meshY.name = "Y";
        quat_set_from_axis_angle(meshY.rotation, __zVec, 270);  // Rotate to point in positive Y direction
        meshY.position[VEC3.y] = -_baseLength;
        meshY.raycastOrder = 0;
        self._gizmo.add(meshY);

        // Create Z axis line (Green/Lime)
        var geoZ = new UeArrowGeometry(__axisLineWidth, __axisLength, 10, 0.25, { color: c_lime });
        geoZ.computeBoundingBox();
        var meshZ = new UeMesh(geoZ, __matMesh.clone());
        meshZ.name = "Z";
        quat_set_from_axis_angle(meshZ.rotation, __yVec, -90);  // Rotate to point in positive Z direction
        meshZ.position[VEC3.z] = _baseLength;
        meshZ.raycastOrder = 0;
        self._gizmo.add(meshZ);

        // === ADDITIONAL PLANES FOR COMBINED AXES ===
        // These planes allow dragging along two axes simultaneously

        // XZ plane (Blue) - allows movement along X and Z axes simultaneously
        var geoXZ = new UeBoxGeometry(__planeSize, __planeSize, __planeDepth, { color: #2277B3, alpha: __planeOpacity });
        geoXZ.computeBoundingBox();
        var meshXZ = new UeMesh(geoXZ, __matMesh.clone());
        meshXZ.name = "XZ";
        meshXZ.raycastOrder = 1;  // Lower priority than individual axes
        self._gizmo.add(meshXZ);

        // YZ plane (Red) - allows movement along Y and Z axes simultaneously
        var geoYZ = new UeBoxGeometry(__planeSize, __planeSize, __planeDepth, { color: c_red, alpha: __planeOpacity });
        geoYZ.computeBoundingBox();
        var meshYZ = new UeMesh(geoYZ, __matMesh.clone());
        meshYZ.name = "YZ";
        meshYZ.raycastOrder = 1;
        self._gizmo.add(meshYZ);

        // XY plane (Green) - allows movement along X and Y axes simultaneously
        var geoXY = new UeBoxGeometry(__planeSize, __planeSize, __planeDepth, { color: c_lime, alpha: __planeOpacity });
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
        geoBox.computeBoundingBox();
        var meshBox = new UeMesh(geoBox, __matMesh.clone());
        meshBox.name = "XYZ";
        meshBox.renderOrder = -1;   // Render behind other elements
        meshBox.raycastOrder = 2;   // Lowest raycast priority
        self._gizmo.add(meshBox);
    }

    /**
     * Builds the rotate mode gizmo with torus rings for each axis.
     */
    function buildRotateModeGizmo() {
        gml_pragma("forceinline");
        var _torusRadius = __axisLength * 1;  // Radius of the rotation rings
        var _torusThickness = __axisLineWidth * 0.5; // Thickness of the rings
        var _radialSegments = 4;
        var _tubularSegments = 22;

        // Torus lies on XY plane usually, extending from -(R+r) to +(R+r)
        var limit = _torusRadius + _torusThickness;
        var zLimit = _torusThickness;
        var torusBoxMin = vec3_create(-limit, -limit, -zLimit);
        var torusBoxMax = vec3_create(limit, limit, zLimit);

        // --- Create X AXIS (Red, YZ plane) ---
        // Front Geometry (0 to 180 degrees) - Opaque
        var geoFrontX = new UeTorusGeometry(_torusRadius, _torusThickness, {
            radialSegments: _radialSegments, tubularSegments: _tubularSegments, color: c_red,
            arc: pi, arcOffset: 0, alpha: 1.0
        });
        geoFrontX.boundingBox = [torusBoxMin[0], torusBoxMin[1], torusBoxMin[2], torusBoxMax[0], torusBoxMax[1], torusBoxMax[2]];

        // Back Geometry (180 to 360 degrees) - Semi-transparent
        var geoBackX = new UeTorusGeometry(_torusRadius, _torusThickness, {
            radialSegments: _radialSegments, tubularSegments: _tubularSegments, color: c_red,
            arc: pi, arcOffset: pi, alpha: 0.2
        });
        geoBackX.boundingBox = [torusBoxMin[0], torusBoxMin[1], torusBoxMin[2], torusBoxMax[0], torusBoxMax[1], torusBoxMax[2]];

        // Back Geometry Opaque (for selection state)
        var geoBackOpaqueX = new UeTorusGeometry(_torusRadius, _torusThickness, {
            radialSegments: _radialSegments, tubularSegments: _tubularSegments, color: c_red,
            arc: pi, arcOffset: pi, alpha: 1.0
        });
        geoBackOpaqueX.boundingBox = [torusBoxMin[0], torusBoxMin[1], torusBoxMin[2], torusBoxMax[0], torusBoxMax[1], torusBoxMax[2]];

        var meshFrontX = new UeMesh(geoFrontX, __matMesh.clone());
        meshFrontX.name = "X";
        quat_set_from_axis_angle(meshFrontX.rotation, __yVec, 90);
        meshFrontX.raycastOrder = 0;

        var meshBackX = new UeMesh(geoBackX, __matMesh.clone());
        meshBackX.name = "X";
        quat_copy(meshBackX.rotation, meshFrontX.rotation);
        meshBackX.raycastOrder = 0;
        meshBackX.material.opacity = 0.2; // Explicitly set opacity for material

        var staticRotX = quat_clone(meshFrontX.rotation);

        meshFrontX.userData = {
            isRotationGizmo: true, planeNormal: vec3_clone(__xVec), staticRotation: staticRotX,
            geoBack: geoBackX, geoBackOpaque: geoBackX, partner: meshBackX, type: "front"
        };
        meshBackX.userData = {
            isRotationGizmo: true, planeNormal: vec3_clone(__xVec), staticRotation: staticRotX,
            partner: meshFrontX, type: "back"
        };

        self._gizmo.add(meshFrontX);
        self._gizmo.add(meshBackX);

        // --- Create Y AXIS (Blue, XZ plane) ---
        var geoFrontY = new UeTorusGeometry(_torusRadius, _torusThickness, {
            radialSegments: _radialSegments, tubularSegments: _tubularSegments, color: #2277B3,
            arc: pi, arcOffset: 0, alpha: 1.0
        });
        geoFrontY.boundingBox = [torusBoxMin[0], torusBoxMin[1], torusBoxMin[2], torusBoxMax[0], torusBoxMax[1], torusBoxMax[2]];

        var geoBackY = new UeTorusGeometry(_torusRadius, _torusThickness, {
            radialSegments: _radialSegments, tubularSegments: _tubularSegments, color: #2277B3,
            arc: pi, arcOffset: pi, alpha: 0.2
        });
        geoBackY.boundingBox = [torusBoxMin[0], torusBoxMin[1], torusBoxMin[2], torusBoxMax[0], torusBoxMax[1], torusBoxMax[2]];

        var geoBackOpaqueY = new UeTorusGeometry(_torusRadius, _torusThickness, {
            radialSegments: _radialSegments, tubularSegments: _tubularSegments, color: #2277B3,
            arc: pi, arcOffset: pi, alpha: 1.0
        });
        geoBackOpaqueY.boundingBox = [torusBoxMin[0], torusBoxMin[1], torusBoxMin[2], torusBoxMax[0], torusBoxMax[1], torusBoxMax[2]];

        var meshFrontY = new UeMesh(geoFrontY, __matMesh.clone());
        meshFrontY.name = "Y";
        quat_set_from_axis_angle(meshFrontY.rotation, __xVec, 90);
        meshFrontY.raycastOrder = 0;

        var meshBackY = new UeMesh(geoBackY, __matMesh.clone());
        meshBackY.name = "Y";
        quat_copy(meshBackY.rotation, meshFrontY.rotation);
        meshBackY.raycastOrder = 0;
        meshBackY.material.opacity = 0.2; // Explicit opacity

        var staticRotY = quat_clone(meshFrontY.rotation);

        meshFrontY.userData = {
            isRotationGizmo: true, planeNormal: vec3_clone(__yVec), staticRotation: staticRotY,
            geoBack: geoBackY, geoBackOpaque: geoBackOpaqueY, partner: meshBackY, type: "front"
        };
        meshBackY.userData = {
            isRotationGizmo: true, planeNormal: vec3_clone(__yVec), staticRotation: staticRotY,
            partner: meshFrontY, type: "back"
        };

        self._gizmo.add(meshFrontY);
        self._gizmo.add(meshBackY);

        // --- Create Z AXIS (Green, XY plane) ---
        var geoFrontZ = new UeTorusGeometry(_torusRadius, _torusThickness, {
            radialSegments: _radialSegments, tubularSegments: _tubularSegments, color: c_lime,
            arc: pi, arcOffset: 0, alpha: 1.0
        });
        geoFrontZ.boundingBox = [torusBoxMin[0], torusBoxMin[1], torusBoxMin[2], torusBoxMax[0], torusBoxMax[1], torusBoxMax[2]];

        var geoBackZ = new UeTorusGeometry(_torusRadius, _torusThickness, {
            radialSegments: _radialSegments, tubularSegments: _tubularSegments, color: c_lime,
            arc: pi, arcOffset: pi, alpha: 0.2
        });
        geoBackZ.boundingBox = [torusBoxMin[0], torusBoxMin[1], torusBoxMin[2], torusBoxMax[0], torusBoxMax[1], torusBoxMax[2]];

        var geoBackOpaqueZ = new UeTorusGeometry(_torusRadius, _torusThickness, {
            radialSegments: _radialSegments, tubularSegments: _tubularSegments, color: c_lime,
            arc: pi, arcOffset: pi, alpha: 1.0
        });
        geoBackOpaqueZ.boundingBox = [torusBoxMin[0], torusBoxMin[1], torusBoxMin[2], torusBoxMax[0], torusBoxMax[1], torusBoxMax[2]];

        var meshFrontZ = new UeMesh(geoFrontZ, __matMesh.clone());
        meshFrontZ.name = "Z";
        meshFrontZ.raycastOrder = 0;

        var meshBackZ = new UeMesh(geoBackZ, __matMesh.clone());
        meshBackZ.name = "Z";
        meshBackZ.raycastOrder = 0;
        meshBackZ.material.opacity = 0.2; // Explicit opacity

        var staticRotZ = quat_create(); // Identity
        meshFrontZ.userData = {
            isRotationGizmo: true, planeNormal: vec3_clone(__zVec), staticRotation: staticRotZ,
            geoBack: geoBackZ, geoBackOpaque: geoBackOpaqueZ, partner: meshBackZ, type: "front"
        };
        meshBackZ.userData = {
            isRotationGizmo: true, planeNormal: vec3_clone(__zVec), staticRotation: staticRotZ,
            partner: meshFrontZ, type: "back"
        };
        self._gizmo.add(meshFrontZ);
        self._gizmo.add(meshBackZ);

        // Create Screen Space Rotation ring (Yellow) - always faces camera ('E')
        var eRadius = _torusRadius * 1.4;
        var eLimit = eRadius + _torusThickness;
        var geoE = new UeTorusGeometry(eRadius, _torusThickness, {
            radialSegments: _radialSegments,
            tubularSegments: _tubularSegments,
            color: #fafadd
        });
        geoE.boundingBox = [ -eLimit, -eLimit, -zLimit, eLimit, eLimit, zLimit ];
        var meshE = new UeMesh(geoE, __matMesh.clone());
        meshE.name = "E";
        meshE.raycastOrder = 0;
        self._gizmo.add(meshE);
    }

    /**
     * Builds the scale mode gizmo with box handles for each axis.
     */
    function buildScaleModeGizmo() {
        gml_pragma("forceinline");

        var _handleSize = __axisLineWidth * 4;
        var lineLen = __axisLength;

        // Create X axis (Red)
        // Cylinder X -> X: No rotation
        var meshX = __createMergedScaleAxis("X", c_red, undefined, 0, vec3_create(lineLen / 2, 0, 0), vec3_create(lineLen, 0, 0), _handleSize, lineLen);

        // Create Y axis (Blue)
        // Cylinder X -> Y: Rotate Z 90
        var meshY = __createMergedScaleAxis("Y", #2277B3, __zVec, 90, vec3_create(0, lineLen / 2, 0), vec3_create(0, lineLen, 0), _handleSize, lineLen);

        // Create Z axis (Green)
        // Cylinder X -> Z: Rotate Y -90
        var meshZ = __createMergedScaleAxis("Z", c_lime, __yVec, -90, vec3_create(0, 0, lineLen / 2), vec3_create(0, 0, lineLen), _handleSize, lineLen);

        // XZ plane (Blue)
        var geoXZ = new UeBoxGeometry(__planeSize, __planeSize, __planeDepth, { color: #2277B3, alpha: __planeOpacity });
        geoXZ.computeBoundingBox();
        var meshXZ = new UeMesh(geoXZ, __matMesh.clone());
        meshXZ.name = "XZ";
        meshXZ.raycastOrder = 1;
        self._gizmo.add(meshXZ);

        // YZ plane (Red)
        var geoYZ = new UeBoxGeometry(__planeSize, __planeSize, __planeDepth, { color: c_red, alpha: __planeOpacity });
        geoYZ.computeBoundingBox();
        var meshYZ = new UeMesh(geoYZ, __matMesh.clone());
        meshYZ.name = "YZ";
        meshYZ.raycastOrder = 1;
        self._gizmo.add(meshYZ);

        // XY plane (Green)
        var geoXY = new UeBoxGeometry(__planeSize, __planeSize, __planeDepth, { color: c_lime, alpha: __planeOpacity });
        geoXY.computeBoundingBox();
        var meshXY = new UeMesh(geoXY, __matMesh.clone());
        meshXY.name = "XY";
        meshXY.raycastOrder = 1;
        self._gizmo.add(meshXY);

        // Uniform Scale (XYZ) - Center Cube
        var cubeSize = _handleSize * 1.5;
        var geoBox = new UeBoxGeometry(cubeSize, cubeSize, cubeSize, { color: c_ltgray });
        geoBox.computeBoundingBox();
        var meshBox = new UeMesh(geoBox, __matMesh.clone());
        meshBox.name = "XYZ";
        meshBox.renderOrder = -1;
        meshBox.raycastOrder = 2;
        self._gizmo.add(meshBox);
    }

    /**
     * Internal helper to create merged axis geometry for scale mode.
     * @param {string} name
     * @param {color} color
     * @param {Vector3} rotationAxis
     * @param {number} rotationAngle
     * @param {Vector3} shaftPos
     * @param {Vector3} handlePos
     * @param {number} handleSize
     * @param {number} lineLen
     */
    function __createMergedScaleAxis(name, color, rotationAxis, rotationAngle, shaftPos, handlePos, handleSize, lineLen) {
        var mat = mat4_create();
        var q = quat_create();
        var s = vec3_create(1, 1, 1);

        // Shaft Geometry
        var geoShaft = new UeCylinderGeometry(__axisLineWidth, __axisLineWidth, lineLen, { radialSegments: 4, color: color });

        // Shaft Transform
        if (rotationAxis != undefined) {
             quat_set_from_axis_angle(q, rotationAxis, rotationAngle);
             mat4_make_rotation_from_quaternion(mat, q);
        } else {
            quat_set(q, 0, 0, 0, 1); // Identity
            mat4_identity(mat);
        }
        // Apply position (shaftPos is already an array from vec3_create)
        mat4_set_position(mat, shaftPos[0], shaftPos[1], shaftPos[2]); 
        geoShaft.applyMatrix(mat);

        // Handle Geometry
        var geoHandle = new UeBoxGeometry(handleSize, handleSize, handleSize, { color: color });

        // Handle Transform
        quat_set(q, 0, 0, 0, 1); // Axis aligned box, so identity rotation
        mat4_compose(mat, handlePos, q, s); // Compose with handle position, identity rotation, and unit scale
        geoHandle.applyMatrix(mat);

        // Merge
        var geoMerged = new UeGeometry().merge([geoShaft, geoHandle]);
        geoMerged.computeBoundingBox();

         // Cleanup intermediate geometries
         geoShaft.dispose();
         geoHandle.dispose();

         // Create Mesh
         var mesh = new UeMesh(geoMerged, __matMesh.clone());
         mesh.name = name;
         mesh.raycastOrder = 0;
         self._gizmo.add(mesh);

         return mesh;
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
        var _wp = global.UE_VEC3_TEMP0;
        self.object.getWorldPosition(_wp);
        vec3_copy(self._root.position, _wp);

        // Calculate distance-based scale to maintain consistent apparent size (billboard-like behavior)
        var distance = vec3_distance_to(self.camera.position, _wp);

        // Scale formula: distance * constant
        var currentScale = distance * 0.008;

        // Clamp scale if limits are defined
        if (self.gizmoMinScale != undefined) currentScale = max(currentScale, self.gizmoMinScale);
        if (self.gizmoMaxScale != undefined) currentScale = min(currentScale, self.gizmoMaxScale);

        // Apply the distance-based scale to the entire gizmo
        vec3_set(self._root.scale, currentScale, currentScale, currentScale);

        if (self.space == "local") {
            // In local space, gizmo rotates with the object's world rotation
            var _wq = global.UE_DUMMY_QUATERNION;
            self.object.getWorldQuaternion(_wq);
            quat_copy(self._root.rotation, _wq);
        } else {
            // In world space mode
            if (self.mode == "move" || self.mode == "scale") {
                // Position plane handles based on camera direction for optimal visibility
                var camDir = global.UE_VEC3_TEMP0;
                self.camera.getWorldDirection(camDir);

                // XZ plane positioning - place on the side of the gizmo facing away from camera
                var meshXZ = self._gizmo.getObjectByName("XZ");
                quat_set_from_axis_angle(meshXZ.rotation, __xVec, 90);  // Orient plane horizontally
                meshXZ.position[VEC3.x] = (camDir[VEC3.x] < 0) ? -__planeSize : __planeSize;
                meshXZ.position[VEC3.z] = (camDir[VEC3.z] < 0) ? -__planeSize : __planeSize;

                // YZ plane positioning
                var meshYZ = self._gizmo.getObjectByName("YZ");
                quat_set_from_axis_angle(meshYZ.rotation, __yVec, 90);  // Orient plane vertically
                meshYZ.position[VEC3.y] = (camDir[VEC3.y] < 0) ? -__planeSize : __planeSize;
                meshYZ.position[VEC3.z] = (camDir[VEC3.z] < 0) ? -__planeSize : __planeSize;

                // XY plane positioning
                var meshXY = self._gizmo.getObjectByName("XY");
                quat_set_from_axis_angle(meshXY.rotation, __zVec, 0);   // Keep plane facing camera
                meshXY.position[VEC3.z] = 0;
                meshXY.position[VEC3.x] = (camDir[VEC3.x] < 0) ? -__planeSize : __planeSize;
                meshXY.position[VEC3.y] = (camDir[VEC3.y] < 0) ? -__planeSize : __planeSize;
            } else if (self.mode == "rotate") {
                // For rotate mode in world space, update E axis to always face camera
                var meshE = self._gizmo.getObjectByName("E");
                if (meshE != undefined) {
                    // Calculate direction from gizmo to camera
                    var dirToCamera = vec3_sub_vectors(global.UE_VEC3_TEMP0, self.camera.position, self._root.position);
                    vec3_normalize(dirToCamera);

                    // Orient the E axis (torus) to face the camera
                    // The torus normal (Z axis by default) should align with the camera direction
                    // Use setFromUnitVectors to directly align Z axis with camera direction
                    var quaternion = global.UE_QUAT_TEMP0;
                    var defaultNormal = vec3_set(global.UE_VEC3_TEMP1, 0, 0, 1); // Torus default normal (Z-up)
                    quat_set_from_unit_vectors(quaternion, defaultNormal, dirToCamera);
                    quat_copy(meshE.rotation, quaternion);
                }

                // Update dynamic arcs for X, Y, Z axes to show only front-facing half
                var dirToCamera = vec3_sub_vectors(global.UE_VEC3_TEMP0, self.camera.position, self._root.position);
                vec3_normalize(dirToCamera);

                // Update each axis with dynamic rotation
                for (var i = 0; i < array_length(self._gizmo.children); i++) {
                    var mesh = self._gizmo.children[i];
                    var userData = mesh.userData;

                    // Skip if this mesh isn't a rotation gizmo part
                    if (userData == undefined || !userData[$ "isRotationGizmo"]) continue;

                    // Calculate rotation angle based on camera position
                    // Project camera direction onto the torus plane
                    var planeNormal = userData.planeNormal;
                    var camDirProjected = vec3_clone(dirToCamera);

                    // Remove the component along the plane normal (project onto plane)
                    var dotProduct = vec3_dot(camDirProjected, planeNormal);
                    vec3_add_scaled_vector(camDirProjected, planeNormal, -dotProduct);
                    vec3_normalize(camDirProjected);

                    // Calculate angle in the plane relative to the torus local space
                    // Since all tori are created in XY plane (normal Z) and then rotated,
                    // we need to find the angle in the local XY plane
                    // But our planeNormal and camDirProjected are in WORLD/GIZMO space.
                    // We need to transform the projected camera vector into the mesh's LOCAL space (before spin)
                    // The static rotation transforms Z -> planeNormal.
                    // So we can apply inverse static rotation to camDirProjected.

                    var localCamDir = vec3_clone(camDirProjected);
                    var invStatic = quat_clone(userData.staticRotation);
                    quat_invert(invStatic);
                    vec3_apply_quaternion(localCamDir, invStatic);

                    // Now localCamDir is in the XY plane of the torus geometry (Z=0)
                    // Calculate angle relative to local Y axis (because our arc is centered at pi/2 which is Y)
                    // Actually, our arc is 0..pi. Center is pi/2 (+Y).
                    // We want the center of the arc (+Y) to point at localCamDir.
                    // So we want to rotate Z so that +Y becomes localCamDir.

                    var targetAngle = arctan2(localCamDir.y, localCamDir.x);

                    // We want to rotate the mesh such that its +Y axis points to targetAngle
                    // Current +Y is at pi/2.
                    // Rotation needed = targetAngle - pi/2
                    var spinAngle = targetAngle - (pi / 2);

                    // Create spin rotation around partial Z axis
                    var spinQ = quat_create();
                    quat_set_from_axis_angle(spinQ, __zVec, spinAngle);

                    // Apply: Total = Static * Spin
                    var totalQ = userData.staticRotation.clone().multiply(spinQ);
                    mesh.rotation.copy(totalQ);
                }
            }
        }
    }

    /**
     * Updates the currently hovered/selected axis by performing raycast on gizmo lines.
     * Handles visual feedback (scaling and emissive highlighting) for interactive elements.
     */
    function updateInteraction() {
        gml_pragma("forceinline");

        var _raycasterInstance = self._raycaster;
        if (self.mode == "rotate") {
            _raycasterInstance = self._raycasterRotate;
        }
        _raycasterInstance.setFromCamera(self.camera);

        if (!self.dragging) {
            // Reset scale and emissive properties of all axes when not dragging
            // Also reset geometry state
            for (var i = 0, l = array_length(self._gizmo.children); i < l; i++) {
                var child = self._gizmo.children[i];
                vec3_set(child.scale, 1, 1, 1);

                // Default reset logic
                child.material.uniforms.ueEmissive.value = [0, 0, 0];
                if (child.userData != undefined && child.userData[$ "isRotationGizmo"]) {
                    // Reset to semi-transparent state if it's a rotation gizmo part
                    if (child.userData.type == "back" && child.userData.partner.userData.geoBack != undefined) {
                        child.geometry = child.userData.partner.userData.geoBack;
                    }
                }
            }

            // Perform raycasting to find intersected gizmo elements
            var intersects = _raycasterInstance.intersectObjects(self._gizmo.children, false, false);

            // Sort intersections
            array_sort(intersects, function (a, b) {
                var pa = a.object.raycastOrder;
                var pb = b.object.raycastOrder;
                if (pa != pb) return pa - pb;
                return a.distance - b.distance;
            });

            if (array_length(intersects) > 0) {
                // Highlight the hovered axis with slight scaling and white glow
                var hovered = intersects[0].object;
                self.hoveredAxis = hovered;

                // If it's part of a rotation gizmo pair, update both
                if (hovered.userData != undefined && hovered.userData[$ "isRotationGizmo"]) {
                    // Manually handle pair update
                    var front, back;
                    if (hovered.userData.type == "front") {
                        front = hovered;
                        back = hovered.userData.partner;
                    } else {
                        back = hovered;
                        front = hovered.userData.partner;
                    }

                    // Highlight
                    var color = [0.3, 0.3, 0.3];
                    front.material.uniforms.ueEmissive.value = color;
                    back.material.uniforms.ueEmissive.value = color;

                    // Opaque Back
                    if (front.userData.geoBackOpaque != undefined) {
                        back.geometry = front.userData.geoBackOpaque;
                    }
                } else {
                    // Standard highlighting
                    vec3_set(hovered.scale, 1.05, 1.05, 1.05);
                    hovered.material.uniforms.ueEmissive.value = [0.3, 0.3, 0.3];
                }
            } else {
                self.hoveredAxis = undefined;
            }
        } else {
            // While dragging, keep the selected axis highlighted with yellow glow
            if (self.selectedAxis != undefined) {
                if (self.selectedAxis.userData != undefined && self.selectedAxis.userData[$ "isRotationGizmo"]) {
                    // Manually handle pair update
                    var mesh = self.selectedAxis;
                    var front, back;
                    if (mesh.userData.type == "front") {
                        front = mesh;
                        back = mesh.userData.partner;
                    } else {
                        back = mesh;
                        front = mesh.userData.partner;
                    }

                    var color = [1, 1, 0];
                    front.material.uniforms.ueEmissive.value = color;
                    back.material.uniforms.ueEmissive.value = color;

                    // Opaque Back
                    if (front.userData.geoBackOpaque != undefined) {
                        back.geometry = front.userData.geoBackOpaque;
                    }
                } else {
                    self.selectedAxis.material.uniforms.ueEmissive.value = [1, 1, 0];
                }
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

        var _raycasterInstance = self._raycaster;
        if (self.mode == "rotate") {
            _raycasterInstance = self._raycasterRotate;
        }

        self.dragging = true;
        self.selectedAxis = self.hoveredAxis;
        self.axis = self.selectedAxis.name;

        if (self.axis == "CX") self.axis = "X";
        else if (self.axis == "CY") self.axis = "Y";
        else if (self.axis == "CZ") self.axis = "Z";

        // Determine axis vector based on selected axis for mathematical calculations
        var axisVec = undefined;
        switch (self.axis) {
            case "X": axisVec = __xVec; break;
            case "Y": axisVec = __yVec; break;
            case "Z": axisVec = __zVec; break;
        }

        // Visual feedback: reset scale and add yellow emissive highlight
        vec3_set(self.selectedAxis.scale, 1, 1, 1);
        self.selectedAxis.material.uniforms.ueEmissive.value = [1, 1, 0];

        // Transform axis vector to local space if needed
        if (self.space == "local" && (self.axis == "X" || self.axis == "Y" || self.axis == "Z")) {
            axisVec.applyQuaternion(self.object.rotation);
        }

        // Calculate the optimal plane for dragging based on mode and selected axis
        var camDir = self.camera.getWorldDirection();
        var _planeNormal = camDir;

        if (self.mode == "rotate" && (self.axis == "X" || self.axis == "Y" || self.axis == "Z")) {
            // For rotate mode: plane is perpendicular to the rotation axis
            // This allows the mouse to move in a circle around the axis
            _planeNormal = axisVec.clone();

            // If camera is looking from the opposite side, flip the plane
            var dot = camDir.dot(_planeNormal);
            if (dot < 0) {
                _planeNormal.negate();
            }
        }
        else if (self.mode == "move" && (self.axis == "X" || self.axis == "Y" || self.axis == "Z")) {
            // For move mode single axis: create plane perpendicular to both camera direction and axis
            // Mathematical explanation: cross(camDir, axis) gives perpendicular vector,
            // then cross that with axis again to get plane normal that contains the axis
            _planeNormal = camDir.clone().cross(axisVec).cross(axisVec).normalize();
        }
        else if (self.axis == "XZ" || self.axis == "YZ" || self.axis == "XY") {
            // For plane handles: use the plane's natural normal
            switch (self.axis) {
                case "XY": _planeNormal = vec3_clone(__zVec); break;
                case "XZ": _planeNormal = vec3_clone(__yVec); break;
                case "YZ": _planeNormal = vec3_clone(__xVec); break;
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
        var intersectionPoint = _raycasterInstance.ray.intersectPlane(self._plane);
        if (intersectionPoint == undefined) {
            // No intersection found; cancel dragging
            self.dragging = false;
            self.selectedAxis = undefined;
            self.axis = undefined;
            return;
        }
        self.pointStart.copy(intersectionPoint);
        self.pointPrevious.copy(intersectionPoint);  // Initialize previous point for rotation
        self._rotationAngle = 0; // Reset accumulated rotation for new drag
    }

    /**
     * Handles pointer move event to update dragging transform.
     * Calculates the drag delta and applies the appropriate transformation.
     */
    function onPointerMove() {
        gml_pragma("forceinline");
        if (!self.dragging) return;

        var _raycasterInstance = self._raycaster;
        if (self.mode == "rotate") {
            _raycasterInstance = self._raycasterRotate;
        }

        // Calculate current intersection with drag plane
        var intersectionPoint = _raycasterInstance.ray.intersectPlane(self._plane);
        if (intersectionPoint == undefined) return;

        self.pointEnd.copy(intersectionPoint);

        // Calculate drag delta vector
        // For move/scale we use delta from start.
        // For rotate, we will calculate angle directly from vectors in applyTransform
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

        // Update gizmo transform (scale/rotation) to match camera/object changes
        updateGizmo();

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
            var worldDelta = vec3_clone(self.delta);

            // --- Constrain Delta to Axis ---
            if (self.space == "local") {
                // We need the object's world rotation to align the delta
                var objectWorldRot = quat_create();
                self.object.getWorldQuaternion(objectWorldRot);
                var invRot = quat_clone(objectWorldRot);
                quat_invert(invRot);

                // Transform world delta to "aligned" space
                vec3_apply_quaternion(worldDelta, invRot);

                // Apply constraints
                if (self.axis == "X") vec3_set(worldDelta, worldDelta[0], 0, 0);
                else if (self.axis == "Y") vec3_set(worldDelta, 0, worldDelta[1], 0);
                else if (self.axis == "Z") vec3_set(worldDelta, 0, 0, worldDelta[2]);
                else if (self.axis == "XY") worldDelta[2] = 0;
                else if (self.axis == "XZ") worldDelta[1] = 0;
                else if (self.axis == "YZ") worldDelta[0] = 0;

                // Transform back to world space
                vec3_apply_quaternion(worldDelta, objectWorldRot);
            } else {
                // World space constraints
                if (self.axis == "X") vec3_set(worldDelta, worldDelta[0], 0, 0);
                else if (self.axis == "Y") vec3_set(worldDelta, 0, worldDelta[1], 0);
                else if (self.axis == "Z") vec3_set(worldDelta, 0, 0, worldDelta[2]);
                else if (self.axis == "XY") worldDelta[2] = 0;
                else if (self.axis == "XZ") worldDelta[1] = 0;
                else if (self.axis == "YZ") worldDelta[0] = 0;
            }

            // Calculate Target World Position
            var targetWorldPos = vec3_clone(self._positionStartWorld);
            vec3_add(targetWorldPos, worldDelta);

            // Convert to Parent Local Space
            if (self.object.parent != undefined) {
                var parentInv = mat4_create();
                mat4_copy(parentInv, self.object.parent.matrixWorld);
                mat4_invert(parentInv);
                vec3_apply_matrix4(targetWorldPos, parentInv);
            }

            // Apply to object (targetWorldPos is now the new local position)
            var newPos = targetWorldPos;

            // Apply snapping if needed
            if (self.translationSnap != undefined) {
                if (self.axis == "X") newPos[0] = round(newPos[0] / self.translationSnap) * self.translationSnap;
                else if (self.axis == "Y") newPos[1] = round(newPos[1] / self.translationSnap) * self.translationSnap;
                else if (self.axis == "Z") newPos[2] = round(newPos[2] / self.translationSnap) * self.translationSnap;
                else if (self.axis == "XYZ") {
                    newPos[0] = round(newPos[0] / self.translationSnap) * self.translationSnap;
                    newPos[1] = round(newPos[1] / self.translationSnap) * self.translationSnap;
                    newPos[2] = round(newPos[2] / self.translationSnap) * self.translationSnap;
                }
            }

            // Clamp to configured limits
            newPos[0] = clamp(newPos[0], self.minX, self.maxX);
            newPos[1] = clamp(newPos[1], self.minY, self.maxY);
            newPos[2] = clamp(newPos[2], self.minZ, self.maxZ);

            // Apply the final position change to the object
            vec3_copy(self.object.position, newPos);
        }
        else if (self.mode == "rotate") {
            var axisVec = vec3_create();
            if (self.axis == "X") vec3_copy(axisVec, __xVec);
            else if (self.axis == "Y") vec3_copy(axisVec, __yVec);
            else if (self.axis == "Z") vec3_copy(axisVec, __zVec);
            else if (self.axis == "E") {
                // Screen space rotation: axis is vector from object to camera
                vec3_sub_vectors(axisVec, self.camera.position, self._positionStartWorld);
                vec3_normalize(axisVec);
            }
            else return;

            if (self.space == "local" && self.axis != "E") {
                var objectWorldRot = quat_create();
                self.object.getWorldQuaternion(objectWorldRot);
                vec3_apply_quaternion(axisVec, objectWorldRot);
            }

            // Accumulate rotation using small deltas (prev -> curr)
            // This allows for infinite rotation (>360 degrees) and stable behavior
            var center = self._positionStartWorld;
            var vPrev = vec3_sub_vectors(vec3_create(), self.pointPrevious, center);
            var vCurr = vec3_sub_vectors(vec3_create(), self.pointEnd, center);

            // Project vectors onto the plane perpendicular to the axis
            // vProj = v - axis * (v . axis)
            var vPrevProj = vec3_copy(vec3_create(), vPrev);
            vec3_add_scaled_vector(vPrevProj, axisVec, -vec3_dot(vPrev, axisVec));
            
            var vCurrProj = vec3_copy(vec3_create(), vCurr);
            vec3_add_scaled_vector(vCurrProj, axisVec, -vec3_dot(vCurr, axisVec));

            vec3_normalize(vPrevProj);
            vec3_normalize(vCurrProj);

            // Calculate small angle change this frame
            var vCross = vec3_cross_vectors(vec3_create(), vPrevProj, vCurrProj);
            var vDot = vec3_dot(vPrevProj, vCurrProj);
            var angleDelta = radtodeg(arctan2(vec3_dot(vCross, axisVec), vDot));

            // Accumulate total angle
            self._rotationAngle += angleDelta;

            // Prepare final angle (with snapping if enabled)
            var finalAngle = self._rotationAngle;
            if (self.rotationSnap != undefined) {
                finalAngle = round(finalAngle / self.rotationSnap) * self.rotationSnap;
            }

            // Create rotation from START state using accumulated angle
            var rotationDelta = quat_create();
            quat_set_from_axis_angle(rotationDelta, axisVec, finalAngle);

            // Apply to initial rotation
            // rotation = rotationDelta * rotationStart
            var finalRot = quat_multiply(quat_clone(rotationDelta), self._rotationStart);
            quat_copy(self.object.rotation, finalRot);

            // Update previous point for next frame
            vec3_copy(self.pointPrevious, self.pointEnd);
        }

        else if (self.mode == "scale") {
            // Calculate scale based on ratio of drag distance from center
            var objectWorldRot = quat_create();
            self.object.getWorldQuaternion(objectWorldRot);
            var invRot = quat_clone(objectWorldRot);
            quat_invert(invRot);

            // Transform start/end points to object local space (offset from center)
            var localStart = vec3_sub_vectors(vec3_create(), self.pointStart, self._positionStartWorld);
            vec3_apply_quaternion(localStart, invRot);
            
            var localEnd = vec3_sub_vectors(vec3_create(), self.pointEnd, self._positionStartWorld);
            vec3_apply_quaternion(localEnd, invRot);

            var scaleFactorX = 1;
            var scaleFactorY = 1;
            var scaleFactorZ = 1;

            if (self.axis == "XYZ") {
                // Uniform scale using "virtual drag" in screen space.
                var viewDelta = vec3_clone(self.delta);
                var camQuat = quat_create();
                self.camera.getWorldQuaternion(camQuat);
                quat_invert(camQuat);
                vec3_apply_quaternion(viewDelta, camQuat); // Transform to View Space

                // Dragging Right (+X) or Up (+Y) increases scale. 
                var dragAmount = viewDelta[0] + viewDelta[1];

                // Normalize sensitivity by distance to camera so it feels consistent
                var dist = vec3_distance_to(self.camera.position, self._positionStartWorld);
                var sensitivity = 1.0 / (dist * 0.5); // Tune this value as needed

                var uniformScale = 1 + (dragAmount * sensitivity);
                uniformScale = max(uniformScale, 0.01); // Prevent zero/negative scale

                scaleFactorX = uniformScale;
                scaleFactorY = uniformScale;
                scaleFactorZ = uniformScale;
            } else {
                // Per-axis scale based on projection ratio
                if (self.axis == "X" || self.axis == "XY" || self.axis == "XZ") {
                    if (abs(localStart[0]) > 0.001) scaleFactorX = localEnd[0] / localStart[0];
                }
                if (self.axis == "Y" || self.axis == "XY" || self.axis == "YZ") {
                    if (abs(localStart[1]) > 0.001) scaleFactorY = localEnd[1] / localStart[1];
                }
                if (self.axis == "Z" || self.axis == "XZ" || self.axis == "YZ") {
                    if (abs(localStart[2]) > 0.001) scaleFactorZ = localEnd[2] / localStart[2];
                }
            }

            var newScale = vec3_clone(self._scaleStart);
            newScale[0] *= scaleFactorX;
            newScale[1] *= scaleFactorY;
            newScale[2] *= scaleFactorZ;

            // Snap
            if (self.scaleSnap != undefined) {
                newScale[0] = round(newScale[0] / self.scaleSnap) * self.scaleSnap;
                newScale[1] = round(newScale[1] / self.scaleSnap) * self.scaleSnap;
                newScale[2] = round(newScale[2] / self.scaleSnap) * self.scaleSnap;
            }

            // Clamp
            newScale[0] = max(newScale[0], 0.01);
            newScale[1] = max(newScale[1], 0.01);
            newScale[2] = max(newScale[2], 0.01);

            vec3_copy(self.object.scale, newScale);
        }
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
        if (self.object != undefined) build();  // Rebuild gizmo with new mode
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
