enum UE_GIZMO_AXIS {
  x, y, z
}

/**
 * UeGizmoControls constructor
 * Lightweight 2D gizmo controls using mathematical raycasting and primitive drawing.
 * Optimized for editor usage.
 * @param {Struct} camera - Camera used for projection.
 * @param {Struct} data - Optional initial settings.
 */
function UeGizmoControls(camera, data = {}): UeControls(data) constructor {
  self.camera = camera;
  self.object = undefined;
  self.mode = "move"; // "move", "rotate", "scale"
  self.space = "world";    // "world", "local"
  self.size = 1.0;         // Gizmo size multiplier
  self.enabled = true;

  self.hoveredAxis = undefined;
  self.selectedAxis = undefined;
  self.dragging = false;
  self.axis = undefined;

  // Internal state
  self._dragStartPoint = vec3_create();     // World position when drag started
  self._dragStartRot = [0, 0, 0, 1];           // Rotation when drag started
  self._dragStartScale = vec3_create();     // Scale when drag started
  self._dragOffset = 0;                     // Linear offset (t) at start
  self._dragAngleStart = 0;                 // Angle at start

  // Math Caches
  self._matViewProj = mat4_create();
  self._vec0 = vec3_create();
  self._vec1 = vec3_create();
  self._vec2 = vec3_create();
  self._quat0 = [0, 0, 0, 1];
  self._mat0 = mat4_create();

  // Drawing Config
  self.lineWidth = 3;
  self.hitThreshold = 15; // Pixel distance for picking
  self.axisLength = 1.5;  // World units length of axes

  // Colors (User Defined Mapping)
  // Red = X
  // Blue = Y (Depth)
  // Lime = Z (Up)
  self.cRed = c_red;
  self.cBlue = make_color_rgb(0x22, 0x77, 0xB3);
  self.cGreen = c_lime;
  self.cWhite = c_white;
  self.cYellow = c_yellow;

  // Geometry Caches
  self._ringCache = undefined;
  self._circlePoints = [];
  var _segs = 64;
  for (var i = 0; i <= _segs; i++) {
    var _a = (i / _segs) * (pi * 2);
    array_push(self._circlePoints, [cos(_a), sin(_a), 0]);
  }

  function setMode(mode) {
    self.mode = mode;
    return self;
  }

  /**
   * Attaches the gizmo to an object.
   */
  function attach(object) {
    self.object = object;

    // Ensure object's world matrix is up-to-date so gizmo uses correct world transforms
    if (object.updateWorldMatrix != undefined) {
      object.updateWorldMatrix(true, false);
    }
    return self;
  }

  /**
   * Detaches the gizmo.
   */
  function detach() {
    self.object = undefined;
    self.hoveredAxis = undefined;
    self.selectedAxis = undefined;
    self.dragging = false;
    return self;
  }

  /**
   * Updates logic (picking, dragging).
   */
  function update() {
    if (!self.object || !self.enabled) return;

    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);

    // 1. Update Object Matrix
    if (self.object.updateWorldMatrix != undefined) {
      self.object.updateWorldMatrix(true, false);
    }

    // 2. Update Camera Matrix & Calculate View Matrix (Inverse World)
    if (variable_struct_exists(self.camera, "updateMatrixWorld")) self.camera.updateMatrixWorld();

    // Manually invert to ensure fresh View Matrix
    if (self.camera.matrixWorldInverse != undefined) {
      var inv = mat4_clone(self.camera.matrixWorld);
      mat4_invert(inv);
      mat4_copy(self.camera.matrixWorldInverse, inv);
    }

    // 3. Calculate MVP: View * Projection
    matrix_multiply(self.camera.matrixWorldInverse, self.camera.projectionMatrix, self._matViewProj);

    // Gizmo Origin in World Space
    self.object.getWorldPosition(self._dragStartPoint);
    var centerPos = vec3_clone(self._dragStartPoint);

    // Scale logic
    var scale = self._computeGizmoScale(centerPos);

    // OPTIMIZATION: Update Ring Geometry Cache once per frame
    self._updateRingGeom(centerPos, scale);

    // --- DRAGGING LOGIC ---
    if (self.dragging && self.selectedAxis != undefined) {
      if (mouse_check_button_released(mb_left)) {
        self.dragging = false;
        self.selectedAxis = undefined;
        return;
      }

      _handleDrag(mx, my, centerPos, scale);
      return;
    }

    // --- PICKING LOGIC ---
    if (mouse_check_button_pressed(mb_left) && self.hoveredAxis != undefined) {
      self._startDrag(mx, my, centerPos, scale);
      return;
    }

    self.hoveredAxis = undefined;
    var minDist = self.hitThreshold;

    var origin2D = self._worldToScreen(centerPos, self._matViewProj);
    if (origin2D == undefined) return; // Behind camera

    // Check Axes
    if (self.mode == "move" || self.mode == "scale") {
      // X Axis
      if (self._pickArrow(UE_GIZMO_AXIS.x, centerPos, scale, mx, my, minDist)) {
        self.hoveredAxis = UE_GIZMO_AXIS.x; minDist = 0;
      }
      // Y Axis
      else if (self._pickArrow(UE_GIZMO_AXIS.y, centerPos, scale, mx, my, minDist)) {
        self.hoveredAxis = UE_GIZMO_AXIS.y; minDist = 0;
      }
      // Z Axis
      else if (self._pickArrow(UE_GIZMO_AXIS.z, centerPos, scale, mx, my, minDist)) {
        self.hoveredAxis = UE_GIZMO_AXIS.z; minDist = 0;
      }
    }
    else if (self.mode == "rotate") {
      // Use Cached Rings for Picking
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
    if (!self.object || !self.enabled) return;

    // Ensure matrices are fresh for rendering frame
    if (variable_struct_exists(self.camera, "updateMatrixWorld")) self.camera.updateMatrixWorld();

    matrix_multiply(self.camera.matrixWorldInverse, self.camera.projectionMatrix, self._matViewProj);

    self.object.getWorldPosition(self._vec0);
    var centerPos = vec3_clone(self._vec0);
    var scale = self._computeGizmoScale(centerPos);

    var origin2D = self._worldToScreen(centerPos, self._matViewProj);
    if (origin2D == undefined) return;

    // Draw Modes
    if (self.mode == "move") {
      self._drawArrow(UE_GIZMO_AXIS.x, centerPos, scale, origin2D);
      self._drawArrow(UE_GIZMO_AXIS.y, centerPos, scale, origin2D);
      self._drawArrow(UE_GIZMO_AXIS.z, centerPos, scale, origin2D);
    } else if (self.mode == "scale") {
      self._drawScaleHandle(UE_GIZMO_AXIS.x, centerPos, scale, origin2D);
      self._drawScaleHandle(UE_GIZMO_AXIS.y, centerPos, scale, origin2D);
      self._drawScaleHandle(UE_GIZMO_AXIS.z, centerPos, scale, origin2D);
    } else if (self.mode == "rotate") {
      self._drawRing(UE_GIZMO_AXIS.x);
      self._drawRing(UE_GIZMO_AXIS.y);
      self._drawRing(UE_GIZMO_AXIS.z);
    }
  }

  function _startDrag(mx, my, centerPos, scale) {
    self.dragging = true;
    self.selectedAxis = self.hoveredAxis;
    self.axis = self.hoveredAxis;

    // Store Start State
    vec3_copy(self._dragStartPoint, self.object.position);
    quat_copy(self._dragStartRot, self.object.rotation);
    vec3_copy(self._dragStartScale, self.object.scale);

    if (self.mode == "move" || self.mode == "scale") {
      // Project initial mouse hit onto axis line
      self._dragOffset = self._computeAxisProjection(mx, my, centerPos, self.axis);
    } else if (self.mode == "rotate") {
      // Compute Initial Angle on Screen relative to center
      var origin2D = self._worldToScreen(centerPos, self._matViewProj);
      if (origin2D != undefined) {
        self._dragAngleStart = arctan2(my - origin2D[1], mx - origin2D[0]);
      }
    }
  }

  function _handleDrag(mx, my, centerPos, scale) {
    if (self.mode == "move") {
      var currT = self._computeAxisProjection(mx, my, centerPos, self.axis);
      if (currT == undefined || self._dragOffset == undefined) return;

      var delta = currT - self._dragOffset;

      // Apply Delta to Position
      var axisVec = self._vec1;
      self._getAxisVector(self.axis, axisVec);

      var moveVec = vec3_clone(axisVec);
      vec3_multiply_scalar(moveVec, delta);

      // Transform to Local Space logic
      if (self.space == "local") {
        if (self.object.parent != undefined) {
          var parentInv = mat4_clone(self.object.parent.matrixWorld);
          mat4_invert(parentInv);
          mat4_set_position(parentInv, 0, 0, 0);
          vec3_apply_matrix4(moveVec, parentInv);
        }
        var newPos = vec3_clone(self._dragStartPoint);
        vec3_add(newPos, moveVec);
        vec3_copy(self.object.position, newPos);

      } else { // World Space Axis
        if (self.object.parent != undefined) {
          var parentInv = mat4_clone(self.object.parent.matrixWorld);
          mat4_invert(parentInv);
          mat4_set_position(parentInv, 0, 0, 0);
          vec3_apply_matrix4(moveVec, parentInv);
        }
        var newPos = vec3_clone(self._dragStartPoint);
        vec3_add(newPos, moveVec);
        vec3_copy(self.object.position, newPos);
      }

      // IMPORTANT: Immediately update world matrix to prevent jitter
      self.object.updateWorldMatrix(true, false);

    } else if (self.mode == "scale") {
      var currT = self._computeAxisProjection(mx, my, centerPos, self.axis);
      if (currT == undefined) return;

      var delta = (currT - self._dragOffset) * 0.1; // Reduced sensitivity

      var scaleAxis = (self.axis == UE_GIZMO_AXIS.x) ? 0 : ((self.axis == UE_GIZMO_AXIS.y) ? 1 : 2);
      var newScale = vec3_clone(self._dragStartScale);

      newScale[scaleAxis] += delta;
      vec3_copy(self.object.scale, newScale);
      self.object.updateWorldMatrix(true, false);

    } else if (self.mode == "rotate") {
      var origin2D = self._worldToScreen(centerPos, self._matViewProj);
      if (origin2D != undefined) {
        var currAngle = arctan2(my - origin2D[1], mx - origin2D[0]);
        var deltaAngle = currAngle - self._dragAngleStart;

        // Invert rotation if camera is looking "along" the axis
        var camDir = global.UE_VEC3_TEMP2;
        self.camera.getWorldDirection(camDir);
        var axisVec = self._vec1;
        self._getAxisVector(self.axis, axisVec);

        // If angle between View and Axis is acute (<90), we are "behind" -> Flip
        if (vec3_dot(camDir, axisVec) > 0) {
          deltaAngle = -deltaAngle;
        }

        var qDelta = global.UE_QUAT_TEMP0;
        quat_set_from_axis_angle(qDelta, axisVec, radtodeg(deltaAngle));

        var newRot = quat_clone(self._dragStartRot);

        if (self.space == "local") {
          quat_multiply(newRot, qDelta);
        } else {
          quat_premultiply(newRot, qDelta);
        }

        quat_copy(self.object.rotation, newRot);
        self.object.updateWorldMatrix(true, false);
      }
    }
  }

  function _computeAxisProjection(mx, my, centerPos, axisName) {
    var axisVec = self._vec1;
    self._getAxisVector(axisName, axisVec);

    var camDir = global.UE_VEC3_TEMP2;
    self.camera.getWorldDirection(camDir);

    var planeNormal = vec3_clone(axisVec);
    vec3_cross(planeNormal, camDir);
    vec3_cross(planeNormal, axisVec);

    if (vec3_length(planeNormal) < UE_EPSILON) return undefined;
    vec3_normalize(planeNormal);

    var rayOrigin = self.camera.position;
    var rayDir = self._screenToWorldDir(mx, my);
    if (rayDir == undefined) return undefined;

    var denom = vec3_dot(rayDir, planeNormal);
    if (abs(denom) < UE_EPSILON) return 0;

    var p0lo = vec3_clone(centerPos);
    vec3_sub(p0lo, rayOrigin);
    var t = vec3_dot(p0lo, planeNormal) / denom;

    var hitPoint = vec3_clone(rayDir);
    vec3_multiply_scalar(hitPoint, t);
    vec3_add(hitPoint, rayOrigin);

    vec3_sub(hitPoint, centerPos);
    return vec3_dot(hitPoint, axisVec);
  }

  // --- INTERNAL HELPERS ---

  function _computeGizmoScale(pos) {
    if (is_nan(pos[0]) || is_nan(pos[1]) || is_nan(pos[2])) return self.size;
    var dist = vec3_distance_to(self.camera.position, pos);
    if (is_nan(dist) || dist == infinity) return self.size;
    return dist * 0.15 * self.size;
  }

  function _getAxisVector(axis, out) {
    vec3_set(out, 0, 0, 0);
    if (axis == UE_GIZMO_AXIS.x) out[0] = 1;
    else if (axis == UE_GIZMO_AXIS.y) out[1] = 1;
    else if (axis == UE_GIZMO_AXIS.z) out[2] = 1;

    if (self.space == "local" && self.object) {
      var q = global.UE_QUAT_TEMP0;
      self.object.getWorldQuaternion(q);
      vec3_apply_quaternion(out, q);
    }
    return out;
  }

  function _getAxisColor(axis) {
    if (self.hoveredAxis == axis || self.selectedAxis == axis) return self.cYellow;
    if (axis == UE_GIZMO_AXIS.x) return self.cRed;
    if (axis == UE_GIZMO_AXIS.y) return self.cBlue;
    if (axis == UE_GIZMO_AXIS.z) return self.cGreen;
    return c_white;
  }

  function _drawArrow(axis, center, scale, origin2D) {
    var endPos = vec3_clone(center);
    self._getAxisVector(axis, self._vec1);
    vec3_add_scaled_vector(endPos, self._vec1, self.axisLength * scale);

    var end2D = self._worldToScreen(endPos, self._matViewProj);
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

      draw_line_width_color(origin2D[0], origin2D[1], lineEndX, lineEndY, self.lineWidth, col, col);
      draw_triangle_color(p1x, p1y, p2x, p2y, p3x, p3y, col, col, col, false);
    }
  }

  function _pickArrow(axisName, center, scale, mx, my, threshold) {
    var endPos = vec3_clone(center);
    self._getAxisVector(axisName, self._vec1);
    vec3_add_scaled_vector(endPos, self._vec1, self.axisLength * scale);

    var origin2D = self._worldToScreen(center, self._matViewProj);
    var end2D = self._worldToScreen(endPos, self._matViewProj);

    if (origin2D != undefined && end2D != undefined) {
      var d = self._distanceToSegment([mx, my], origin2D, end2D);
      return (d < threshold);
    }
    return false;
  }

  function _drawScaleHandle(axisName, center, scale, origin2D) {
    var endPos = vec3_clone(center);
    self._getAxisVector(axisName, self._vec1);
    vec3_add_scaled_vector(endPos, self._vec1, self.axisLength * scale);

    var end2D = self._worldToScreen(endPos, self._matViewProj);
    if (end2D == undefined) return;

    var col = self._getAxisColor(axisName);

    draw_line_width_color(origin2D[0], origin2D[1], end2D[0], end2D[1], self.lineWidth, col, col);
    // Box Tip
    var s = self.lineWidth * 2.5;
    draw_rectangle_color(end2D[0] - s, end2D[1] - s, end2D[0] + s, end2D[1] + s, col, col, col, col, false);
  }

  function _updateRingGeom(center, scale) {
    if (self._ringCache == undefined) self._ringCache = [ [], [], [] ];
    // X
    self._ringCache[0] = self._getRingArcPoints(UE_GIZMO_AXIS.x, center, scale, 24);
    // Y
    self._ringCache[1] = self._getRingArcPoints(UE_GIZMO_AXIS.y, center, scale, 24);
    // Z
    self._ringCache[2] = self._getRingArcPoints(UE_GIZMO_AXIS.z, center, scale, 24);
  }

  function _getRingArcPoints(axis, center, scale, steps) {
    var rotQ = global.UE_QUAT_TEMP0;
    quat_set(rotQ, 0, 0, 0, 1);
    if (axis == UE_GIZMO_AXIS.x) quat_set_from_axis_angle(rotQ, [0, 1, 0], 90);
    else if (axis == UE_GIZMO_AXIS.y) quat_set_from_axis_angle(rotQ, [1, 0, 0], -90);
    if (self.space == "local") {
      var objQ = global.UE_QUAT_TEMP1;
      self.object.getWorldQuaternion(objQ);
      quat_multiply(rotQ, objQ);
    }

    // Calculate View Vector relative to center
    var viewDir = vec3_clone(self.camera.position);
    vec3_sub(viewDir, center);

    // Transform ViewDir into Ring Local Space (InvRot * ViewDir)
    var invRot = quat_clone(rotQ);
    quat_invert(invRot);
    vec3_apply_quaternion(viewDir, invRot);

    // Arc Center Angle
    var midAngle = arctan2(viewDir[1], viewDir[0]);

    var points = [];
    var r = self.axisLength * scale;

    // Generate Semi-Circle (Pi)
    var range = pi;
    var stepRad = range / steps;
    var startAngle = midAngle - range * 0.5;

    for (var i = 0; i <= steps; i++) {
      var a = startAngle + stepRad * i;

      var p3 = [cos(a) * r, sin(a) * r, 0];
      vec3_apply_quaternion(p3, rotQ);
      vec3_add(p3, center);

      var p2 = self._worldToScreen(p3, self._matViewProj);
      if (p2 != undefined) array_push(points, p2);
    }
    return points;
  }

  function _drawRing(axis) {
    if (self._ringCache == undefined) return;
    var col = self._getAxisColor(axis);
    var points2D = self._ringCache[axis];

    if (points2D != undefined && array_length(points2D) > 1) {
      draw_primitive_begin(pr_trianglestrip);
      self._drawThickLineStrip(points2D, self.lineWidth, col);
      draw_primitive_end();
    }
  }

  function _pickRing(axis, mx, my, threshold) {
    if (self._ringCache == undefined) return false;
    var points2D = self._ringCache[axis];

    if (points2D == undefined) return false;

    var prevP2 = undefined;
    for (var i = 0, il = array_length(points2D); i < il; i++) {
      var p2 = points2D[i];
      if (prevP2 != undefined) {
        var d = self._distanceToSegment([mx, my], prevP2, p2);
        if (d < threshold) return true;
      }
      prevP2 = p2;
    }
    return false;
  }

  function _drawThickLineStrip(points, width, color) {
    var halfW = width * 0.5;
    draw_set_color(color);
    for (var i = 0; i < array_length(points) - 1; i++) {
      var p1 = points[i];
      var p2 = points[i + 1];

      var dirX = p2[0] - p1[0];
      var dirY = p2[1] - p1[1];
      var len = sqrt(dirX * dirX + dirY * dirY);
      if (len == 0) continue;
      dirX /= len; dirY /= len;

      var perpX = -dirY * halfW;
      var perpY = dirX * halfW;

      draw_vertex(p1[0] + perpX, p1[1] + perpY);
      draw_vertex(p1[0] - perpX, p1[1] - perpY);
      draw_vertex(p2[0] + perpX, p2[1] + perpY);
      draw_vertex(p2[0] - perpX, p2[1] - perpY);
    }
  }

  function _worldToScreen(worldPos, viewProjMat) {
    var _x = worldPos[0], _y = worldPos[1], _z = worldPos[2], _w = 1;

    var m = viewProjMat;

    var cx = m[0] * _x + m[4] * _y + m[8] * _z + m[12];
    var cy = m[1] * _x + m[5] * _y + m[9] * _z + m[13];
    var cz = m[2] * _x + m[6] * _y + m[10] * _z + m[14];
    var cw = m[3] * _x + m[7] * _y + m[11] * _z + m[15];

    if (cw <= 0) return undefined;

    var ndcX = cx / cw;
    var ndcY = cy / cw;

    // NDC → VIEWPORT (non window!)
    var vx = view_xport[0];
    var vy = view_yport[0];
    var vw = view_wport[0];
    var vh = view_hport[0];

    var screenX = vx + (ndcX + 1) * 0.5 * vw;
    var screenY = vy + ((ndcY + 1) * 0.5) * vh;

    // Viewport → GUI
    var guiW = display_get_gui_width();
    var guiH = display_get_gui_height();
    var winW = window_get_width();
    var winH = window_get_height();

    screenX *= guiW / winW;
    screenY *= guiH / winH;

    if (is_nan(screenX) || is_nan(screenY)) return undefined;

    return [screenX, screenY];
  }

  function _screenToWorldDir(mx, my) {
    var winW = window_get_width();
    var winH = window_get_height();
    var guiW = display_get_gui_width();
    var guiH = display_get_gui_height();

    // GUI → Window
    var winX = mx * (winW / guiW);
    var winY = my * (winH / guiH);

    // Window → Viewport local
    var vx = view_xport[0];
    var vy = view_yport[0];
    var vw = view_wport[0];
    var vh = view_hport[0];

    // Fuori dalla viewport → niente picking
    if (winX < vx || winX > vx + vw || winY < vy || winY > vy + vh)
      return undefined;

    var localX = (winX - vx) / vw;
    var localY = (winY - vy) / vh;

    // Viewport → NDC (NO flip Y)
    var ndcX = localX * 2 - 1;
    var ndcY = localY * 2 - 1;

    // Inverse ViewProjection
    var invVP = mat4_clone(self._matViewProj);
    mat4_invert(invVP);

    // Clip space (far plane)
    var cx = ndcX;
    var cy = ndcY;
    var cz = 1.0;
    var cw = 1.0;

    // Clip → World
    var ox = invVP[0] * cx + invVP[4] * cy + invVP[8] * cz + invVP[12] * cw;
    var oy = invVP[1] * cx + invVP[5] * cy + invVP[9] * cz + invVP[13] * cw;
    var oz = invVP[2] * cx + invVP[6] * cy + invVP[10] * cz + invVP[14] * cw;
    var ow = invVP[3] * cx + invVP[7] * cy + invVP[11] * cz + invVP[15] * cw;

    if (ow != 0) {
      ox /= ow; oy /= ow; oz /= ow;
    }

    var farPos = [ox, oy, oz];

    // Ray direction
    var dir = vec3_create();
    vec3_sub_vectors(dir, farPos, self.camera.position);
    vec3_normalize(dir);

    return dir;
  }


  function _distanceToSegment(p, a, b) {
    if (is_nan(a[0]) || is_nan(a[1]) || is_nan(b[0]) || is_nan(b[1])) return infinity;

    var dx = b[0] - a[0];
    var dy = b[1] - a[1];
    var l2 = dx * dx + dy * dy;

    if (l2 == 0 || is_nan(l2)) {
      var dpx = p[0] - a[0];
      var dpy = p[1] - a[1];
      var distSq = dpx * dpx + dpy * dpy;
      return is_nan(distSq) ? infinity : sqrt(distSq);
    }

    var t = ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / l2;
    t = clamp(t, 0, 1);

    var projX = a[0] + t * dx;
    var projY = a[1] + t * dy;

    var ddx = p[0] - projX;
    var ddy = p[1] - projY;
    var finalDistSq = ddx * ddx + ddy * ddy;

    if (is_nan(finalDistSq)) return infinity;
    return sqrt(finalDistSq);
  }
}
