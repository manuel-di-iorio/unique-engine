/// @func UePointerLockControls(camera, data)
/// @desc Controls for first person shooter style camera.
/// @param {Struct.UeCamera} camera The camera to control
/// @param {Struct} [data] Configuration data
function UePointerLockControls(camera, data = {}): UeControls(data) constructor {
    self.camera = camera;
    
    // Configurazione Speed
    self.pointerSpeedX = data[$ "pointerSpeedX"] ?? 0.1;
    self.pointerSpeedY = data[$ "pointerSpeedY"] ?? 0.1;
    
    // Limits
    self.minPolarAngle = data[$ "minPolarAngle"] ?? 0;
    self.maxPolarAngle = data[$ "maxPolarAngle"] ?? pi;
    
    // Accumulatori rotazione (in gradi)
    self.yaw = 0;   // Rotazione attorno a Z (World Up)
    self.pitch = 0; // Rotazione attorno a X (Local Right)
    
    // Target Lock State
    self.isLocked = false;
    
    // Flag per forzare l'aggiornamento (es. al primo frame o dopo modifiche programmatiche)
    self._needsUpdate = true;

    // Metodi di controllo Lock
    static lock = function() {
        window_mouse_set_locked(true);
        if (!self.isLocked) {
            self.isLocked = true;
            self.dispatch({ type: "lock" });
        }
        self._needsUpdate = true;
    };

    static unlock = function() {
        window_mouse_set_locked(false);
        if (self.isLocked) {
            self.isLocked = false;
            self.dispatch({ type: "unlock" });
        }
        self._needsUpdate = true;
    };
    

    static getDirection = function(target) {
        var r = dcos(self.pitch);
        var dirX = r * dcos(self.yaw);
        var dirY = r * dsin(self.yaw);
        var dirZ = dsin(self.pitch);
        
        if (is_array(target)) {
            target[0] = dirX;
            target[1] = dirY;
            target[2] = dirZ;
        } else {
            target.x = dirX;
            target.y = dirY;
            target.z = dirZ;
        }
        return target;
    };
    
    static moveForward = function(distance) {
        var moveX = dcos(self.yaw) * distance;
        var moveY = dsin(self.yaw) * distance;
        
        self.camera.position[0] += moveX;
        self.camera.position[1] += moveY;
        self.camera.target[0] += moveX;
        self.camera.target[1] += moveY;
    };
    
    static moveRight = function(distance) {
        var moveX = -dsin(self.yaw) * distance;
        var moveY = dcos(self.yaw) * distance;
        
        self.camera.position[0] += moveX;
        self.camera.position[1] += moveY;
        self.camera.target[0] += moveX;
        self.camera.target[1] += moveY;
    };
    
    static update = function() {
        if (!self.enabled) return;
        
        // Gestione stato lock (toggle con Click per lockare, solo se nel viewport)
        if (mouse_check_button_pressed(mb_left) && !self.isLocked) {
            var mouse = global.UE_MOUSE.get();
            if (abs(mouse.ndcX) <= 1 && abs(mouse.ndcY) <= 1) {
                self.lock();
            }
        }
        
        // Se non siamo lockati, non ruotiamo a meno che non sia richiesto un aggiornamento forzato
        var isLockedNow = window_mouse_get_locked();
        if (!isLockedNow) {
            if (self.isLocked) {
                self.isLocked = false;
                self.dispatch({ type: "unlock" });
            }
            if (!self._needsUpdate) return;
        } else {
            if (!self.isLocked) {
                self.isLocked = true;
                self.dispatch({ type: "lock" });
            }
        }

        // Get Mouse Delta
        var dx = isLockedNow ? window_mouse_get_delta_x() : 0;
        var dy = isLockedNow ? window_mouse_get_delta_y() : 0;

        if (dx == 0 && dy == 0 && !self._needsUpdate) return;

        // Aggiorna Yaw (Z-axis) e Pitch (X-axis) solo se lockati
        if (isLockedNow) {
            // dx positivo (mouse a destra) -> yaw diminuisce (ruota orario verso Y-)
            self.yaw -= dx * self.pointerSpeedX;
            
            // dy positivo (mouse giù) -> pitch diminuisce (guarda giù)
            self.pitch -= dy * self.pointerSpeedY;

            // Clamp Pitch
            var minPitchDeg = 90 - (self.maxPolarAngle * 180 / pi);
            var maxPitchDeg = 90 - (self.minPolarAngle * 180 / pi);
            self.pitch = clamp(self.pitch, minPitchDeg, maxPitchDeg);
            
            self.dispatch({ type: "change" });
        }
        
        // --- Aggiorna Camera Target ---
        var r = dcos(self.pitch); // Raggio orizzontale
        var dirX = r * dcos(self.yaw);
        var dirY = r * dsin(self.yaw);
        var dirZ = dsin(self.pitch);
        
        var dist = 1000;
        self.camera.target[0] = self.camera.position[0] + dirX * dist;
        self.camera.target[1] = self.camera.position[1] + dirY * dist;
        self.camera.target[2] = self.camera.position[2] + dirZ * dist;
        
        self._needsUpdate = false;
    };
}
