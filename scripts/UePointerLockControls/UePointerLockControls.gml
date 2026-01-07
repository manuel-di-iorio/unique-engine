/// @func UePointerLockControls(camera, data)
/// @desc Controls for first person shooter style camera.
/// @param {Struct.UeCamera} camera The camera to control
/// @param {Struct} [data] Configuration data
function UePointerLockControls(camera, data = {}): UeControls(data) constructor {
    self.camera = camera;
    
    // Configurazione Sensibilità
    self.sensitivityX = data[$ "sensitivityX"] ?? 0.1;
    self.sensitivityY = data[$ "sensitivityY"] ?? 0.1;
    
    // Accumulatori rotazione (in gradi)
    self.yaw = 0;   // Rotazione attorno a Z (World Up)
    self.pitch = 0; // Rotazione attorno a X (Local Right)
    
    // Target Lock State
    self.isLocked = false;

    // Metodi di controllo Lock
    static lock = function() {
        window_mouse_set_locked(true);
        self.isLocked = true;
    };

    static unlock = function() {
        window_mouse_set_locked(false);
        self.isLocked = false;
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
        
        // Se non siamo lockati, non ruotiamo
        if (!window_mouse_get_locked()) {
            self.isLocked = false;
            return;
        } else {
            self.isLocked = true;
        }

        // Get Mouse Delta
        var dx = window_mouse_get_delta_x();
        var dy = window_mouse_get_delta_y();

        if (dx == 0 && dy == 0) return;

        // Aggiorna Yaw (Z-axis) e Pitch (X-axis)
        // dx positivo (mouse a destra) -> yaw diminuisce (ruota orario verso Y-)
        self.yaw -= dx * self.sensitivityX;
        
        // dy positivo (mouse giù) -> pitch diminuisce (guarda giù)
        self.pitch -= dy * self.sensitivityY;

        // Clamp Pitch (evita di capovolgersi, limitato a +/- 89)
        self.pitch = clamp(self.pitch, -89, 89);
        
        // --- Aggiorna Camera Target ---
        // UeCamera usa matrix_build_lookat, quindi dobbiamo aggiornare il target point.
        var r = dcos(self.pitch); // Raggio orizzontale
        var dirX = r * dcos(self.yaw);
        var dirY = r * dsin(self.yaw);
        var dirZ = dsin(self.pitch);
        
        // Impostiamo il target a una certa distanza lungo la direzione
        // Questo simula una rotazione "FPS" mantenendo il funzionamento LookAt della camera
        var dist = 1000;
        self.camera.target[0] = self.camera.position[0] + dirX * dist;
        self.camera.target[1] = self.camera.position[1] + dirY * dist;
        self.camera.target[2] = self.camera.position[2] + dirZ * dist;
    };
}
