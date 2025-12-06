---
sidebar_position: 3
---

# UeShadowMap

`UeShadowMap` is an internal container for shadow depth information. It manages the render target (surface) used to store shadow depth values during the shadow mapping process.

This class uses a high-precision `r32float` surface format to ensure accurate depth storage and minimize shadow artifacts.

---

## Constructor

```js
new UeShadowMap(width = 1024, height = 1024)
```

### Parameters

| Parameter | Type     | Default | Description                |
| --------- | -------- | ------- | -------------------------- |
| `width`   | `number` | `1024`  | Shadow map width in pixels |
| `height`  | `number` | `1024`  | Shadow map height in pixels |

---

## Properties

| Property  | Type      | Default | Description                                          |
| --------- | --------- | ------- | ---------------------------------------------------- |
| `width`   | `number`  | `1024`  | Shadow map width                                     |
| `height`  | `number`  | `1024`  | Shadow map height                                    |
| `surface` | `pointer` | `-1`    | GameMaker surface ID (r32float format)               |

---

## Methods

### `create()`

Creates the shadow map surface. If a surface already exists, it is freed before creating a new one.

The surface uses `surface_r32float` format for high-precision depth storage (32-bit floating-point).

**Returns:** `self` (for method chaining)

**Example:**
```js
shadowMap.create();
```

---

### `render(light, scene, camera, __queue, __shadowIdx)`

Renders the shadow map from the light's perspective.

This is an internal method called by the renderer during the shadow pass.

**Parameters:**
- `light` (UeLight) - The light casting shadows
- `scene` (UeScene) - The scene to render
- `camera` (UeCamera) - The main scene camera
- `__queue` (array) - Render queue of objects
- `__shadowIdx` (number) - Number of shadow-casting objects

**Process:**
1. Sets the shadow map surface as render target
2. Updates shadow camera position and light space matrix
3. Clears surface to white (representing maximum depth)
4. Sets shadow depth shader (`sh_ue_shadow_map`)
5. Renders all objects with `castShadow = true`
6. Calls `onBeforeShadow()` and `onAfterShadow()` callbacks if defined

**Returns:** `self` (for method chaining)

---

### `dispose()`

Frees the shadow map surface and releases GPU memory.

**Returns:** `self` (for method chaining)

**Example:**
```js
shadowMap.dispose();
```

---

### `getTexture()`

Returns the texture ID of the shadow map surface for use in shaders.

**Returns:** `pointer` - The texture ID

**Example:**
```js
var shadowTexture = shadowMap.getTexture();
shader_set_uniform_f(u_shadowMap, shadowTexture);
```

---

## Surface Format: `surface_r32float`

The shadow map uses a single-channel 32-bit floating-point format:

- **R channel:** Stores depth value (0.0 to 1.0+)
- **Precision:** 32-bit float provides excellent depth precision
- **Range:** Supports depth values beyond 1.0 for large scenes

### Why r32float?

- **High precision:** Minimizes depth fighting and shadow acne
- **Extended range:** Handles large shadow distances
- **Efficient:** Single channel reduces memory bandwidth

---

## Shadow Depth Shader

The shadow map is rendered using a dedicated shader (`sh_ue_shadow_map`) that:

1. Transforms vertex positions to light clip space
2. Writes depth to the color buffer (stored in R channel)
3. Performs depth testing to ensure closest surfaces are rendered

### Shader Output

```glsl
// Simplified shadow depth shader
gl_FragColor = vec4(depth, 0.0, 0.0, 1.0);
```

Where `depth` is the normalized distance from the light camera.

---

### Accessing Light Shadow Maps

```js
// Get shadow map from directional light
const light = new UeDirectionalLight(c_white, 1);
light.castShadow = true;

var shadowMap = light.shadow.map;
show_debug_message($"Shadow map size: {shadowMap.width}x{shadowMap.height}");
show_debug_message($"Surface ID: {shadowMap.surface}");
```

### Shadow Rendering Callbacks

```js
// Define custom shadow rendering behavior
mesh.onBeforeShadow = function() {
    // Custom setup before shadow rendering
    show_debug_message("Rendering shadow for " + name);
};

mesh.onAfterShadow = function() {
    // Cleanup after shadow rendering
};
```

---

## Performance Considerations

### Resolution vs Quality

| Resolution | Quality       | Memory Usage | Performance |
| ---------- | ------------- | ------------ | ----------- |
| 512×512    | Low (aliased) | ~1 MB        | Fast        |
| 1024×1024  | Medium        | ~4 MB        | Good        |
| 2048×2048  | High (sharp)  | ~16 MB       | Moderate    |
| 4096×4096  | Very High     | ~64 MB       | Slow        |

### Optimization Tips

1. **Use appropriate resolution:** Don't use 4096×4096 for small objects
2. **Reuse shadow maps:** Set `renderer.shadowMap.autoUpdate = false` for static scenes
3. **Limit casting objects:** Only set `castShadow = true` on important objects
4. **Tight shadow frustum:** Adjust shadow camera bounds to cover only necessary area

---

## See Also

- [UeDirectionalLightShadow](/docs/reference/lights/shadows/UeDirectionalLightShadow) - Directional light shadows
- [UeLightShadow](/docs/reference/lights/shadows/UeLightShadow) - Base shadow class
- [UeLight](/docs/reference/lights/UeLight) - Light base class
- [UeRenderer](/docs/reference/core/UeRenderer) - Renderer shadow mapping
