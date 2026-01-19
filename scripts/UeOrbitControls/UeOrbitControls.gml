// @todo check input configuration in variables (mouse/keyboard)
function UeOrbitControls(camera, data = {}): UeControls(data) constructor {
    self.camera = camera;
    self.target = data[$ "target"] ?? vec3_create(data[$ "xt"] ?? 0, data[$ "yt"] ?? 0, data[$ "zt"] ?? 0);
    
    // Set the initial azimuth/elevation from the camera position towards the target
    var dir = vec3_clone(camera.position); vec3_sub(dir, target);
    self.radius = vec3_distance_to(camera.position, target);
    self.azimuth = arctan2(dir[VEC3.y], dir[VEC3.x]);
    self.elevation = radius == 0 ? 0 : arcsin(clamp(dir[VEC3.z] / radius, -1, 1));

    self.enableZoom = data[$"enableZoom"] ?? true;
    self.zoomSpeed = data[$"zoomSpeed"] ?? 5;
    self.minTargetRadius = data[$"minTargetRadius"] ?? 5;
    self.maxTargetRadius = data[$"maxTargetRadius"] ?? infinity;

    self.enablePan = data[$"enablePan"] ?? true;
    self.panSpeed = data[$"panSpeed"] ?? 1.0;

    self.enableRotate = data[$"enableRotate"] ?? true;
    self.rotateSpeed = data[$"rotateSpeed"] ?? 1.0;

    self.enableDamping = data[$"enableDamping"] ?? true;
    self.dampingFactor = data[$"dampingFactor"] ?? 0.1;

    self.autoRotate = data[$"autoRotate"] ?? false;
    self.autoRotateSpeed = data[$"autoRotateSpeed"] ?? 0.5;

    self.screenSpacePanning = data[$"screenSpacePanning"] ?? false;

    self.mouseButtonRotate = mb_left;
    self.mouseButtonZoom = mb_middle;
    self.mouseButtonPan = mb_right; 

    self.keyPanSpeed = 1.0;
    self.keyRotateSpeed = 1.0;

    self.keys = {
        LEFT: vk_left,
        UP: vk_up,
        RIGHT: vk_right,
        BOTTOM: vk_down,
        SHIFT: vk_shift
    };

    self._dragging = false;
    self._panning = false;
    self._zooming = false;
    self.transforming = false;
    
    // Callback fired when transformation ends
    self.onChange = data[$"onChange"] ?? undefined;

    self._deltaAzimuth = 0;
    self._deltaElevation = 0;
    self._deltaPan = vec3_create();

    self.__scratchVec0 = vec3_create();
    self.__scratchVec1 = vec3_create();
    self.__scratchVec2 = vec3_create();

    // @todo missing doc
    function reset() {
      gml_pragma("forceinline");
      vec3_set(self.target, 0, 0, 0);  // @todo should set to the actual initial target
      
      var dir = vec3_sub_vectors(self.__scratchVec0, camera.position, target);
      self.radius = vec3_distance_to(camera.position, target);
      self.azimuth = arctan2(dir[VEC3.y], dir[VEC3.x]);
      self.elevation = radius == 0 ? 0 : arcsin(clamp(dir[VEC3.z] / radius, -1, 1));
    }

    // Update spherical coordinates from current camera position and target
    // Useful when manually setting the camera position and target
    // @todo missing doc
    function updateSphericalCoordinates() {
      var dir = vec3_sub_vectors(self.__scratchVec0, camera.position, target);
      self.radius = vec3_distance_to(camera.position, target);
      self.azimuth = arctan2(dir[VEC3.y], dir[VEC3.x]);
      self.elevation = radius == 0 ? 0 : arcsin(clamp(dir[VEC3.z] / radius, -1, 1));
        
      self._deltaAzimuth = 0;
      self._deltaElevation = 0;
      vec3_set(self._deltaPan, 0, 0, 0);
    }

    // Update the camera orbit. 
    // Optionally takes the mouse coordinates in input, otherwise it will get it automatically from the UeMouse class
    function update(mx = undefined, my = undefined) {
        gml_pragma("forceinline");
        
        if (!enabled) return;
        
        if (mx == undefined) {
            var mouse = global.UE_MOUSE.get(); 
            mx = mouse.x;
            my = mouse.y;
        }
        
        var allowInteractions = shouldHandleInput();
        var wheelUp = false;
        var wheelDown = false;
        var hasInput = false;

        if (allowInteractions) {
            wheelUp = mouse_wheel_up();
            wheelDown = mouse_wheel_down();
            hasInput = wheelUp || wheelDown ||
                       mouse_check_button(self.mouseButtonRotate) || 
                       mouse_check_button(self.mouseButtonPan) || 
                       mouse_check_button(self.mouseButtonZoom) || 
                       keyboard_check(self.keys.LEFT) || keyboard_check(self.keys.RIGHT) ||
                       keyboard_check(self.keys.UP) || keyboard_check(self.keys.BOTTOM);
        }

        var anyButtonPressed = mouse_check_button_pressed(mb_any);
        var anyButtonReleased = mouse_check_button_released(mb_any);

        var isDamping = false;
        if (self.enableDamping) {
            isDamping = abs(self._deltaAzimuth) > 0.0001 || 
                        abs(self._deltaElevation) > 0.0001 || 
                        vec3_length_sq(self._deltaPan) > 0.0001;
        }

        // Early exit if no input, no damping, no auto-rotate, and we're not currently transforming or interacting
        if (!hasInput && !isDamping && !self.autoRotate && !self.transforming && !anyButtonPressed && !anyButtonReleased) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
            return;
        }

        var displayWidth = display_get_width();
        var displayHeight = display_get_height();
        var worldUp = global.UE_DEFAULT_UP;
        
        if (anyButtonPressed) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
            if (allowInteractions) __canInteract = true;
        }
        if (anyButtonReleased) {
            __canInteract = false;
        }

        var isRotatingNow = __canInteract && mouse_check_button(self.mouseButtonRotate) && self.enableRotate;
        var isPanningNow = __canInteract && mouse_check_button(self.mouseButtonPan) && self.enablePan;
        var isZoomingNow = __canInteract && mouse_check_button(self.mouseButtonZoom) && self.enableZoom;
        var isWheelZooming = enableZoom && allowInteractions && (wheelUp || wheelDown);

        if ((isRotatingNow && !self._dragging) || (isPanningNow && !self._panning) || (isZoomingNow && !self._zooming)) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
        }

        self._dragging = isRotatingNow;
        self._panning = isPanningNow;
        self._zooming = isZoomingNow;
        
        var wasTransforming = self.transforming;
        self.transforming = self._dragging || self._panning || self._zooming || isWheelZooming;
        
        if (wasTransforming && !self.transforming && self.onChange != undefined) {
            self.onChange();
        }

        var dx = 0, dy = 0;
        if (self._dragging || self._panning || self._zooming) {
            dx = mx - self._prevMouseX;
            dy = my - self._prevMouseY;
        }

        var camPos = self.camera.position;
        var camTarget = self.target;
        var camDir = undefined; // Lazy initialization

        // Mouse rotate
        if (self._dragging && self.enableRotate) {
            self._deltaAzimuth -= (dx / displayWidth) * self.rotateSpeed * pi;
            self._deltaElevation += (dy / displayHeight) * self.rotateSpeed * pi;
        }

        // Mouse pan
        if (self._panning && self.enablePan) {
            if (camDir == undefined) {
                camDir = vec3_sub_vectors(self.__scratchVec0, camTarget, camPos); 
                vec3_normalize(camDir);
            }

            var panX = -(dx / displayWidth) * self.panSpeed * self.radius * 3;
            var panY = (dy / displayHeight) * self.panSpeed * self.radius * 3;
            
            if (self.screenSpacePanning) {
                var right = vec3_copy(self.__scratchVec1, camDir); vec3_cross(right, worldUp); vec3_normalize(right);
                var up = vec3_copy(self.__scratchVec2, right); vec3_cross(up, camDir); vec3_normalize(up);

                vec3_add_scaled_vector(self._deltaPan, right, -panX);
                vec3_add_scaled_vector(self._deltaPan, up, -panY);
            } else {
                var forward = vec3_set(self.__scratchVec1, camDir[VEC3.x], camDir[VEC3.y], 0); vec3_normalize(forward);
                var right = vec3_set(self.__scratchVec2, -forward[VEC3.y], forward[VEC3.x], 0);

                vec3_add_scaled_vector(self._deltaPan, right, -panX);
                vec3_add_scaled_vector(self._deltaPan, forward, panY);
            }
        }

        // Mouse zoom
        if (enableZoom && allowInteractions) {
            if (wheelUp) self.radius -= self.zoomSpeed * 5;
            if (wheelDown) self.radius += self.zoomSpeed * 5;
            if (self._zooming) self.radius += dy * self.zoomSpeed * 0.1;
        }

        // Keyboard input
        if (allowInteractions && !global.UI.hasAnyFocus()) {
            var shiftPressed = keyboard_check(self.keys.SHIFT);
            
            if (shiftPressed) {
                var rotateKeyAmount = self.keyRotateSpeed * pi * 0.01;
                if (keyboard_check(self.keys.LEFT))  self._deltaAzimuth += rotateKeyAmount;
                if (keyboard_check(self.keys.RIGHT)) self._deltaAzimuth -= rotateKeyAmount;
                if (keyboard_check(self.keys.UP))    self._deltaElevation += rotateKeyAmount;
                if (keyboard_check(self.keys.BOTTOM))self._deltaElevation -= rotateKeyAmount;
            } else {
                var panKeyAmount = self.keyPanSpeed * self.radius * 0.01;
                if (camDir == undefined) {
                    camDir = vec3_sub_vectors(self.__scratchVec0, camTarget, camPos); 
                    vec3_normalize(camDir);
                }

                if (self.screenSpacePanning) {
                    var right = vec3_copy(self.__scratchVec1, camDir); vec3_cross(right, worldUp); vec3_normalize(right);
                    var up = vec3_copy(self.__scratchVec2, right); vec3_cross(up, camDir); vec3_normalize(up);
                  
                    if (keyboard_check(self.keys.LEFT))   vec3_add_scaled_vector(self._deltaPan, right, panKeyAmount);
                    if (keyboard_check(self.keys.RIGHT))  vec3_add_scaled_vector(self._deltaPan, right, -panKeyAmount);
                    if (keyboard_check(self.keys.UP))     vec3_add_scaled_vector(self._deltaPan, up, -panKeyAmount);
                    if (keyboard_check(self.keys.BOTTOM)) vec3_add_scaled_vector(self._deltaPan, up, panKeyAmount);
                } else {
                    var forward = vec3_set(self.__scratchVec1, camDir[VEC3.x], camDir[VEC3.y], 0); vec3_normalize(forward);
                    var right = vec3_set(self.__scratchVec2, -forward[VEC3.y], forward[VEC3.x], 0);
                    
                    if (keyboard_check(self.keys.LEFT))   vec3_add_scaled_vector(self._deltaPan, right, panKeyAmount);
                    if (keyboard_check(self.keys.RIGHT))  vec3_add_scaled_vector(self._deltaPan, right, -panKeyAmount);
                    if (keyboard_check(self.keys.UP))     vec3_add_scaled_vector(self._deltaPan, forward, panKeyAmount);
                    if (keyboard_check(self.keys.BOTTOM)) vec3_add_scaled_vector(self._deltaPan, forward, -panKeyAmount);
                }
            }
        }

        // Auto-rotate
        if (self.autoRotate && !self._dragging && !self._panning) {
            self._deltaAzimuth -= degtorad(self.autoRotateSpeed);
        }

        // Apply motion
        if (self.enableDamping) {
            self.azimuth += self._deltaAzimuth * self.dampingFactor;
            self.elevation += self._deltaElevation * self.dampingFactor;
            vec3_add_scaled_vector(self.target, self._deltaPan, self.dampingFactor);

            self._deltaAzimuth *= (1 - self.dampingFactor);
            self._deltaElevation *= (1 - self.dampingFactor);
            vec3_multiply_scalar(self._deltaPan, 1 - self.dampingFactor);
        } else {
            self.azimuth += self._deltaAzimuth;
            self.elevation += self._deltaElevation;
            vec3_add(self.target, self._deltaPan);

            self._deltaAzimuth = 0;
            self._deltaElevation = 0;
            vec3_set(self._deltaPan, 0, 0, 0);
        }
        
        self.radius = clamp(self.radius, self.minTargetRadius, self.maxTargetRadius);
        self.elevation = clamp(self.elevation, -pi * 0.4999, pi * 0.4999);

        // Update camera position
        var cosElevation = cos(self.elevation);
        var cx = self.target[VEC3.x] + self.radius * cosElevation * cos(self.azimuth);
        var cy = self.target[VEC3.y] + self.radius * cosElevation * sin(self.azimuth);
        var cz = self.target[VEC3.z] + self.radius * sin(self.elevation);
    
        self.camera.setPosition(cx, cy, cz);
        vec3_copy(self.camera.target, self.target);
        
        self._prevMouseX = mx;
        self._prevMouseY = my;
    }
    
    var mouse = global.UE_MOUSE.get(); 
    self._prevMouseX = mouse.x;
    self._prevMouseY = mouse.y;
}
