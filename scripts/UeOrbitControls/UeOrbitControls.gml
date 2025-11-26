// @todo check input configuration in variables (mouse/keyboard)
function UeOrbitControls(camera, data = {}): UeControls(data) constructor {
    self.camera = camera;
    self.target = data[$ "target"] ?? new UeVector3(data[$ "xt"] ?? 0, data[$ "yt"] ?? 0, data[$ "zt"] ?? 0);
    
    // Set the initial azimuth/elevation from the camera position towards the target
    var dir = camera.position.clone().sub(target);
    self.radius = camera.position.distanceTo(target);
    self.azimuth = arctan2(dir.y, dir.x);
    self.elevation = radius == 0 ? 0 : arcsin(clamp(dir.z / radius, -1, 1));

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
    self._deltaPan = new UeVector3(0, 0, 0);

    // @todo missing doc
    function reset() {
        gml_pragma("forceinline");
        self.target.set(0, 0, 0); // @todo should set to the actual initial target
        var dir = camera.position.clone().sub(target);
        self.radius = camera.position.distanceTo(target);
        self.azimuth = arctan2(dir.y, dir.x);
        self.elevation = radius == 0 ? 0 : arcsin(clamp(dir.z / radius, -1, 1));
    }

    // Update spherical coordinates from current camera position and target
    // Useful when manually setting the camera position and target
    // @todo missing doc
    function updateSphericalCoordinates() {
        var dir = camera.position.clone().sub(target);
        self.radius = camera.position.distanceTo(target);
        self.azimuth = arctan2(dir.y, dir.x);
        self.elevation = self.radius == 0 ? 0 : arcsin(clamp(dir.z / self.radius, -1, 1));
        
        self._deltaAzimuth = 0;
        self._deltaElevation = 0;
        self._deltaPan.set(0, 0, 0);
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
        
        var displayWidth = display_get_width();
        var displayHeight = display_get_height();
        var worldUp = global.UE_OBJECT3D_DEFAULT_UP;
        
        // Allow interactions only if they have been allowed from the user
        var allowInteractions = shouldHandleInput();
        
        if (mouse_check_button_pressed(mb_any)) {
            // Update previous mouse position to current position to prevent camera jump
            self._prevMouseX = mx;
            self._prevMouseY = my;

            if (allowInteractions) {
                __canInteract = true;
            }
        }
        if (mouse_check_button_released(mb_any)) {
            __canInteract = false;
        }

        var isRotatingNow = __canInteract && mouse_check_button(self.mouseButtonRotate) && self.enableRotate;
        var isPanningNow = __canInteract && mouse_check_button(self.mouseButtonPan) && self.enablePan;
        var isZoomingNow = __canInteract && mouse_check_button(self.mouseButtonZoom) && self.enableZoom;
        var isWheelZooming = enableZoom && allowInteractions && (mouse_wheel_up() || mouse_wheel_down());

        if (isRotatingNow && !self._dragging) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
        }
        if (isPanningNow && !self._panning) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
        }
        if (isZoomingNow && !self._zooming) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
        }

        self._dragging = isRotatingNow;
        self._panning = isPanningNow;
        self._zooming = isZoomingNow;
        
        // Track transforming state and fire onChange when it ends
        var wasTransforming = self.transforming;
        self.transforming = self._dragging || self._panning || self._zooming || isWheelZooming;
        
        // Fire onChange callback when transformation ends
        if (wasTransforming && !self.transforming && self.onChange != undefined) {
            self.onChange();
        }

        var dx = 0;
        var dy = 0;
        if (self._dragging || self._panning || self._zooming) {
            dx = mx - self._prevMouseX;
            dy = my - self._prevMouseY;
        }

        // Mouse rotate
        if (self._dragging && self.enableRotate) {
            var norm_dx = dx / displayWidth;
            var norm_dy = dy / displayHeight;

            self._deltaAzimuth -= norm_dx * self.rotateSpeed * pi;
            self._deltaElevation += norm_dy * self.rotateSpeed * pi;
        }

        // Mouse pan
        if (self._panning && self.enablePan) {
            var norm_dx = dx / displayWidth;
            var norm_dy = dy / displayHeight;

            var panX = -norm_dx * self.panSpeed * self.radius * 3;
            var panY = norm_dy * self.panSpeed * self.radius * 3;
            
            var camPos = self.camera.position;
            var camTarget = self.target;
            var camDir = camTarget.clone().sub(camPos).normalize();

            if (self.screenSpacePanning) {
                var right = camDir.cross(worldUp).normalize();
                var up = right.cross(camDir).normalize();

                self._deltaPan.add(right.scale(-panX));
                self._deltaPan.add(up.scale(-panY));
            } else {
                var forward = new UeVector3(camDir.x, camDir.y, 0).normalize();
                var right = new UeVector3(-forward.y, forward.x, 0); // 90° clockwise

                self._deltaPan.add(right.scale(-panX));
                self._deltaPan.add(forward.scale(panY));
            }
        }

        // Mouse zoom
        if (enableZoom && allowInteractions) {
            if (mouse_wheel_up()) self.radius -= self.zoomSpeed * 5;
            if (mouse_wheel_down()) self.radius += self.zoomSpeed * 5;
                
            if (self._zooming) {
                // Zoom in base al movimento verticale del mouse (drag)
                self.radius += dy * self.zoomSpeed * 0.1;
            }
        }

        // Keyboard input
        var shiftPressed = keyboard_check(self.keys.SHIFT);
        var panKeyAmount = self.keyPanSpeed * self.radius * 0.01;
        var rotateKeyAmount = self.keyRotateSpeed * pi * 0.01;

        var camPos = self.camera.position;
        var camTarget = self.target;
        var camDir = camTarget.clone().sub(camPos).normalize();

        if (allowInteractions && !global.UI.hasAnyFocus()) {
            if (!shiftPressed) {
                if (self.screenSpacePanning) {
                    // Pan aligned to camera screen space
                    var right = camDir.cross(worldUp).normalize();
                    var up = right.cross(camDir).normalize();
            
                    if (keyboard_check(self.keys.LEFT))   self._deltaPan.add(right.scale(panKeyAmount));
                    if (keyboard_check(self.keys.RIGHT))  self._deltaPan.add(right.scale(-panKeyAmount));
                    if (keyboard_check(self.keys.UP))     self._deltaPan.add(up.scale(-panKeyAmount));
                    if (keyboard_check(self.keys.BOTTOM)) self._deltaPan.add(up.scale(panKeyAmount));
                } else {
                    // Project cam direction onto world XY plane
                    var forward = new UeVector3(camDir.x, camDir.y, 0).normalize();
                    var right = new UeVector3(-forward.y, forward.x, 0);
                    
                    // World space pan (assumed XY plane)
                    if (keyboard_check(self.keys.LEFT))   self._deltaPan.add(right.scale(panKeyAmount));
                    if (keyboard_check(self.keys.RIGHT))  self._deltaPan.add(right.scale(-panKeyAmount));
                    if (keyboard_check(self.keys.UP))     self._deltaPan.add(forward.scale(panKeyAmount));
                    if (keyboard_check(self.keys.BOTTOM)) self._deltaPan.add(forward.scale(-panKeyAmount));
                }
            } else {
                if (keyboard_check(self.keys.LEFT))  self._deltaAzimuth += rotateKeyAmount;
                if (keyboard_check(self.keys.RIGHT)) self._deltaAzimuth -= rotateKeyAmount;
                if (keyboard_check(self.keys.UP))    self._deltaElevation += rotateKeyAmount;
                if (keyboard_check(self.keys.BOTTOM))self._deltaElevation -= rotateKeyAmount;
            }
        }

        // Auto-rotate
        if (self.autoRotate && !self._dragging && !self._panning) {
            self._deltaAzimuth -= degtorad(self.autoRotateSpeed);
        }

        // Clamp and apply motion
        if (self.enableDamping) {
            self.azimuth += self._deltaAzimuth * self.dampingFactor;
            self.elevation += self._deltaElevation * self.dampingFactor;
            self.target.add(self._deltaPan.clone().scale(self.dampingFactor));

            self._deltaAzimuth *= (1 - self.dampingFactor);
            self._deltaElevation *= (1 - self.dampingFactor);
            self._deltaPan.scale(1 - self.dampingFactor);
        } else {
            self.azimuth += self._deltaAzimuth;
            self.elevation += self._deltaElevation;
            self.target.add(self._deltaPan);

            self._deltaAzimuth = 0;
            self._deltaElevation = 0;
            self._deltaPan.set(0, 0, 0);
        }
        
        self.radius = clamp(self.radius, self.minTargetRadius, self.maxTargetRadius);
        self.elevation = clamp(self.elevation, -pi * 0.4999, pi * 0.4999);

        // Update camera position
        var cx = self.target.x + self.radius * cos(self.elevation) * cos(self.azimuth);
        var cy = self.target.y + self.radius * cos(self.elevation) * sin(self.azimuth);
        var cz = self.target.z + self.radius * sin(self.elevation);
    
        self.camera.setPosition(cx, cy, cz);
        self.camera.target.copy(self.target);
        
        self._prevMouseX = mx;
        self._prevMouseY = my;
    }
    
    var mouse = global.UE_MOUSE.get(); 
    self._prevMouseX = mouse.x;
    self._prevMouseY = mouse.y;
}
