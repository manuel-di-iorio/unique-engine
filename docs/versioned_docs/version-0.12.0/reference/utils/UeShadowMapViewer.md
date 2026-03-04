---
sidebar_position: 2
---

# UeShadowMapViewer

`UeShadowMapViewer` is a debug utility that renders a visual representation of a light's shadow map on the screen. This is useful for debugging shadow mapping issues, verifying shadow quality, and understanding how shadows are being rendered.

---

## Constructor

```js
new UeShadowMapViewer(light, data = {})
```

### Parameters

| Parameter | Type     | Default | Description                                |
| --------- | -------- | ------- | ------------------------------------------ |
| `light`   | `UeLight` | *required* | The light whose shadow map to display   |
| `data`    | `struct` | `{}`    | Configuration object for viewer properties |

### Data Properties

| Property  | Type      | Default | Description                                    |
| --------- | --------- | ------- | ---------------------------------------------- |
| `enabled` | `boolean` | `true`  | Whether the viewer is currently active         |
| `width`   | `number`  | `256`   | Display width in pixels                        |
| `height`  | `number`  | `256`   | Display height in pixels                       |

---

## Properties

| Property  | Type      | Default | Description                                    |
| --------- | --------- | ------- | ---------------------------------------------- |
| `light`   | `UeLight` | -       | Reference to the light being visualized        |
| `enabled` | `boolean` | `true`  | Whether to render the viewer                   |
| `width`   | `number`  | `256`   | Width of the rendered shadow map preview       |
| `height`  | `number`  | `256`   | Height of the rendered shadow map preview      |

---

## Methods

### `render(camera, x1, y1)`

Renders the shadow map preview at the specified screen coordinates.

This method should be called after the main scene rendering, typically in a draw event.

**Parameters:**
- `camera` (UeCamera) - The main scene camera (not currently used)
- `x1` (number) - X coordinate on screen where to draw the preview
- `y1` (number) - Y coordinate on screen where to draw the preview

**Returns:** Nothing

**Behavior:**
- Returns early if viewer is disabled or light/shadow map is invalid
- Checks if the shadow map surface exists
- Scales the shadow map to fit the viewer's width/height
- Draws the surface at the specified position

---

## Usage Example

```js
// Create a directional light with shadows
const dirLight = new UeDirectionalLight(c_white, 1.5);
dirLight.position.set(100, 200, 150);
dirLight.castShadow = true;
dirLight.shadow.updateMapSize(1024, 1024);
scene.add(dirLight);

// Create a shadow map viewer
const shadowViewer = new UeShadowMapViewer(dirLight, {
    width: 256,
    height: 256,
    enabled: true
});

// In your draw event:
shadowViewer.render(camera, 10, 10); // Top-left corner
```

---

## Debug Workflow

The shadow map viewer is particularly useful for:

1. **Verifying shadow coverage** - Check if your shadow camera frustum properly covers the scene
2. **Diagnosing shadow artifacts** - Inspect depth values to identify acne, peter-panning, or precision issues
3. **Optimizing shadow resolution** - Compare different shadow map sizes visually
4. **Understanding depth distribution** - See how depth values are distributed across the map

---

## Notes

- The shadow map is stored in `r32float` format (32-bit floating-point depth values)
- White pixels represent maximum depth (far plane), darker pixels represent closer geometry
- The viewer automatically scales the shadow map surface to fit the specified display size
- Disabling the viewer (`enabled = false`) prevents rendering without destroying the viewer object
- For point lights with cube shadow maps, you would need 6 separate viewers (one per face) - currently only single-face shadow maps are supported
