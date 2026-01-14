/**
 * UeQuadGeometry
 * 
 * A simple quad geometry in Normalized Device Coordinates (NDC).
 * NDC ranges from -1 to +1 on both X and Y axes.
 * 
 * When rendered with identity matrices, this quad covers the entire screen,
 * making it perfect for fullscreen post-processing effects.
 */
function UeQuadGeometry(data = {}): UeGeometry(data) constructor {
  type = "QuadGeometry";

  // This is lighter than the default format (no normals/color needed for fullscreen quad)
  self.format = global.UE_VFORMAT_PU;

  // Optimization: Single large triangle covering the entire NDC space
  // The triangle vertices are:
  // 1. Bottom-Left (-1, -1)
  // 2. Far-Right   ( 3, -1)
  // 3. Far-Top     (-1,  3)

  self.position = [
    -1, -1, 0,
    3, -1, 0,
    -1, 3, 0
  ];

  self.uv = [
    0, 1,
    2, 1,
    0, -1
  ];

  self.build();
}

/**
 * UeFullscreenQuad
 * 
 * A utility class for rendering fullscreen post-processing effects.
 */
function UeFullscreenQuad(material = undefined) constructor {
  self.material = material;
  self.geometry = new UeQuadGeometry();

  function dispose() {
    gml_pragma("forceinline");
    if (self.geometry != undefined) {
      self.geometry.dispose();
      self.geometry = undefined;
    }
    self.material = undefined;
    return self;
  }

  function render(texture = -1, skipMaterial = false) {
    gml_pragma("forceinline");

    if (!skipMaterial) self.material.use();

    var _cull = gpu_get_cullmode();
    var _ztest = gpu_get_ztestenable();
    var _zwrite = gpu_get_zwriteenable();

    gpu_set_ztestenable(false);
    gpu_set_zwriteenable(false);
    gpu_set_cullmode(cull_noculling);

    matrix_set(matrix_projection, global.UE_MAT4_IDENTITY);
    matrix_set(matrix_view, global.UE_MAT4_IDENTITY);
    matrix_set(matrix_world, global.UE_MAT4_IDENTITY);

    vertex_submit(self.geometry.vb, pr_trianglelist, texture);

    gpu_set_cullmode(_cull);
    gpu_set_ztestenable(_ztest);
    gpu_set_zwriteenable(_zwrite);

    return self;
  }
}
