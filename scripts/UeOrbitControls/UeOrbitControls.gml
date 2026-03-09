/// UeOrbitControls
/// 
/// Controls:
/// - Alt + Left Mouse: Orbit (rotate around target)
/// - Middle Mouse: Pan (move camera laterally)
/// - Scroll Wheel / Alt + Right Mouse: Zoom
/// - Right Mouse (hold): Flythrough mode (FPS-style)
///   - WASD: Move forward/left/backward/right
///   - Q/E: Move down/up
///   - Shift: Double movement speed
///   - Scroll Wheel: Adjust flythrough speed
///
function UeOrbitControls(camera, uiSceneNode, data = {}): UeControls(data) constructor {
    self.camera = camera;
    self.uiSceneNode = uiSceneNode; // Reference to ui.Main.Scene for bounds checking
    self.onChange = data[$ "onChange"];
    
    // Target settings
    var _initialTarget = data[$ "target"] ?? vec3_create(data[$ "xt"] ?? 0, data[$ "yt"] ?? 0, data[$ "zt"] ?? 0);
    self.target = is_array(_initialTarget) ? vec3_clone(_initialTarget) : vec3_create();
    
    self.targetObject = undefined;
    self.targetOffset = vec3_create();
    self.sizeFactor = 1.0;
    self.__scratchBox = box3_create();
    
    // Spherical coordinates
    var cp = camera.position;
    var ct = self.target;
    if (!is_nan(cp[0] + cp[1] + cp[2] + ct[0] + ct[1] + ct[2])) {
        var dir = vec3_clone(cp); vec3_sub(dir, ct);
        self.radius = vec3_distance_to(cp, ct);
        self.azimuth = arctan2(dir[VEC3.y], dir[VEC3.x]);
        self.elevation = self.radius == 0 ? 0 : arcsin(clamp(dir[VEC3.z] / self.radius, -1, 1));
    } else {
        self.radius = 10;
        self.azimuth = 0;
        self.elevation = 0;
    }
    
    // Orbit settings
    self.enableZoom = data[$"enableZoom"] ?? true;
    self.zoomSpeed = data[$"zoomSpeed"] ?? 0.2; // Even slower default
    self.minTargetRadius = data[$"minTargetRadius"] ?? 0.0001; // Allow almost zero zoom
    self.maxTargetRadius = data[$"maxTargetRadius"] ?? infinity;
    
    self.enablePan = data[$"enablePan"] ?? true;
    self.panSpeed = data[$"panSpeed"] ?? 10.0;
    
    self.enableRotate = data[$"enableRotate"] ?? true;
    self.rotateSpeed = data[$"rotateSpeed"] ?? 1.0;
    
    self.enableDamping = data[$"enableDamping"] ?? true;
    self.dampingFactor = data[$"dampingFactor"] ?? 1.0;
    
    self.autoRotate = data[$"autoRotate"] ?? false;
    self.autoRotateSpeed = data[$"autoRotateSpeed"] ?? 0.5;
    
    self.screenSpacePanning = data[$"screenSpacePanning"] ?? true; // Default true for screen-aligned panning
    
    // Flythrough mode settings
    self.enableFlythrough = data[$"enableFlythrough"] ?? true;
    self.flythroughSpeed = data[$"flythroughSpeed"] ?? 5.0;
    self.flythroughSpeedMultiplier = 2.0; // When shift is pressed
    self.flythroughSpeedMin = 0.1;
    self.flythroughSpeedMax = 1000.0;
    self.flythroughActive = false;
    self.flythroughYaw = 0;
    self.flythroughPitch = 0;
    self.flythroughSensitivity = 0.003; // Mouse sensitivity for FPS mode
    self.flythroughSpeedDisplayTime = 0; // Timer for speed display
    
    // Keys configuration
    self.keys = {
        // Orbit keys (exist for compatibility)
        LEFT: vk_left,
        UP: vk_up,
        RIGHT: vk_right,
        BOTTOM: vk_down,
        SHIFT: vk_shift,
        
        // Flythrough keys
        FORWARD: ord("W"),
        BACKWARD: ord("S"),
        LEFT_STRAFE: ord("A"),
        RIGHT_STRAFE: ord("D"),
        UP_MOVE: ord("E"),
        DOWN_MOVE: ord("Q"),
        
        // Modifiers
        ALT: vk_alt
    };
    
    // State tracking
    self._orbitActive = false;
    self._panActive = false;
    self._altZoomActive = false;
    self.transforming = false;
    
    // Delta values for damping
    self._deltaAzimuth = 0;
    self._deltaElevation = 0;
    self._deltaPan = vec3_create();
    self._needsUpdate = true;
    
    // Mouse tracking
    self._prevMouseX = 0;
    self._prevMouseY = 0;
    
    // Scene bounds cache (updated each frame)
    self._sceneBounds = {
        x1: 0,
        y1: 0,
        x2: window_get_width(),
        y2: window_get_height()
    };
    
    // Scratch vectors
    self.__scratchVec0 = vec3_create();
    self.__scratchVec1 = vec3_create();
    self.__scratchVec2 = vec3_create();
    
    /// Reset camera to initial state
    function reset() {
        gml_pragma("forceinline");
        vec3_set(self.target, 0, 0, 0);
        
        var cp = camera.position;
        var ct = self.target;
        if (!is_nan(cp[0] + cp[1] + cp[2] + ct[0] + ct[1] + ct[2])) {
            var dir = vec3_sub_vectors(self.__scratchVec0, cp, ct);
            self.radius = vec3_distance_to(cp, ct);
            self.azimuth = arctan2(dir[VEC3.y], dir[VEC3.x]);
            self.elevation = self.radius == 0 ? 0 : arcsin(clamp(dir[VEC3.z] / self.radius, -1, 1));
        }
        
        self._needsUpdate = true;
        if (self.onChange != undefined) self.onChange();
    }
    
    /// Update spherical coordinates from current camera position
    function updateSphericalCoordinates() {
        var cp = camera.position;
        var ct = self.target;
        if (is_nan(cp[0] + cp[1] + cp[2] + ct[0] + ct[1] + ct[2])) return;
        
        var dir = vec3_sub_vectors(self.__scratchVec0, cp, ct);
        self.radius = vec3_distance_to(cp, ct);
        self.azimuth = arctan2(dir[VEC3.y], dir[VEC3.x]);
        self.elevation = self.radius == 0 ? 0 : arcsin(clamp(dir[VEC3.z] / self.radius, -1, 1));
        
        self._deltaAzimuth = 0;
        self._deltaElevation = 0;
        vec3_set(self._deltaPan, 0, 0, 0);
        self._needsUpdate = true;
    }
    
    /// Set the orbit target
    function setTarget(newTarget) {
        vec3_set(self.targetOffset, 0, 0, 0);
        if (typeof (newTarget) == "struct" && (newTarget[$ "isObject3D"] || newTarget[$ "isMesh"])) {
            self.targetObject = newTarget;
            newTarget.getWorldPosition(self.target);
            
            // Determine size factor for zoom limits from geometry bbox if available
            var geom = newTarget[$ "geometry"];
            if (geom != undefined && geom[$ "boundingBox"] != undefined) {
                var size = box3_get_size(geom.boundingBox, self.__scratchVec1);
                var worldScale = newTarget.getWorldScale(self.__scratchVec0);
                self.sizeFactor = max(size[0] * worldScale[0], size[1] * worldScale[1], size[2] * worldScale[2]);
            } else {
                self.sizeFactor = vec3_length(newTarget.getWorldScale(self.__scratchVec0));
            }
            if (self.sizeFactor <= 0) self.sizeFactor = 1.0;
            
            // Adjust zoom limits based on size
            self.minTargetRadius = self.sizeFactor * 0.05;
            self.maxTargetRadius = self.sizeFactor * 50.0;
            self.radius = clamp(self.radius, self.minTargetRadius, self.maxTargetRadius);
        } else {
            self.targetObject = undefined;
            self.sizeFactor = 1.0;
            if (is_array(newTarget)) {
                vec3_copy(self.target, newTarget);
            }
        }
        self.updateSphericalCoordinates();
        if (self.onChange != undefined) self.onChange();
    }
    
    /// Focus on an object
    function focus(object) {
        if (!object) return;
        
        var center = object.getWorldPosition(self.__scratchVec0);
        var sizeValue = 1.0;
        
        var geom = object[$ "geometry"];
        if (geom != undefined && geom[$ "boundingBox"] != undefined) {
            var sizeVec = box3_get_size(geom.boundingBox, self.__scratchVec1);
            var worldScale = object.getWorldScale(self.__scratchVec2);
            sizeValue = max(sizeVec[0] * worldScale[0], sizeVec[1] * worldScale[1], sizeVec[2] * worldScale[2]);
        } else {
            sizeValue = vec3_length(object.getWorldScale(self.__scratchVec1)) * 2;
        }
        
        var radius = sizeValue * 0.5;
        var vFov = degtorad(self.camera.fov ?? 60);
        var aspect = self.camera.aspect ?? 1.0;
        
        var distY = radius / tan(vFov * 0.5);
        var distX = radius / (tan(vFov * 0.5) * aspect);
        var distance = max(distX, distY) * 1.8;
        
        var forward = vec3_sub_vectors(self.__scratchVec2, self.camera.position, self.camera.target);
        if (vec3_length_sq(forward) < UE_EPSILON) {
            vec3_set(forward, 0, 0, 1);
        }
        vec3_normalize(forward);
        
        vec3_copy(self.target, center);
        
        self.camera.setPosition(
            self.target[0] + forward[0] * distance,
            self.target[1] + forward[1] * distance,
            self.target[2] + forward[2] * distance
        );
        
        vec3_copy(self.camera.target, self.target);
        
        self._deltaAzimuth = 0;
        self._deltaElevation = 0;
        vec3_set(self._deltaPan, 0, 0, 0);
        self.updateSphericalCoordinates();
        self._needsUpdate = true;
        if (self.onChange != undefined) self.onChange();
    }
    
    /// Check if mouse is inside UI scene bounds
    // function isMouseInSceneBounds(mx, my) {
    //     return (mx >= self._sceneBounds.x1 && mx <= self._sceneBounds.x2 &&
    //             my >= self._sceneBounds.y1 && my <= self._sceneBounds.y2);
    // }
    
    /// Warp mouse when it exits scene bounds (Godot-style)
    function warpMouseIfNeeded(mx, my) {
        var warped = false;
        var newX = mx;
        var newY = my;
        
        // Use window dimensions as absolute limits for warping
        var winW = window_get_width();
        var winH = window_get_height();
        
        var xMin = max(self._sceneBounds.x1, 0);
        var yMin = max(self._sceneBounds.y1, 0);
        var xMax = min(self._sceneBounds.x2, winW);
        var yMax = min(self._sceneBounds.y2, winH);
        
        var width = xMax - xMin;
        var height = yMax - yMin;
        
        if (width <= 0 || height <= 0) return false;
        
        var margin = 10; // Trigger slightly before the edge for better robustness

        if (mx < xMin + margin) {
            newX = xMax - margin - 2;
            warped = true;
        } else if (mx > xMax - margin) {
            newX = xMin + margin + 2;
            warped = true;
        }
        
        if (my < yMin + margin) {
            newY = yMax - margin - 2;
            warped = true;
        } else if (my >= yMax - margin) {
            newY = yMin + margin + 2;
            warped = true;
        }
        
        if (warped) {
            window_mouse_set(newX, newY);
            self._prevMouseX = newX;
            self._prevMouseY = newY;
            return true;
        }
        
        return false;
    }
    
    /// Update camera (main function called each frame)
    function update(mx = undefined, my = undefined) {
        gml_pragma("forceinline");
        
        if (!enabled) return;
        
        // Decrease speed display timer
        if (self.flythroughSpeedDisplayTime > 0) {
            self.flythroughSpeedDisplayTime--;
        }
        
        // Get mouse position (window-relative is more robust for editor controls)
        if (mx == undefined) {
            mx = window_mouse_get_x();
            my = window_mouse_get_y();
        }
        
        // Update scene bounds from UI node
        if (self.uiSceneNode != undefined && self.uiSceneNode.layout != undefined) {
            var layout = self.uiSceneNode.layout;
            self._sceneBounds.x1 = layout.left;
            self._sceneBounds.y1 = layout.top;
            self._sceneBounds.x2 = layout.left + layout.width;
            self._sceneBounds.y2 = layout.top + layout.height;
        }
        
        var allowInteractions = shouldHandleInput();
        
        // Input state
        var altPressed = keyboard_check(self.keys.ALT);
        var shiftPressed = keyboard_check(self.keys.SHIFT);
        var wheelUp = false;
        var wheelDown = false;
        
        if (allowInteractions) {
            wheelUp = mouse_wheel_up();
            wheelDown = mouse_wheel_down();
        }
        
        // Mouse button states
        var leftMouse = mouse_check_button(mb_left);
        var middleMouse = mouse_check_button(mb_middle);
        var rightMouse = mouse_check_button(mb_right);
        
        var leftMousePressed = mouse_check_button_pressed(mb_left);
        var middleMousePressed = mouse_check_button_pressed(mb_middle);
        var rightMousePressed = mouse_check_button_pressed(mb_right);
        
        var anyButtonReleased = mouse_check_button_released(mb_any);
        
        // Determine active mode
        var orbitMode = (allowInteractions || self._orbitActive) && altPressed && leftMouse && self.enableRotate;
        var panMode = (allowInteractions || self._panActive) && middleMouse && self.enablePan;
        var altZoomMode = (allowInteractions || self._altZoomActive) && altPressed && rightMouse && self.enableZoom;
        var flythroughMode = (allowInteractions || self.flythroughActive) && self.enableFlythrough && rightMouse && !altPressed;
        
        // Track mode transitions
        var wasFlythroughActive = self.flythroughActive;
        self.flythroughActive = flythroughMode;
        
        // Initialize flythrough angles when entering flythrough mode
        if (self.flythroughActive && !wasFlythroughActive) {
            // Calculate yaw and pitch from current camera direction
            var forward = vec3_sub_vectors(self.__scratchVec0, self.camera.target, self.camera.position);
            vec3_normalize(forward);
            
            self.flythroughYaw = arctan2(forward[VEC3.y], forward[VEC3.x]);
            self.flythroughPitch = arcsin(clamp(forward[VEC3.z], -1, 1));
            
            self._prevMouseX = mx;
            self._prevMouseY = my;
        }
        
        // Exit flythrough: update orbit coordinates
        if (wasFlythroughActive && !self.flythroughActive) {
            vec3_copy(self.target, self.camera.target);
            self.updateSphericalCoordinates();
        }
        
        // Track orbit/pan state changes
        if ((orbitMode && !self._orbitActive) || (panMode && !self._panActive) || (altZoomMode && !self._altZoomActive)) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
        }
        
        self._orbitActive = orbitMode;
        self._panActive = panMode;
        self._altZoomActive = altZoomMode;
        
        var wasTransforming = self.transforming;
        self.transforming = self._orbitActive || self._panActive || self._altZoomActive || self.flythroughActive;
        
        // Check if we should perform early exit (no input, no damping, no auto-rotate)
        var isDamping = false;
        if (self.enableDamping && !self.flythroughActive) {
            isDamping = abs(self._deltaAzimuth) > 0.0001 ||
                abs(self._deltaElevation) > 0.0001 ||
                vec3_length_sq(self._deltaPan) > 0.0001;
        }
        
        var hasKeyboardInput = allowInteractions && !global.UI.hasAnyFocus() && (
            keyboard_check(self.keys.FORWARD) || keyboard_check(self.keys.BACKWARD) ||
            keyboard_check(self.keys.LEFT_STRAFE) || keyboard_check(self.keys.RIGHT_STRAFE) ||
            keyboard_check(self.keys.UP_MOVE) || keyboard_check(self.keys.DOWN_MOVE)
        );
        
        if (!self.transforming && !isDamping && !self.autoRotate && !self._needsUpdate && 
            !wheelUp && !wheelDown && !hasKeyboardInput && !anyButtonReleased) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
            return;
        }
        
        if (anyButtonReleased) {
            __canInteract = false;
        }
        
        // Calculate mouse delta
        var dx = mx - self._prevMouseX;
        var dy = my - self._prevMouseY;
        
        var worldUp = global.UE_DEFAULT_UP;
        
        // === FLYTHROUGH MODE ===
        if (self.flythroughActive) {
            // Mouse look
            self.flythroughYaw -= dx * self.flythroughSensitivity;
            self.flythroughPitch -= dy * self.flythroughSensitivity;
            self.flythroughPitch = clamp(self.flythroughPitch, -pi * 0.49, pi * 0.49);
            
            // Scroll wheel adjusts flythrough speed
            if (wheelUp) {
                self.flythroughSpeed = clamp(self.flythroughSpeed * 1.2, self.flythroughSpeedMin, self.flythroughSpeedMax);
                self.flythroughSpeedDisplayTime = 120; // Show for 2 seconds at 60fps
            }
            if (wheelDown) {
                self.flythroughSpeed = clamp(self.flythroughSpeed / 1.2, self.flythroughSpeedMin, self.flythroughSpeedMax);
                self.flythroughSpeedDisplayTime = 120; // Show for 2 seconds at 60fps
            }
            
            // Calculate forward/right/up vectors
            var cosPitch = cos(self.flythroughPitch);
            var forward = vec3_set(self.__scratchVec0,
                cos(self.flythroughYaw) * cosPitch,
                sin(self.flythroughYaw) * cosPitch,
                sin(self.flythroughPitch)
            );
            
            var right = vec3_set(self.__scratchVec1, forward[VEC3.y], -forward[VEC3.x], 0);
            vec3_normalize(right);
            
            var up = vec3_copy(self.__scratchVec2, worldUp);
            
            // Movement
            var _speed = self.flythroughSpeed * (shiftPressed ? self.flythroughSpeedMultiplier : 1.0);
            var camPos = self.camera.position;
            
            // Temporary variable for position delta
            var posDelta = self.__scratchVec2;
            vec3_set(posDelta, 0, 0, 0);
            
            if (keyboard_check(self.keys.FORWARD)) {
                vec3_add_scaled_vector(posDelta, forward, _speed);
            }
            if (keyboard_check(self.keys.BACKWARD)) {
                vec3_add_scaled_vector(posDelta, forward, -_speed);
            }
            if (keyboard_check(self.keys.LEFT_STRAFE)) {
                vec3_add_scaled_vector(posDelta, right, -_speed);
            }
            if (keyboard_check(self.keys.RIGHT_STRAFE)) {
                vec3_add_scaled_vector(posDelta, right, _speed);
            }
            if (keyboard_check(self.keys.UP_MOVE)) {
                vec3_add_scaled_vector(posDelta, worldUp, -_speed);
            }
            if (keyboard_check(self.keys.DOWN_MOVE)) {
                vec3_add_scaled_vector(posDelta, worldUp, _speed);
            }
            
            vec3_add(camPos, posDelta);
            
            // Update camera target based on look direction
            var targetDist = self.radius; // Use current radius as distance for look-at point
            vec3_add_scaled_vector(vec3_copy(self.camera.target, camPos), forward, targetDist);
        } else {
            // === ORBIT MODE ===
            
            // Update target from object if set
            if (self.targetObject != undefined) {
                // Using world position (pivot) instead of recursive bbox center for performance
                self.targetObject.getWorldPosition(self.__scratchVec0);
                vec3_add_vectors(self.target, self.__scratchVec0, self.targetOffset);
            }
            
            var effectiveSizeFactor = (self.targetObject != undefined) ? (self.sizeFactor * 0.001) : 1.0;
            
            var displayWidth = self._sceneBounds.x2 - self._sceneBounds.x1;
            var displayHeight = self._sceneBounds.y2 - self._sceneBounds.y1;
            if (displayWidth <= 0) displayWidth = window_get_width();
            if (displayHeight <= 0) displayHeight = window_get_height();
            
            // Orbit rotation (Alt + Left Mouse)
            if (self._orbitActive && self.enableRotate) {
                self._deltaAzimuth -= (dx / displayWidth) * self.rotateSpeed * pi;
                self._deltaElevation += (dy / displayHeight) * self.rotateSpeed * pi;
            }
            
            // Pan (Middle Mouse)
            if (self._panActive && self.enablePan) {
                var camPos = self.camera.position;
                var camTarget = self.target;
                var camDir = vec3_sub_vectors(self.__scratchVec0, camTarget, camPos);
                vec3_normalize(camDir);
                
                // Pan amount scaled by radius and display size
                var panX = (dx / displayWidth) * self.panSpeed * effectiveSizeFactor * self.radius * 2;
                var panY = (dy / displayHeight) * self.panSpeed * effectiveSizeFactor * self.radius * 2;
                
                if (self.screenSpacePanning) {
                    // Robust right vector from azimuth (avoids gimbal lock when looking straight up/down)
                    var right = vec3_set(self.__scratchVec1, -sin(self.azimuth), cos(self.azimuth), 0);
                    var up = vec3_copy(self.__scratchVec2, right); vec3_cross(up, camDir); vec3_normalize(up);
                    
                    // Natural panning (drag right -> scene moves right)
                    vec3_add_scaled_vector(self._deltaPan, right, -panX);
                    vec3_add_scaled_vector(self._deltaPan, up, panY);
                } else {
                    var forward = vec3_set(self.__scratchVec1, camDir[VEC3.x], camDir[VEC3.y], 0); vec3_normalize(forward);
                    var right = vec3_set(self.__scratchVec2, -forward[VEC3.y], forward[VEC3.x], 0);
                    
                    vec3_add_scaled_vector(self._deltaPan, right, -panX);
                    vec3_add_scaled_vector(self._deltaPan, forward, panY);
                }
            }
            
            // Zoom (Scroll or Alt + Right Mouse)
            if (self.enableZoom && allowInteractions) {
                var zoomFactor = 0.05 * self.zoomSpeed; // 5% zoom per notch
                
                if (wheelUp) {
                    self.radius *= (1 - zoomFactor);
                    self._needsUpdate = true;
                }
                if (wheelDown) {
                    self.radius *= (1 + zoomFactor);
                    self._needsUpdate = true;
                }
                if (self._altZoomActive) {
                    // Continuous zoom via mouse drag
                    var dragFactor = dy * 0.005 * self.zoomSpeed;
                    self.radius *= (1 + dragFactor);
                    self._needsUpdate = true;
                }
            }
            
            // Auto-rotate
            if (self.autoRotate && !self._orbitActive && !self._panActive) {
                self._deltaAzimuth -= degtorad(self.autoRotateSpeed);
            }
            
            // Apply damping or instant movement
            if (self.enableDamping) {
                self.azimuth += self._deltaAzimuth * self.dampingFactor;
                self.elevation += self._deltaElevation * self.dampingFactor;
                
                if (self.targetObject != undefined) {
                    vec3_add_scaled_vector(self.targetOffset, self._deltaPan, self.dampingFactor);
                } else {
                    vec3_add_scaled_vector(self.target, self._deltaPan, self.dampingFactor);
                }
                
                self._deltaAzimuth *= (1 - self.dampingFactor);
                self._deltaElevation *= (1 - self.dampingFactor);
                vec3_multiply_scalar(self._deltaPan, 1 - self.dampingFactor);
            } else {
                self.azimuth += self._deltaAzimuth;
                self.elevation += self._deltaElevation;
                
                if (self.targetObject != undefined) {
                    vec3_add(self.targetOffset, self._deltaPan);
                } else {
                    vec3_add(self.target, self._deltaPan);
                }
                
                self._deltaAzimuth = 0;
                self._deltaElevation = 0;
                vec3_set(self._deltaPan, 0, 0, 0);
            }
            
            // Clamp values
            self.radius = clamp(self.radius, self.minTargetRadius, self.maxTargetRadius);
            self.elevation = clamp(self.elevation, -pi * 0.4999, pi * 0.4999);
            
            // Update target position if tracking an object
            if (self.targetObject != undefined) {
                var center = box3_get_center(self.__scratchBox, self.__scratchVec0);
                vec3_add_vectors(self.target, center, self.targetOffset);
            }
            
            // Update camera position from spherical coordinates
            var cosElevation = cos(self.elevation);
            var cx = self.target[VEC3.x] + self.radius * cosElevation * cos(self.azimuth);
            var cy = self.target[VEC3.y] + self.radius * cosElevation * sin(self.azimuth);
            var cz = self.target[VEC3.z] + self.radius * sin(self.elevation);
            
            self.camera.setPosition(cx, cy, cz);
            self.camera.lookAtVec(self.target);
            vec3_copy(self.camera.target, self.target);
        }
        
        // === POST-UPDATE ===
        
        // Warp mouse if exiting scene bounds while transforming
        var warped = false;
        if (self.transforming) {
            warped = warpMouseIfNeeded(mx, my);
        }
        
        self._needsUpdate = false;
        
        // Only update previous mouse position if we didn't warp
        // If we warped, warpMouseIfNeeded already set _prevMouseX/Y to the new position
        if (!warped) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
        }
        
        if (self.onChange != undefined && (self.transforming || isDamping || self.autoRotate)) {
            self.onChange();
        }
    }
    

    
    // Initialize mouse position
    self._prevMouseX = window_mouse_get_x();
    self._prevMouseY = window_mouse_get_y();
    
    // Set initial target if it's an object
    if (typeof (_initialTarget) == "struct" && (_initialTarget[$ "isObject3D"] || _initialTarget[$ "isMesh"])) {
        self.setTarget(_initialTarget);
    }
}
