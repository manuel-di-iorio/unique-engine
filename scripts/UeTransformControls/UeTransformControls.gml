enum UE_GIZMO_AXIS {
  x, y, z,
  yz, xz, xy
}

/**
 * UeTransformControls
 * A high-performance, lightweight 3D transform gizmo for GameMaker.
 * 
 * Technical Overview:
 * - Uses a 2D-overlay approach: 3D positions are projected to screen space for rendering and picking.
 * - Supports three main modes: "move", "rotate", and "scale".
 * - Supports both "world" and "local" transformation spaces.
 * - Optimized with internal math buffers to minimize per-frame memory allocations.
 * - Implements intelligent geometry caching for rotation rings to reduce projection overhead.
 * - Uses mathematical ray-plane and ray-line projections for stable dragging without jitter.
 * 
 * @param {Struct} camera - The camera object used for 3D-to-2D projections.
 * @param {Struct} data - Optional configuration data.
 */
function UeTransformControls(camera, data = {}): UeControls(data) constructor {
  self.camera = camera;
  self.object = undefined;
  self.mode = "move"; // Current transformation mode: "move", "rotate", "scale"
  self.space = "world";    // Coordinate space: "world" or "local"
  self.size = 1.0;         // User-defined size multiplier for the gizmo
  self.enabled = true;     // Whether the gizmo is active and visible
  self.view = data[$ "view"] ?? 0; // The GameMaker view index to use

  self.hoveredAxis = undefined;  // The axis currently under the mouse
  self.selectedAxis = undefined; // The axis currently being dragged
  self.dragging = false;         // Drag state flag
  self.axis = undefined;         // Active axis index (X, Y, Z, etc.)

  // --- Internal Drag State ---
  // These variables store the state of the object and mouse at the moment a drag starts.
  self._dragStartPoint = vec3_create();     // Object's local position at drag start
  self._dragStartRot = quat_create();       // Object's rotation at drag start
  self._dragStartScale = vec3_create();     // Object's scale at drag start
  self._dragStartWorldPos = vec3_create();  // Object's world position at drag start (stable reference)
  self._dragLockedAxisVec = vec3_create();  // Normalized world direction of the active axis
  self._dragOffset = 0;                     // Initial scalar offset along the axis
  self._dragOffsetVec = vec3_create();      // Initial vector offset for plane-based dragging
  self._dragAngleStart = 0;                 // Initial screen-space angle for rotation
  self._centerPos = vec3_create();          // Current world center of the gizmo
  self._gizmoScale = 1.0;                   // Dynamic scale based on distance to camera

  // --- Viewport & Projection Caches ---
  // Pre-calculated constants to speed up 3D -> 2D projections every frame.
  self._vw = 0; self._vh = 0; self._vx = 0; self._vy = 0;
  self._guiW = 0; self._guiH = 0; self._winW = 0; self._winH = 0;
  self._projFactorX = 0; self._projOffsetX = 0;
  self._projFactorY = 0; self._projOffsetY = 0;

  // --- Ring Geometry Optimization ---
  // Caches for the rotation rings to avoid re-projecting 3D points when the view hasn't changed significantly.
  self._ringLastUpdateCenter = vec3_create();
  self._ringLastUpdateCamPos = vec3_create();
  self._ringLastUpdateCamRot = quat_create();
  self._ringLastUpdateObjRot = quat_create();
  self._ringLastUpdateSpace = "";
  self._ringLastUpdateMode = "";
  self._ringLastUpdateViewDir = vec3_create();
  self._ringOrigin2D = vec2_create(); // Screen-space center of the rings
  self._ringOriginW = 1.0;            // W-component (depth) for projection scaling

  // --- Math Buffers ---
  // Reusable arrays/structs to prevent garbage collection spikes from per-frame math.
  self._matViewProj = mat4_create();
  self._vec0 = vec3_create();
  self._vec1 = vec3_create();
  self._vec2 = vec3_create();
  self._vec3 = vec3_create();
  self._vec4 = vec3_create();
  self._vec5 = vec3_create();
  self._vec6 = vec3_create();
  self._vec7 = vec3_create();
  self._vec2D = vec2_create();
  self._vec2D_0 = vec2_create();
  self._vec2D_1 = vec2_create();
  self._vec2D_2 = vec2_create();
  self._quat0 = quat_create();
  self._quat1 = quat_create();
  self._quat2 = quat_create();
  self._quat3 = quat_create();
  self._mat0 = mat4_create();

  // --- Drawing Configuration ---
  self.lineWidth = 3;      // Thickness of gizmo lines in pixels
  self.hitThreshold = 10;  // Pixel distance for mouse picking
  self.axisLength = 1.5;   // Length of the axes in world units

  // --- Color Palette ---
  self.cRed = c_red;
  self.cBlue = make_color_rgb(0x22, 0x77, 0xB3);
  self.cGreen = c_lime;
  self.cWhite = c_white;
  self.cYellow = c_yellow;

  // --- Callbacks ---
  self.onDragStart = data[$ "onDragStart"]; // Fired when dragging begins
  self.onDrag      = data[$ "onDrag"];      // Fired every frame while dragging
  self.onDragEnd   = data[$ "onDragEnd"];   // Fired when dragging stops

  // --- Geometry Generation ---
  // Generates unit-sized points for the rotation rings in X, Y, and Z planes.
  self._ringCache = array_create(3, undefined); 
  self._unitRings = array_create(3);            
  
  var _segs = 32; // Number of segments for the ring circles
  for (var a = 0; a < 3; a++) {
    var points = array_create(_segs + 1);
    for (var i = 0; i <= _segs; i++) {
      var _angle = (i / _segs) * (pi * 2);
      var px = cos(_angle);
      var py = sin(_angle);
      
      // Points are relative to the gizmo center
      if (a == 0) points[i] = [0, px, py];      // X-axis ring (YZ plane)
      else if (a == 1) points[i] = [px, 0, py]; // Y-axis ring (XZ plane)
      else points[i] = [px, py, 0];             // Z-axis ring (XY plane)
    }
    self._unitRings[a] = points;
  }

  /**
   * Sets the current transformation mode.
   * @param {String} mode - "move", "rotate", or "scale".
   */
  function setMode(mode) {
    gml_pragma("forceinline");
    self.mode = mode;
    return self;
  }

  /**
   * Attaches the gizmo to a specific object for manipulation.
   * @param {Struct} object - The object to transform (must have position, rotation, scale).
   */
  function attach(object) {
    gml_pragma("forceinline");
    self.object = object;

    // Ensure object's world matrix is up-to-date so gizmo uses correct world transforms
    if (object.updateWorldMatrix != undefined) {
      object.updateWorldMatrix(true, false);
    }

    return self;
  }

  /**
   * Detaches the gizmo from the current object.
   */
  function detach() {
    gml_pragma("forceinline");
    self.object = undefined;
    self.hoveredAxis = undefined;
    self.selectedAxis = undefined;
    self.dragging = false;
    return self;
  }

  /**
   * Updates only the gizmo's internal state (matrices, position, scale, and ring caching).
   * Useful for updating the gizmo's orientation/position without processing mouse interactions.
   */
  function updateGizmo() {
    gml_pragma("forceinline");
    if (!self.object || !self.enabled) return;

    // 1. Force the target object to update its world matrix so we have accurate position/rotation.
    if (self.object.updateWorldMatrix != undefined) {
      self.object.updateWorldMatrix(true, false);
    }

    // 2. Sync camera matrices and calculate the combined View-Projection matrix.
    if (variable_struct_exists(self.camera, "updateMatrixWorld")) self.camera.updateMatrixWorld();

    if (self.camera.matrixWorldInverse != undefined) {
      mat4_copy(self._mat0, self.camera.matrixWorld);
      mat4_invert(self._mat0);
      mat4_copy(self.camera.matrixWorldInverse, self._mat0);
    }

    matrix_multiply(self.camera.matrixWorldInverse, self.camera.projectionMatrix, self._matViewProj);

    // 3. Pre-calculate viewport and GUI constants to optimize _worldToScreen projections.
    self._vw = view_wport[self.view];
    self._vh = view_hport[self.view];
    self._vx = view_xport[self.view];
    self._vy = view_yport[self.view];
    self._guiW = display_get_gui_width();
    self._guiH = display_get_gui_height();
    self._winW = window_get_width();
    self._winH = window_get_height();

    var scaleX = self._guiW / self._winW;
    var scaleY = self._guiH / self._winH;
    
    self._projFactorX = (0.5 * self._vw) * scaleX;
    self._projOffsetX = (self._vx + 0.5 * self._vw) * scaleX;
    self._projFactorY = (0.5 * self._vh) * scaleY;
    self._projOffsetY = (self._vy + 0.5 * self._vh) * scaleY;

    // 4. Update the gizmo's world center and dynamic scale (keeping it constant size on screen).
    self.object.getWorldPosition(self._centerPos);
    self._gizmoScale = self._computeGizmoScale(self._centerPos);

    // 5. Intelligent Ring Caching logic for "rotate" mode.
    var origin2D = self._worldToScreen(self._centerPos, self._matViewProj, self._ringOrigin2D);
    var m = self._matViewProj;
    
    // Calculate the W component (depth) for the ring center to use in screen-space scaling.
    self._ringOriginW = m[3] * self._centerPos[0] + m[7] * self._centerPos[1] + m[11] * self._centerPos[2] + m[15];
    
    if (self.mode == "rotate" && origin2D != undefined) {
      var camPos = self.camera.getWorldPosition(self._vec0);
      var viewDir = self._vec6;
      vec3_sub(viewDir, camPos, self._centerPos);
      vec3_normalize(viewDir);

      var objRot = self.object.getWorldQuaternion(self._quat2);
      
      var needsUpdate = false;
      if (self.space != self._ringLastUpdateSpace) needsUpdate = true;
      else if (self.mode != self._ringLastUpdateMode) needsUpdate = true;
      else if (vec3_distance_to_squared(viewDir, self._ringLastUpdateViewDir) > UE_EPSILON) needsUpdate = true;
      else if (self.space == "local" && abs(1.0 - abs(quat_dot(objRot, self._ringLastUpdateObjRot))) > UE_EPSILON) needsUpdate = true;

      if (needsUpdate) {
        self._updateRingGeom(self._centerPos);
        
        // Cache current state for the next frame
        vec3_copy(self._ringLastUpdateViewDir, viewDir);
        quat_copy(self._ringLastUpdateObjRot, objRot);
        self._ringLastUpdateSpace = self.space;
        self._ringLastUpdateMode = self.mode;
      }
    }
  }

  /**
   * The main update loop for the gizmo. Handles:
   * 1. State updates (via updateGizmo).
   * 2. Interaction logic (picking and dragging).
   */
  function update() {
    gml_pragma("forceinline");
    if (!self.object || !self.enabled) return;

    // 1. Update internal state (matrices, position, scale, caching)
    self.updateGizmo();

    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    // --- INTERACTION: DRAGGING ---
    if (self.dragging && self.selectedAxis != undefined) {
      if (mouse_check_button_released(mb_left)) {
        self.dragging = false;
        self.selectedAxis = undefined;
        if (self.onDragEnd != undefined) self.onDragEnd();
        return;
      }

      _handleDrag(mx, my, self._centerPos, self._gizmoScale);
      return;
    }

    // --- INTERACTION: PICKING ---
    // Detect if the user clicks on any gizmo component.
    if (mouse_check_button_pressed(mb_left) && self.hoveredAxis != undefined) {
      self._startDrag(mx, my, self._centerPos, self._gizmoScale);
      return;
    }

    self.hoveredAxis = undefined;
    var minDist = self.hitThreshold;

    var origin2D = self._worldToScreen(self._centerPos, self._matViewProj);
    if (origin2D == undefined) return; // Gizmo is behind the camera clipping plane

    // Component-specific picking logic
    if (self.mode == "move") {
      // 1. Plane handles (the squares between axes) have priority
      if (self._pickPlaneHandle(UE_GIZMO_AXIS.xy, self._centerPos, self._gizmoScale, mx, my)) {
        self.hoveredAxis = UE_GIZMO_AXIS.xy; minDist = 0;
      }
      else if (self._pickPlaneHandle(UE_GIZMO_AXIS.xz, self._centerPos, self._gizmoScale, mx, my)) {
        self.hoveredAxis = UE_GIZMO_AXIS.xz; minDist = 0;
      }
      else if (self._pickPlaneHandle(UE_GIZMO_AXIS.yz, self._centerPos, self._gizmoScale, mx, my)) {
        self.hoveredAxis = UE_GIZMO_AXIS.yz; minDist = 0;
      }

      // 2. Standard axis arrows
      if (self.hoveredAxis == undefined) {
        if (self._pickArrow(UE_GIZMO_AXIS.x, self._centerPos, self._gizmoScale, mx, my, minDist)) {
          self.hoveredAxis = UE_GIZMO_AXIS.x; minDist = 0;
        }
        else if (self._pickArrow(UE_GIZMO_AXIS.y, self._centerPos, self._gizmoScale, mx, my, minDist)) {
          self.hoveredAxis = UE_GIZMO_AXIS.y; minDist = 0;
        }
        else if (self._pickArrow(UE_GIZMO_AXIS.z, self._centerPos, self._gizmoScale, mx, my, minDist)) {
          self.hoveredAxis = UE_GIZMO_AXIS.z; minDist = 0;
        }
      }
    }
    else if (self.mode == "scale") {
      if (self._pickArrow(UE_GIZMO_AXIS.x, self._centerPos, self._gizmoScale, mx, my, minDist)) {
        self.hoveredAxis = UE_GIZMO_AXIS.x; minDist = 0;
      }
      else if (self._pickArrow(UE_GIZMO_AXIS.y, self._centerPos, self._gizmoScale, mx, my, minDist)) {
        self.hoveredAxis = UE_GIZMO_AXIS.y; minDist = 0;
      }
      else if (self._pickArrow(UE_GIZMO_AXIS.z, self._centerPos, self._gizmoScale, mx, my, minDist)) {
        self.hoveredAxis = UE_GIZMO_AXIS.z; minDist = 0;
      }
    }
    else if (self.mode == "rotate") {
      if (self._pickRing(UE_GIZMO_AXIS.x, mx, my, minDist)) {
        self.hoveredAxis = UE_GIZMO_AXIS.x; minDist = 0;
      } else if (self._pickRing(UE_GIZMO_AXIS.y, mx, my, minDist)) {
        self.hoveredAxis = UE_GIZMO_AXIS.y; minDist = 0;
      } else if (self._pickRing(UE_GIZMO_AXIS.z, mx, my, minDist)) {
        self.hoveredAxis = UE_GIZMO_AXIS.z; minDist = 0;
      }
    }
  }

  /**
   * Draws the gizmo.
   * Should be called in Draw GUI event.
   */
  function render() {
    gml_pragma("forceinline");
    if (!self.object || !self.enabled) return;

    // Use a member buffer for origin2D
    var origin2D = self._worldToScreen(self._centerPos, self._matViewProj, self._vec2D_0);
    if (origin2D == undefined) return;

    if (self.mode == "move") {
      self._drawPlaneHandle(UE_GIZMO_AXIS.yz, self._centerPos, self._gizmoScale, origin2D); // Red
      self._drawPlaneHandle(UE_GIZMO_AXIS.xz, self._centerPos, self._gizmoScale, origin2D); // Blue
      self._drawPlaneHandle(UE_GIZMO_AXIS.xy, self._centerPos, self._gizmoScale, origin2D); // Green

      self._drawArrow(UE_GIZMO_AXIS.x, self._centerPos, self._gizmoScale, origin2D);
      self._drawArrow(UE_GIZMO_AXIS.y, self._centerPos, self._gizmoScale, origin2D);
      self._drawArrow(UE_GIZMO_AXIS.z, self._centerPos, self._gizmoScale, origin2D);
    } else if (self.mode == "scale") {
      self._drawScaleHandle(UE_GIZMO_AXIS.x, self._centerPos, self._gizmoScale, origin2D);
      self._drawScaleHandle(UE_GIZMO_AXIS.y, self._centerPos, self._gizmoScale, origin2D);
      self._drawScaleHandle(UE_GIZMO_AXIS.z, self._centerPos, self._gizmoScale, origin2D);
    } else if (self.mode == "rotate") {
      self._drawRing(UE_GIZMO_AXIS.x);
      self._drawRing(UE_GIZMO_AXIS.y);
      self._drawRing(UE_GIZMO_AXIS.z);
    }
  }

  // --- DRAG HANDLERS ---

  /**
   * Initiates dragging for the given axis.
   * Stores initial state and prepares for drag calculations.
   */
  function _startDrag(mx, my, centerPos, scale) {
    gml_pragma("forceinline");
    self.dragging = true;
    self.selectedAxis = self.hoveredAxis;
    self.axis = self.hoveredAxis;

    // Store Start State
    vec3_copy(self._dragStartPoint, self.object.position);
    quat_copy(self._dragStartRot, self.object.rotation);
    vec3_copy(self._dragStartScale, self.object.scale);
    self.object.getWorldPosition(self._dragStartWorldPos);
    self._getAxisVector(self.axis, self._dragLockedAxisVec);

    if (self.mode == "move") {
      if (self.axis == UE_GIZMO_AXIS.xy || self.axis == UE_GIZMO_AXIS.xz || self.axis == UE_GIZMO_AXIS.yz) {
        // Plane Drag
        var normal = self._vec1;
        self._getAxisVector(self.axis, normal); // Returns proper normal for plane enums

        var hit = self._computePlaneIntersection(mx, my, self._dragStartWorldPos, normal);
        if (hit != undefined) {
          vec3_copy(self._dragOffsetVec, hit);
          vec3_sub(self._dragOffsetVec, self._dragStartWorldPos);
        } else {
          self.dragging = false; // Failed to hit plane??
        }
      } else {
        // Axis Drag
        self._dragOffset = self._computeAxisProjectionStable(mx, my, self._dragStartWorldPos, self._dragLockedAxisVec);
        if (self._dragOffset == undefined) self.dragging = false;
      }
    } else if (self.mode == "scale") {
      // Project initial mouse hit onto axis line
      self._dragOffset = self._computeAxisProjectionStable(mx, my, self._dragStartWorldPos, self._dragLockedAxisVec);
    } else if (self.mode == "rotate") {
      // Compute Initial Angle on Screen relative to center
      var origin2D = self._worldToScreen(self._dragStartWorldPos, self._matViewProj);
      if (origin2D != undefined) {
        self._dragAngleStart = arctan2(my - origin2D[1], mx - origin2D[0]);
      }
    }

    if (self.dragging && self.onDragStart != undefined) {
      self.onDragStart();
    }
  }

  /**
   * Handles dragging for the current axis.
   * Applies delta transformations to the object.
   */
  function _handleDrag(mx, my, centerPos, scale) {
    gml_pragma("forceinline");
    if (self.mode == "move") {

      if (self.axis == UE_GIZMO_AXIS.xy || self.axis == UE_GIZMO_AXIS.xz || self.axis == UE_GIZMO_AXIS.yz) {
        // Plane Logic
        var normal = self._dragLockedAxisVec;

        var hit = self._computePlaneIntersection(mx, my, self._dragStartWorldPos, normal);
        if (hit == undefined) return;

        var newPos = self._vec2;
        vec3_copy(newPos, hit);
        vec3_sub(newPos, self._dragOffsetVec); // This is now a world position

        // Apply to Object
        if (self.object.parent != undefined) {
          var parentInv = self._mat0;
          mat4_copy(parentInv, self.object.parent.matrixWorld);
          mat4_invert(parentInv);
          vec3_apply_matrix4(newPos, parentInv);
        }

        vec3_copy(self.object.position, newPos);
        self.object.updateWorldMatrix(true, false);
      } else {

      var currT = self._computeAxisProjectionStable(mx, my, self._dragStartWorldPos, self._dragLockedAxisVec);
      if (currT == undefined || self._dragOffset == undefined) return;

      var delta = currT - self._dragOffset;

      // Apply Delta to Position
      var axisVec = self._dragLockedAxisVec;
      var moveVec = self._vec2;
      vec3_copy(moveVec, axisVec);
      vec3_multiply_scalar(moveVec, delta);

      // Transform to Local Space logic
      if (self.space == "local") {
        if (self.object.parent != undefined) {
          var parentInv = self._mat0;
          mat4_copy(parentInv, self.object.parent.matrixWorld);
          mat4_invert(parentInv);
          mat4_set_position(parentInv, 0, 0, 0);
          vec3_apply_matrix4(moveVec, parentInv);
        }
        var newPos = self._vec3;
        vec3_copy(newPos, self._dragStartPoint);
        vec3_add(newPos, moveVec);
        vec3_copy(self.object.position, newPos);

      } else { // World Space Axis
        if (self.object.parent != undefined) {
          var parentInv = self._mat0;
          mat4_copy(parentInv, self.object.parent.matrixWorld);
          mat4_invert(parentInv);
          mat4_set_position(parentInv, 0, 0, 0);
          vec3_apply_matrix4(moveVec, parentInv);
        }
        var newPos = self._vec3;
        vec3_copy(newPos, self._dragStartPoint);
        vec3_add(newPos, moveVec);
        vec3_copy(self.object.position, newPos);
      }

      // IMPORTANT: Immediately update world matrix to prevent jitter
      self.object.updateWorldMatrix(true, false);
    }

    } else if (self.mode == "scale") {
      var currT = self._computeAxisProjectionStable(mx, my, self._dragStartWorldPos, self._dragLockedAxisVec);
      if (currT == undefined) return;

      var delta = (currT - self._dragOffset) * 0.1; // Reduced sensitivity

      var scaleAxis = (self.axis == UE_GIZMO_AXIS.x) ? 0 : ((self.axis == UE_GIZMO_AXIS.y) ? 1 : 2);
      var newScale = self._vec2;
      vec3_copy(newScale, self._dragStartScale);

      newScale[scaleAxis] += delta;
      vec3_copy(self.object.scale, newScale);
      self.object.updateWorldMatrix(true, false);

    } else if (self.mode == "rotate") {
      var origin2D = self._worldToScreen(self._dragStartWorldPos, self._matViewProj);
      if (origin2D != undefined) {
        var currAngle = arctan2(my - origin2D[1], mx - origin2D[0]);
        var deltaAngle = currAngle - self._dragAngleStart;

        // Invert rotation if camera is looking "along" the axis
        var camDir = self._vec0;
        self.camera.getWorldDirection(camDir);
        var axisVec = self._dragLockedAxisVec;

        // If angle between View and Axis is acute (<90), we are "behind" -> Flip
        if (vec3_dot(camDir, axisVec) > 0) {
          deltaAngle = -deltaAngle;
        }

        var qDelta = self._quat0;
        quat_set_from_axis_angle(qDelta, axisVec, radtodeg(deltaAngle));

        var newRot = self._quat1;
        quat_copy(newRot, self._dragStartRot);

        if (self.space == "local") {
          quat_multiply(newRot, qDelta);
        } else {
          quat_premultiply(newRot, qDelta);
        }

        quat_copy(self.object.rotation, newRot);
        self.object.updateWorldMatrix(true, false);
      }
    }

    if (self.onDrag != undefined) {
      self.onDrag();
    }
  }

  /**
   * Computes the projection of the mouse point (mx, my) onto the given axis.
   * Returns the distance from the centerPos to the projection point.
   */
  function _computeAxisProjection(mx, my, centerPos, axisName) {
    gml_pragma("forceinline");
    var axisVec = self._vec4;
    self._getAxisVector(axisName, axisVec);

    var camDir = self._vec5;
    self.camera.getWorldDirection(camDir);

    var planeNormal = self._vec6;
    vec3_copy(planeNormal, axisVec);
    vec3_cross(planeNormal, camDir);
    vec3_cross(planeNormal, axisVec);

    if (vec3_length(planeNormal) < UE_EPSILON) return undefined;
    vec3_normalize(planeNormal);

    var rayOrigin = self.camera.position;
    var rayDir = self._screenToWorldDir(mx, my);
    if (rayDir == undefined) return undefined;

    var denom = vec3_dot(rayDir, planeNormal);
    if (abs(denom) < UE_EPSILON) return 0;

    var p0lo = self._vec7;
    vec3_copy(p0lo, centerPos);
    vec3_sub(p0lo, rayOrigin);
    var t = vec3_dot(p0lo, planeNormal) / denom;

    var hitPoint = self._vec7; // Reuse p0lo as hitPoint
    vec3_copy(hitPoint, rayDir);
    vec3_multiply_scalar(hitPoint, t);
    vec3_add(hitPoint, rayOrigin);

    vec3_sub(hitPoint, centerPos);
    return vec3_dot(hitPoint, axisVec);
  }

  /**
   * Computes the projection of the mouse point (mx, my) onto the given axis.
   * Returns the distance from the centerPos to the projection point.
   * Handles edge cases where the axis is parallel to the camera direction.
   */
  function _computeAxisProjectionStable(mx, my, centerPos, axisVec) {
    gml_pragma("forceinline");
    var camDir = self._vec5;
    self.camera.getWorldDirection(camDir);

    var planeNormal = self._vec6;
    vec3_copy(planeNormal, axisVec);
    vec3_cross(planeNormal, camDir);
    vec3_cross(planeNormal, axisVec);

    if (vec3_length(planeNormal) < UE_EPSILON) return undefined;
    vec3_normalize(planeNormal);

    var rayOrigin = self.camera.position;
    var rayDir = self._screenToWorldDir(mx, my);
    if (rayDir == undefined) return undefined;

    var denom = vec3_dot(rayDir, planeNormal);
    if (abs(denom) < UE_EPSILON) return 0;

    var p0lo = self._vec7;
    vec3_copy(p0lo, centerPos);
    vec3_sub(p0lo, rayOrigin);
    var t = vec3_dot(p0lo, planeNormal) / denom;

    var hitPoint = self._vec7; 
    vec3_copy(hitPoint, rayDir);
    vec3_multiply_scalar(hitPoint, t);
    vec3_add(hitPoint, rayOrigin);

    vec3_sub(hitPoint, centerPos);
    return vec3_dot(hitPoint, axisVec);
  }

  // --- INTERNAL HELPERS ---

  /**
   * Computes the scale of the gizmo based on the distance to the object.
   * Ensures a minimum size of self.size.
   */
  function _computeGizmoScale(pos) {
    gml_pragma("forceinline");
    if (is_nan(pos[0]) || is_nan(pos[1]) || is_nan(pos[2])) return self.size;
    var dist = vec3_distance_to(self.camera.position, pos);
    if (is_nan(dist) || dist == infinity) return self.size;
    return dist * 0.15 * self.size;
  }

  /**
   * Computes the vector of the given axis in world space.
   * Optionally transforms the vector to local space if self.space is "local".
   */
  function _getAxisVector(axis, out) {
    gml_pragma("forceinline");
    vec3_set(out, 0, 0, 0);
    // Normals: X for YZ, Y for XZ, Z for XY
    if (axis == UE_GIZMO_AXIS.x || axis == UE_GIZMO_AXIS.yz) out[0] = 1;
    else if (axis == UE_GIZMO_AXIS.y || axis == UE_GIZMO_AXIS.xz) out[1] = 1;
    else if (axis == UE_GIZMO_AXIS.z || axis == UE_GIZMO_AXIS.xy) out[2] = 1;

    if (self.space == "local" && self.object) {
      var q = global.UE_QUAT_TEMP0;
      self.object.getWorldQuaternion(q);
      vec3_apply_quaternion(out, q);
    }

    // Face towards camera
    var camDir = global.UE_VEC3_TEMP2;
    self.camera.getWorldDirection(camDir);

    // If axis points away from camera → flip
    if (vec3_dot(out, camDir) < 0) {
      vec3_multiply_scalar(out, -1);
    }

    return out;
  }

  /**
   * Returns the color of the given axis based on its state (hovered, selected, or default).
   */
  function _getAxisColor(axis) {
    gml_pragma("forceinline");
    if (self.hoveredAxis == axis || self.selectedAxis == axis) return self.cYellow;
    if (axis == UE_GIZMO_AXIS.x || axis == UE_GIZMO_AXIS.yz) return self.cRed;
    if (axis == UE_GIZMO_AXIS.y || axis == UE_GIZMO_AXIS.xz) return self.cBlue;
    if (axis == UE_GIZMO_AXIS.z || axis == UE_GIZMO_AXIS.xy) return self.cGreen;
    return c_white;
  }

  /**
   * Draws an arrow for the given axis at the specified center position.
   * The arrow is scaled by the given factor and drawn from the origin2D.
   */
  function _drawArrow(axis, center, scale, origin2D) {
    gml_pragma("forceinline");
    var endPos = self._vec0;
    vec3_copy(endPos, center);
    self._getAxisVector(axis, self._vec1);
    vec3_add_scaled_vector(endPos, self._vec1, self.axisLength * scale);

    var end2D = self._worldToScreen(endPos, self._matViewProj, self._vec2D_1);
    if (end2D == undefined) return;

    var col = self._getAxisColor(axis);

    // Fake 3D Arrow (Triangle)
    var dx = end2D[0] - origin2D[0];
    var dy = end2D[1] - origin2D[1];
    var len = sqrt(dx * dx + dy * dy);

    // Draw line shorter to not overlap head
    var headLen = self.lineWidth * 6.0;
    var linePixels = len - headLen + 2; // +2 overlap 
    if (linePixels < 0) linePixels = 0;

    var lineEndX = origin2D[0];
    var lineEndY = origin2D[1];

    if (len > 0) {
      dx /= len; dy /= len;
      lineEndX = origin2D[0] + dx * linePixels;
      lineEndY = origin2D[1] + dy * linePixels;

      var headW = self.lineWidth * 3.0;
      var bx = end2D[0] - dx * headLen;
      var by = end2D[1] - dy * headLen;

      var p1x = end2D[0];
      var p1y = end2D[1];
      var p2x = bx - dy * headW;
      var p2y = by + dx * headW;
      var p3x = bx + dy * headW;
      var p3y = by - dx * headW;

      draw_set_color(col);
      draw_line_width(origin2D[0], origin2D[1], lineEndX, lineEndY, self.lineWidth);
      draw_triangle(p1x, p1y, p2x, p2y, p3x, p3y, false);
    }
  }

  /**
   * Checks if the mouse position (mx, my) is within the click threshold of the arrow for the given axis.
   * The arrow is defined by the center position, scale, and axis normal.
   */
  function _pickArrow(axisName, center, scale, mx, my, threshold) {
    gml_pragma("forceinline");
    var endPos = self._vec0;
    vec3_copy(endPos, center);
    self._getAxisVector(axisName, self._vec1);
    vec3_add_scaled_vector(endPos, self._vec1, self.axisLength * scale);

    var origin2D = self._worldToScreen(center, self._matViewProj, self._vec2D_1);
    var end2D = self._worldToScreen(endPos, self._matViewProj, self._vec2D_2);

    if (origin2D != undefined && end2D != undefined) {
      // Use Vector2 library function
      var d = vec2_distance_to_segment([mx, my], origin2D, end2D);
      return (d < threshold);
    }
    return false;
  }

  /**
   * Computes the right and up vectors for the given axis plane.
   * The axis plane is defined by the axis normal.
   */
  function _getPlaneBasis(axis, outRight, outUp) {
    gml_pragma("forceinline");
    if (axis == UE_GIZMO_AXIS.yz) {
      self._getAxisVector(UE_GIZMO_AXIS.y, outRight);
      self._getAxisVector(UE_GIZMO_AXIS.z, outUp);
    }
    else if (axis == UE_GIZMO_AXIS.xz) {
      self._getAxisVector(UE_GIZMO_AXIS.x, outRight);
      self._getAxisVector(UE_GIZMO_AXIS.z, outUp);
    }
    else if (axis == UE_GIZMO_AXIS.xy) {
      self._getAxisVector(UE_GIZMO_AXIS.x, outRight);
      self._getAxisVector(UE_GIZMO_AXIS.y, outUp);
    }
  }

  /**
   * Draws a scale handle for the given axis at the specified center position.
   * The handle is scaled by the given factor and drawn from the origin2D.
   */
  function _drawScaleHandle(axisName, center, scale, origin2D) {
    gml_pragma("forceinline");
    var endPos = self._vec0;
    vec3_copy(endPos, center);
    self._getAxisVector(axisName, self._vec1);
    vec3_add_scaled_vector(endPos, self._vec1, self.axisLength * scale);

    var end2D = self._worldToScreen(endPos, self._matViewProj, self._vec2D_1);
    if (end2D == undefined) return;

    var col = self._getAxisColor(axisName);

    draw_line_width_color(origin2D[0], origin2D[1], end2D[0], end2D[1], self.lineWidth, col, col);
    // Box Tip
    var s = self.lineWidth * 2.5;
    draw_rectangle_color(end2D[0] - s, end2D[1] - s, end2D[0] + s, end2D[1] + s, col, col, col, col, false);
  }

  /**
   * Draws a plane handle for the given axis at the specified center position.
   * The handle is scaled by the given factor and drawn from the origin2D.
   */
  function _drawPlaneHandle(axis, center, scale, origin2D) {
    gml_pragma("forceinline");
    // Planes:
    // YZ (Red): Normal X. Spans Y, Z.
    // XZ (Blue): Normal Y. Spans X, Z.
    // XY (Green): Normal Z. Spans X, Y.

    var size = self.axisLength * scale * 0.3;
    var offset = 0;

    var p0 = self._vec2;
    var p1 = self._vec3;
    var p2 = self._vec4;
    var p3 = self._vec5;
    vec3_copy(p0, center);
    vec3_copy(p1, center);
    vec3_copy(p2, center);
    vec3_copy(p3, center);

    var up = self._vec6;
    var right = self._vec7;
    vec3_set(up, 0, 0, 0);
    vec3_set(right, 0, 0, 0);

    self._getPlaneBasis(axis, right, up);

    // Calculate 4 corners
    // p0 = center + offset*right + offset*up
    // p1 = center + (offset+size)*right + offset*up
    // p2 = center + (offset+size)*right + (offset+size)*up
    // p3 = center + offset*right + (offset+size)*up

    var vOffsetRight = self._vec0; 
    vec3_copy(vOffsetRight, right); vec3_multiply_scalar(vOffsetRight, offset);
    var vOffsetUp = self._vec1; 
    vec3_copy(vOffsetUp, up); vec3_multiply_scalar(vOffsetUp, offset);
    
    // p0
    vec3_add(p0, vOffsetRight); vec3_add(p0, vOffsetUp);
    
    // Reuse vOffsetRight/Up for Size
    var vSizeRight = vOffsetRight; 
    vec3_copy(vSizeRight, right); vec3_multiply_scalar(vSizeRight, size);
    var vSizeUp = vOffsetUp; 
    vec3_copy(vSizeUp, up); vec3_multiply_scalar(vSizeUp, size);

    // p1
    vec3_copy(p1, p0); vec3_add(p1, vSizeRight);
    // p2
    vec3_copy(p2, p1); vec3_add(p2, vSizeUp);
    // p3
    vec3_copy(p3, p0); vec3_add(p3, vSizeUp);

    // Project
    var s0 = self._worldToScreen(p0, self._matViewProj, self._vec2D_1);
    if (s0 == undefined) return;
    var s0x = s0[0], s0y = s0[1];

    var s1 = self._worldToScreen(p1, self._matViewProj, self._vec2D_1);
    if (s1 == undefined) return;
    var s1x = s1[0], s1y = s1[1];

    var s2 = self._worldToScreen(p2, self._matViewProj, self._vec2D_1);
    if (s2 == undefined) return;
    var s2x = s2[0], s2y = s2[1];

    var s3 = self._worldToScreen(p3, self._matViewProj, self._vec2D_1);
    if (s3 == undefined) return;
    var s3x = s3[0], s3y = s3[1];

    var col = self._getAxisColor(axis);
    draw_set_color(col);
    draw_set_alpha(0.5); // Semi-transparent
    draw_triangle(s0x, s0y, s1x, s1y, s2x, s2y, false);
    draw_triangle(s0x, s0y, s2x, s2y, s3x, s3y, false);
    draw_set_alpha(1.0);
  }

  /**
   * Checks if the mouse position (mx, my) is within the click threshold of the plane handle for the given axis.
   * The handle is defined by the center position, scale, and axis normal.
   */
  function _pickPlaneHandle(axis, center, scale, mx, my) {
    gml_pragma("forceinline");  
    var size = self.axisLength * scale * 0.3;
    var offset = 0;

    var p0 = self._vec2;
    var p1 = self._vec3;
    var p2 = self._vec4;
    var p3 = self._vec5;
    vec3_copy(p0, center);
    vec3_copy(p1, center);
    vec3_copy(p2, center);
    vec3_copy(p3, center);

    var up = self._vec6;
    var right = self._vec7;
    vec3_set(up, 0, 0, 0);
    vec3_set(right, 0, 0, 0);

    self._getPlaneBasis(axis, right, up);

    var vOffsetRight = self._vec0; 
    vec3_copy(vOffsetRight, right); vec3_multiply_scalar(vOffsetRight, offset);
    var vOffsetUp = self._vec1; 
    vec3_copy(vOffsetUp, up); vec3_multiply_scalar(vOffsetUp, offset);
    
    vec3_add(p0, vOffsetRight); vec3_add(p0, vOffsetUp);
    
    var vSizeRight = vOffsetRight; 
    vec3_copy(vSizeRight, right); vec3_multiply_scalar(vSizeRight, size);
    var vSizeUp = vOffsetUp; 
    vec3_copy(vSizeUp, up); vec3_multiply_scalar(vSizeUp, size);

    vec3_copy(p1, p0); vec3_add(p1, vSizeRight);
    vec3_copy(p2, p1); vec3_add(p2, vSizeUp);
    vec3_copy(p3, p0); vec3_add(p3, vSizeUp);

    var s0 = self._worldToScreen(p0, self._matViewProj, self._vec2D_1);
    if (s0 == undefined) return false;
    var s0x = s0[0], s0y = s0[1];

    var s1 = self._worldToScreen(p1, self._matViewProj, self._vec2D_1);
    if (s1 == undefined) return false;
    var s1x = s1[0], s1y = s1[1];

    var s2 = self._worldToScreen(p2, self._matViewProj, self._vec2D_1);
    if (s2 == undefined) return false;
    var s2x = s2[0], s2y = s2[1];

    var s3 = self._worldToScreen(p3, self._matViewProj, self._vec2D_1);
    if (s3 == undefined) return false;
    var s3x = s3[0], s3y = s3[1];

    // Point in Triangle Check (Fan)
    if (point_in_triangle(mx, my, s0x, s0y, s1x, s1y, s2x, s2y)) return true;
    if (point_in_triangle(mx, my, s0x, s0y, s2x, s2y, s3x, s3y)) return true;

    return false;
  }

  /**
   * Updates the geometry of the ring arcs for the given axis.
   * The ring arcs are defined by the center position and the axis normal.
   */
  function _updateRingGeom(center) {
    gml_pragma("forceinline");
    self._updateRingArc(0, center);
    self._updateRingArc(1, center);
    self._updateRingArc(2, center);
  }

  /**
   * Updates the geometry of the ring arc for the given axis index and center position.
   * The ring arc is defined by the center position and the axis normal.
   */
  function _updateRingArc(axisIdx, center) {
    gml_pragma("forceinline");
    var axisEnum = (axisIdx == 0) ? UE_GIZMO_AXIS.x : ((axisIdx == 1) ? UE_GIZMO_AXIS.y : UE_GIZMO_AXIS.z);
    
    var rotQ = self._quat0;
    quat_set(rotQ, 0, 0, 0, 1);
    
    // Basis rotation for the ring
    if (axisIdx == 0) quat_set_from_axis_angle(rotQ, [0, 1, 0], 90);
    else if (axisIdx == 1) quat_set_from_axis_angle(rotQ, [1, 0, 0], -90);
    
    if (self.space == "local") {
      var objQ = self._quat1;
      self.object.getWorldQuaternion(objQ);
      quat_multiply(rotQ, objQ);
    }

    // View direction in ring local space to find the arc center
    var viewDir = self._vec0;
    vec3_copy(viewDir, self.camera.position);
    vec3_sub(viewDir, center);

    var invRot = self._quat1;
    quat_copy(invRot, rotQ);
    quat_invert(invRot);
    vec3_apply_quaternion(viewDir, invRot);

    var midAngle = arctan2(viewDir[1], viewDir[0]);
    var r = self.axisLength; // Fixed radius 1.0 * axisLength
    
    var steps = 32;
    var range = pi;
    var stepRad = range / steps;
    var startAngle = midAngle - range * 0.5;

    var points2D = self._ringCache[axisEnum];
    if (points2D == undefined) {
      points2D = array_create(steps + 1);
      for (var i = 0; i <= steps; i++) points2D[i] = [0, 0]; // Pre-allocate sub-arrays
      self._ringCache[axisEnum] = points2D;
    }

    var pLocal = self._vec2;
    var m = self._matViewProj;

    for (var i = 0; i <= steps; i++) {
      var a = startAngle + stepRad * i;
      vec3_set(pLocal, cos(a) * r, sin(a) * r, 0);
      vec3_apply_quaternion(pLocal, rotQ);
      
      // Project the offset vector into "unscaled screen space"
      points2D[i][0] = m[0] * pLocal[0] + m[4] * pLocal[1] + m[8] * pLocal[2];
      points2D[i][1] = m[1] * pLocal[0] + m[5] * pLocal[1] + m[9] * pLocal[2];
    }
  }

  /**
   * Draws the ring arc for the given axis.
   * The ring arc is defined by the center position and the axis normal.
   */
  function _drawRing(axis) {
    gml_pragma("forceinline");
    if (self._ringCache == undefined) return;
    var col = self._getAxisColor(axis);
    var points2D = self._ringCache[axis];

    if (points2D != undefined && array_length(points2D) > 1) {
      var fx = (self._projFactorX / self._ringOriginW) * self._gizmoScale;
      var fy = (self._projFactorY / self._ringOriginW) * self._gizmoScale;
      
      draw_primitive_begin(pr_trianglestrip);
      self._drawThickLineStrip(points2D, self.lineWidth, col, self._ringOrigin2D[0], self._ringOrigin2D[1], fx, fy);
      draw_primitive_end();
    }
  }

  /**
   * Checks if the mouse position (mx, my) is within the click threshold of the ring arc for the given axis.
   * The ring arc is defined by the center position and the axis normal.
   */
  function _pickRing(axis, mx, my, threshold) {
    gml_pragma("forceinline");
    if (self._ringCache == undefined) return false;
    var points2D = self._ringCache[axis];

    if (points2D == undefined) return false;

    var pMouse = [mx, my];
    var cx = self._ringOrigin2D[0];
    var cy = self._ringOrigin2D[1];
    var fx = (self._projFactorX / self._ringOriginW) * self._gizmoScale;
    var fy = (self._projFactorY / self._ringOriginW) * self._gizmoScale;
    
    var prevP2 = self._vec2D_0;
    var currP2 = self._vec2D_1;
    var isFirst = true;

    for (var i = 0, il = array_length(points2D); i < il; i++) {
      var p = points2D[i];
      currP2[0] = p[0] * fx + cx;
      currP2[1] = p[1] * fy + cy;

      if (!isFirst) {
        var d = vec2_distance_to_segment(pMouse, prevP2, currP2);
        if (d < threshold) return true;
      }
      
      prevP2[0] = currP2[0];
      prevP2[1] = currP2[1];
      isFirst = false;
    }
    return false;
  }

  /**
   * Draws a thick line strip between the given points.
   * The line strip is defined by an array of 2D points (x, y).
   * The width is the thickness of the line strip.
   * The color is the color of the line strip.
   * The offsetX and offsetY are the offset to apply to the points.
   * The scaleX and scaleY are the scale to apply to the points.
   */
  function _drawThickLineStrip(points, width, color, offsetX = 0, offsetY = 0, scaleX = 1, scaleY = 1) {
    gml_pragma("forceinline");
    var halfW = width * 0.5;
    draw_set_color(color);
    for (var i = 0; i < array_length(points) - 1; i++) {
      var p1 = points[i];
      var p2 = points[i + 1];

      var p1x = p1[0] * scaleX + offsetX;
      var p1y = p1[1] * scaleY + offsetY;
      var p2x = p2[0] * scaleX + offsetX;
      var p2y = p2[1] * scaleY + offsetY;

      var dirX = p2x - p1x;
      var dirY = p2y - p1y;
      var len = sqrt(dirX * dirX + dirY * dirY);
      if (len == 0) continue;
      dirX /= len; dirY /= len;

      var perpX = -dirY * halfW;
      var perpY = dirX * halfW;

      draw_vertex(p1x + perpX, p1y + perpY);
      draw_vertex(p1x - perpX, p1y - perpY);
      draw_vertex(p2x + perpX, p2y + perpY);
      draw_vertex(p2x - perpX, p2y - perpY);
    }
  }

  function _worldToScreen(worldPos, viewProjMat, out = undefined) {
    gml_pragma("forceinline");
    var m = viewProjMat;
    var cw = m[3] * worldPos[0] + m[7] * worldPos[1] + m[11] * worldPos[2] + m[15];

    if (cw <= 0) return undefined;

    var cx = m[0] * worldPos[0] + m[4] * worldPos[1] + m[8] * worldPos[2] + m[12];
    var cy = m[1] * worldPos[0] + m[5] * worldPos[1] + m[9] * worldPos[2] + m[13];

    var ndcX = cx / cw;
    var ndcY = cy / cw;

    var res = out ?? self._vec2D;
    res[0] = ndcX * self._projFactorX + self._projOffsetX;
    res[1] = ndcY * self._projFactorY + self._projOffsetY;

    return res;
  }

  function _screenToWorldDir(mx, my) {
    gml_pragma("forceinline");
    var winW = window_get_width();
    var winH = window_get_height();
    var guiW = display_get_gui_width();
    var guiH = display_get_gui_height();

    var winX = mx * (winW / guiW);
    var winY = my * (winH / guiH);

    var vx = view_xport[self.view];
    var vy = view_yport[self.view];
    var vw = view_wport[self.view];
    var vh = view_hport[self.view];

    var localX = (winX - vx) / vw;
    var localY = (winY - vy) / vh;

    var ndcX = localX * 2 - 1;
    var ndcY = localY * 2 - 1;

    var invVP = self._mat0;
    mat4_copy(invVP, self._matViewProj);
    mat4_invert(invVP);

    var cx = ndcX;
    var cy = ndcY;
    var cz = 1;
    var cw = 1;

    var ox = invVP[0] * cx + invVP[4] * cy + invVP[8] * cz + invVP[12] * cw;
    var oy = invVP[1] * cx + invVP[5] * cy + invVP[9] * cz + invVP[13] * cw;
    var oz = invVP[2] * cx + invVP[6] * cy + invVP[10] * cz + invVP[14] * cw;
    var ow = invVP[3] * cx + invVP[7] * cy + invVP[11] * cz + invVP[15] * cw;

    if (ow != 0) { ox /= ow; oy /= ow; oz /= ow; }

    var dir = vec3_create();
    vec3_set(dir, ox - self.camera.position[0], oy - self.camera.position[1], oz - self.camera.position[2]);
    vec3_normalize(dir);

    return dir;
  }

  /**
   * Computes the direction of a ray from the screen coordinates (mx, my) to the world.
   * The screen coordinates are normalized to the viewport coordinates.
   * Returns the direction of the ray as a 3D vector, or undefined if the ray is not visible.
   */
  // function _screenToWorldDirViewport(mx, my) {
  //   gml_pragma("forceinline");
  //   var winW = window_get_width();
  //   var winH = window_get_height();
  //   var guiW = display_get_gui_width();
  //   var guiH = display_get_gui_height();

  //   var winX = mx * (winW / guiW);
  //   var winY = my * (winH / guiH);

  //   var vx = view_xport[self.view];
  //   var vy = view_yport[self.view];
  //   var vw = view_wport[self.view];
  //   var vh = view_hport[self.view];

  //   if (winX < vx || winX > vx + vw || winY < vy || winY > vy + vh)
  //     return undefined;

  //   // poi chiama la versione libera
  //   return _screenToWorldDir(mx, my);
  // }

  /**
   * Computes the intersection point of a ray with a plane.
   * The ray is defined by the origin and direction.
   * The plane is defined by the origin and normal.
   * Returns the intersection point as a 3D vector, or undefined if no intersection.
   */
  function _computePlaneIntersection(mx, my, planeOrigin, planeNormal) {
    gml_pragma("forceinline");
    var rayDir = self._screenToWorldDir(mx, my);
    if (rayDir == undefined) return undefined;

    // Use Unique Math Ray Intersection
    var ray = global.UE_RAY_TEMP0;
    ray_set(ray, self.camera.position, rayDir);

    // Plane equation: dot(normal, x) + d = 0  => d = -dot(normal, planeOrigin)
    var d = -vec3_dot(planeNormal, planeOrigin);
    var plane = [planeNormal[0], planeNormal[1], planeNormal[2], d];

    return ray_intersect_plane(ray, plane);
  }
}
