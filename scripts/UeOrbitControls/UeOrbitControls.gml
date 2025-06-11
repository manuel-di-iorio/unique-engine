function OrbitControls(data = {}): Controls(data) constructor {
    self.camera = data[$ "camera"];
    self.target = data[$ "target"] ?? new Vec3(data[$ "xt"] ?? 0, data[$ "yt"] ?? 0, data[$ "zt"] ?? 0);
    
    // Set the initial azimuth/elevation from the camera position towards the target
    var dir = camera.position.clone().sub(target);
    self.radius = camera.position.distanceTo(target);
    self.azimuth = arctan2(dir.y, dir.x);
    self.elevation = arcsin(clamp(dir.z / radius, -1, 1));

    //self.radius = max(0.1, data[$"radius"] ?? 100);
    //self.azimuth = data[$ "azimuth"] ? degtorad(data.azimuth) : 0;
    //self.elevation = data[$ "elevation"] ? degtorad(data.elevation) : 0;
    //self.radius = camera.position.distanceTo(target);
    //self.azimuth = darctan2(camera.position.y, camera.position.x);
    //self.elevation = darcsin(clamp(camera.position.z / self.radius, -1, 1));

    self.enableZoom = true;
    self.zoomSpeed = data[$"zoomSpeed"] ?? 5;
    self.minTargetRadius = data[$"minTargetRadius"] ?? 5;
    self.maxTargetRadius = data[$"maxTargetRadius"] ?? infinity;

    self.enablePan = true;
    self.panSpeed = data[$"panSpeed"] ?? 1.0;

    self.enableRotate = true;
    self.rotateSpeed = data[$"rotateSpeed"] ?? 1.0;

    self.enableDamping = true;
    self.dampingFactor = 0.1;

    self.autoRotate = data[$"autoRotate"] ?? false;
    self.autoRotateSpeed = data[$"autoRotateSpeed"] ?? 0.1;

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
        BOTTOM: vk_down
    };

    self._dragging = false;
    self._panning = false;

    self._deltaAzimuth = 0;
    self._deltaElevation = 0;
    self._deltaPan = new Vec3(0, 0, 0);

    self._prevMouseX = display_mouse_get_x();
    self._prevMouseY = display_mouse_get_y();

    function update() {
        var mx = display_mouse_get_x();
        var my = display_mouse_get_y();

        var isRotatingNow = mouse_check_button(self.mouseButtonRotate);
        var isPanningNow = mouse_check_button(self.mouseButtonPan);

        if (isRotatingNow && !self._dragging) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
        }
        if (isPanningNow && !self._panning) {
            self._prevMouseX = mx;
            self._prevMouseY = my;
        }

        self._dragging = isRotatingNow;
        self._panning = isPanningNow;

        var dx = 0;
        var dy = 0;
        if (self._dragging || self._panning) {
            dx = mx - self._prevMouseX;
            dy = my - self._prevMouseY;
        }

        // Mouse rotate
        if (self._dragging && self.enableRotate) {
            var norm_dx = dx / display_get_width();
            var norm_dy = dy / display_get_height();

            self._deltaAzimuth -= norm_dx * self.rotateSpeed * 2 * pi;
            self._deltaElevation += norm_dy * self.rotateSpeed * pi;
        }

        // Mouse pan
        if (self._panning && self.enablePan) {
            var norm_dx = dx / display_get_width();
            var norm_dy = dy / display_get_height();

            var panX = -norm_dx * self.panSpeed * self.radius * 3;
            var panY = norm_dy * self.panSpeed * self.radius * 3;
            
            var camPos = self.camera.position;
            var camTarget = self.target;
            var camDir = camTarget.clone().sub(camPos).normalize();

            if (self.screenSpacePanning) {
                var worldUp = new Vec3(0, 0, -1);
                var right = camDir.cross(worldUp).normalize();
                var up = right.cross(camDir).normalize();

                self._deltaPan.add(right.scale(-panX));
                self._deltaPan.add(up.scale(-panY));
            } else {
                var forward = new Vec3(camDir.x, camDir.y, 0).normalize();
                var right = new Vec3(-forward.y, forward.x, 0); // 90° clockwise

                self._deltaPan.add(right.scale(-panX));
                self._deltaPan.add(forward.scale(panY));
            }
        }

        // Mouse zoom
        if (enableZoom) {
            if (mouse_wheel_up()) self.radius -= self.zoomSpeed * 5;
            if (mouse_wheel_down()) self.radius += self.zoomSpeed * 5;
                
            if (mouse_check_button(self.mouseButtonZoom)) {
                my = display_mouse_get_y();
                dy = my - self._prevMouseY;
        
                // Zoom in base al movimento verticale del mouse (drag)
                self.radius += dy * self.zoomSpeed * 0.1;
            }
        }

        // Keyboard input
        var shiftPressed = keyboard_check(vk_shift);
        var panKeyAmount = self.keyPanSpeed * self.radius * 0.01;
        var rotateKeyAmount = self.keyRotateSpeed * pi * 0.01;

        var camPos = self.camera.position;
        var camTarget = self.target;
        var camDir = camTarget.clone().sub(camPos).normalize();

        if (!shiftPressed) {
            if (self.screenSpacePanning) {
                // Pan aligned to camera screen space
                var worldUp = new Vec3(0, 0, -1);
                var right = camDir.cross(worldUp).normalize();
                var up = right.cross(camDir).normalize();
        
                if (keyboard_check(self.keys.LEFT))  self._deltaPan.add(right.scale(panKeyAmount));
                if (keyboard_check(self.keys.RIGHT)) self._deltaPan.add(right.scale(-panKeyAmount));
                if (keyboard_check(self.keys.UP))    self._deltaPan.add(up.scale(-panKeyAmount));
                if (keyboard_check(self.keys.BOTTOM))self._deltaPan.add(up.scale(panKeyAmount));
            } else {
                // Project cam direction onto world XY plane
                var forward = new Vec3(camDir.x, camDir.y, 0).normalize();
                var right = new Vec3(-forward.y, forward.x, 0);
                
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
        self.elevation = clamp(self.elevation, -pi * 0.49, pi * 0.49);

        // Update camera position
        var cx = self.target.x + self.radius * cos(self.elevation) * cos(self.azimuth);
        var cy = self.target.y + self.radius * cos(self.elevation) * sin(self.azimuth);
        var cz = self.target.z + self.radius * sin(self.elevation);

        self.camera.position.set(cx, cy, cz);
        self.camera.target.copy(self.target);

        self._prevMouseX = mx;
        self._prevMouseY = my;
    }
}
