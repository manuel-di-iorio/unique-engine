---
sidebar_position: 2
---

# UeDirectionalLightShadow

`UeDirectionalLightShadow` manages shadow configuration for directional lights. It uses an orthographic camera to capture shadow depth information, simulating sunlight or other distant light sources that produce parallel light rays.

This class is automatically instantiated when creating a `UeDirectionalLight` and is accessible via the light's `shadow` property.

---

## Constructor

```js
new UeDirectionalLightShadow(data = {})
```

> Inherits from [UeLightShadow](/docs/reference/lights/shadows/UeLightShadow)

### Parameters

| Parameter | Type     | Default | Description                                |
| --------- | -------- | ------- | ------------------------------------------ |
| `data`    | `struct` | `{}`    | Configuration object for shadow properties |

---

## Properties

| Property           | Type                        | Default     | Description                                      |
| ------------------ | --------------------------- | ----------- | ------------------------------------------------ |
| `camera`           | `UeOrthographicCamera`      | Auto-created | Shadow camera with orthographic projection       |
| `map`              | `UeShadowMap`               | Auto-created | Shadow map render target (r32float surface)      |
| `lightSpaceMatrix` | `UeMatrix4`                 | Auto-created | Transformation matrix (projection × view)        |
| `mapSize`          | `struct`                    | `{width: 1024, height: 1024}` | Inherited from UeLightShadow |

### Shadow Camera Configuration

The orthographic camera is initialized with default bounds:

```js
{
    left: -1000,
    right: 1000,
    top: -1000,
    bottom: 1000
}
```

You can adjust these bounds to control the shadow frustum size:

```js
const light = new UeDirectionalLight(c_white, 1);
light.castShadow = true;
light.shadow.camera.left = -500;
light.shadow.camera.right = 500;
light.shadow.camera.top = -500;
light.shadow.camera.bottom = 500;
```

---

## Methods

### `updateMapSize(width, height)`

Updates the shadow map size and recreates the render target.

**Parameters:**
- `width` (number) - New shadow map width
- `height` (number) - New shadow map height

**Returns:** `self` (for method chaining)

**Example:**
```js
light.shadow.updateMapSize(2048, 2048); // Higher resolution shadows
```

---

### `updateMatrices(light)`

Updates the light space matrix and positions the shadow camera based on the light's position and target.

This method is called internally by the renderer during shadow map rendering.

**Parameters:**
- `light` (UeDirectionalLight) - The directional light that owns this shadow

**Process:**
1. Positions shadow camera at the light's position
2. Orients camera to look at the light's target position
3. Updates camera's world matrix
4. Applies camera matrices to GameMaker camera
5. Calculates light space matrix: `Projection × View`

**Returns:** `self` (for method chaining)

---

### `dispose()`

Disposes of shadow resources (camera and shadow map).

**Returns:** `self` (for method chaining)

**Example:**
```js
light.shadow.dispose();
```

---

## Usage Example

### Basic Shadow Setup

```js
// Create directional light with shadows
const sun = new UeDirectionalLight(c_white, 1, {
    color: c_white,
    intensity: 1.5
});

sun.castShadow = true;
sun.position.set(100, 200, 150);
sun.target.position.set(0, 0, 0);

// Configure shadow quality
sun.shadow.updateMapSize(2048, 2048);

// Adjust shadow camera bounds
sun.shadow.camera.left = -800;
sun.shadow.camera.right = 800;
sun.shadow.camera.top = -800;
sun.shadow.camera.bottom = 800;

scene.add(sun);
```

### Enabling Renderer Shadow Mapping

```js
const renderer = new UeRenderer({
    shadowMap: {
        enabled: true,      // Enable shadow rendering
        autoUpdate: true,   // Auto-update every frame
    }
});

renderer.render(scene, camera);
```

### Object Shadow Configuration

```js
// Make mesh cast and receive shadows
const mesh = new UeMesh(geometry, material);
mesh.castShadow = true;    // This object casts shadows
mesh.receiveShadow = true;  // This object receives shadows
scene.add(mesh);
```

---

## How It Works

1. **Shadow Map Rendering (Pass 1):**
   - Renderer positions shadow camera at light position
   - Camera looks at light target
   - Scene is rendered from light's perspective to depth texture
   - Depth values are stored in `r32float` surface

2. **Main Scene Rendering (Pass 2):**
   - Light space matrix is passed to material shaders
   - Fragment positions are transformed to light space
   - Shadow map is sampled to determine if fragment is in shadow
   - Shadow factor modulates lighting contribution

3. **Light Space Matrix:**
   ```
   lightSpaceMatrix = projectionMatrix × viewMatrix
   ```
   This transforms world positions into the shadow camera's clip space.

---

## Performance Considerations

- **Shadow Map Resolution:** Higher resolution (e.g., 2048×2048) provides sharper shadows but uses more VRAM and GPU time
- **Shadow Camera Bounds:** Tighter bounds improve shadow quality by using more of the shadow map's resolution
- **Update Frequency:** Set `renderer.shadowMap.autoUpdate = false` for static scenes and manually trigger updates when needed
