function OrbitControls(camera, data = {}): Controls(data) constructor {
    self.camera = camera;
    
    self.target = data[$ "target"] ?? new Vec3(0, 0, 0);
    self.radius = max(0.1, data[$ "radius"] ?? 100);
    self.azimuth = data[$ "azimuth"] ? degtorad(data.azimuth) : 0;
    self.elevation = data[$ "elevation"] ? degtorad(data.elevation) : 0;
    
    autoRotate = true;
    autoRotateSpeed = .01;

    function update() {
        if (autoRotate) {
            self.azimuth += self.autoRotateSpeed;
        }
            
        self.elevation = clamp(self.elevation, -pi * 0.49, pi * 0.49);

        var xx = self.target.x + self.radius * cos(self.elevation) * cos(self.azimuth);
        var yy = self.target.y + self.radius * cos(self.elevation) * sin(self.azimuth);
        var zz = self.target.z + self.radius * sin(self.elevation);

        self.camera.position.set(xx, yy, zz);
        self.camera.target.copy(self.target);
    }
}
