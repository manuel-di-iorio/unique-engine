function UeQuadGeometry(data = {}): UeBufferGeometry(data) constructor {
    type = "QuadGeometry";
    
    // Create a fullscreen quad with position and UV coordinates
    // Using NDC coordinates: -1 to 1 for position
    var vertices = [
        // First triangle (top-left, bottom-left, bottom-right)
        { x: -1, y:  1, z: 0, nx: 0, ny: 0, nz: 1, u: 0, v: 1, color: c_white, alpha: 1 },
        { x: -1, y: -1, z: 0, nx: 0, ny: 0, nz: 1, u: 0, v: 0, color: c_white, alpha: 1 },
        { x:  1, y: -1, z: 0, nx: 0, ny: 0, nz: 1, u: 1, v: 0, color: c_white, alpha: 1 },
        
        // Second triangle (top-left, bottom-right, top-right)
        { x: -1, y:  1, z: 0, nx: 0, ny: 0, nz: 1, u: 0, v: 1, color: c_white, alpha: 1 },
        { x:  1, y: -1, z: 0, nx: 0, ny: 0, nz: 1, u: 1, v: 0, color: c_white, alpha: 1 },
        { x:  1, y:  1, z: 0, nx: 0, ny: 0, nz: 1, u: 1, v: 1, color: c_white, alpha: 1 }
    ];
    
    self.vertices = vertices;
}


function UeFullscreenQuad(material) constructor {
  self.material = material;
  self.geometry = new UeQuadGeometry();
  self.geometry.build();
  
  self.mesh = new UeMesh(self.geometry, self.material);

  self.__camera = new UeOrthographicCamera({
    left: -1,
    right: 1,
    top: 1,
    bottom: -1,
    near: -1,
    far: 0,
    view: 1
  });
  // self.__camera.setPosition(readTarget.width / 2, readTarget.height / 2, 0);
  // self.__camera.target.set(readTarget.width / 2, readTarget.height / 2, 0);
  self.__camera.upX = 0;
  self.__camera.upY = 1;
  self.__camera.upZ = 0;
  self.__camera.updateMatrixWorld();

  function dispose() {
    gml_pragma("forceinline");
    if (self.geometry != undefined) {
      self.geometry.dispose();
      self.geometry = undefined;
    }
    if (self.material != undefined) {
      self.material.dispose();
      self.material = undefined;
    }
    self.mesh = undefined;
    return self;
  }

  function render(renderer) {
    gml_pragma("forceinline");
    
    if (self.mesh != undefined) {
      renderer.render(self.mesh, self.__camera);
    }
    
    return self;
  }
}
