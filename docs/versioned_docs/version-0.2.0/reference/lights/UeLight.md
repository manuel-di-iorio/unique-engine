---
sidebar_position: 1
---

All lights in Unique Engine inherit from `UeLight`. These include `AmbientLight`, `DirectionalLight`, and `PointLight`.

Lights affect materials that have lighting enabled (e.g. `UeMeshStandardMaterial`) and are collected by the renderer from the scene.

---

```js
new UeLight(data = {})
```

> Inherits from [UeObject3D](/docs/reference/core/UeObject3D)

### Properties

| Property    | Type      | Default     | Description                                    |
| ----------- | --------- | ----------- | ---------------------------------------------- |
| `isLight`   | `boolean` | `true`      | Identifies this object as a light              |
| `type`      | `string`  | `Light`     | Object type                                    |
| `name`      | `string`  | undefined   | Object name (optional)                         |
| `lightType` | `string`  | `"Light"`   | Specific light type (`"AmbientLight"`, etc.)   |
| `intensity` | `number`  | `1`         | Brightness multiplier for this light           |
| `enabled`   | `boolean` | `true`      | Whether the light is currently active          |
| `range`     | `number`  | `undefined` | (Only for point lights) max influence distance |
| `color`     | `array`   | `c_dkgray`  | RGB color as normalized array `[r, g, b]`      |

## Methods

```js
setColor(color)
```
Sets the RGB color of the light. Accepts a GM color constant like c_red.

```js
toJSON()
```

Returns an object representing this entity's properties. Not all props may be included.

🌌 **UeAmbientLight**

```js
new UeAmbientLight(color = c_white, data = {})
```
Ambient lights apply uniform color to all visible fragments. They are not directional and don't cast shadows.

🌞 **UeDirectionalLight**
```js
new UeDirectionalLight(color = c_white, intensity = 1, data = {})
```
Simulates sunlight-like directional lighting with parallel light rays. Light direction is determined by the vector from the light's position to its target position.

**Properties**

| Property   | Type        | Default        | Description                                    |
| ---------- | ----------- | -------------- | ---------------------------------------------- |
| `target`   | `UeObject3D`| Auto-created   | Object3D that the light points at (default: origin) |
| `shadow`   | `UeDirectionalLightShadow` | Auto-created | Shadow configuration and camera |

**Methods:**
  
- `getDirection()` - Returns normalized direction vector from position to target

**Example:**
```js
const sun = new UeDirectionalLight(c_white, 1.5);
sun.position.set(100, 200, 150);
sun.target.position.set(0, 0, 0);
sun.castShadow = true;
scene.add(sun);
```


💡 **UePointLight**

```js
new UePointLight(range = 1000, data = {})
```
Emits light in all directions from a single point, attenuated by distance. Supports omnidirectional shadow casting.

**Data Parameters**

| Key           | Type     | Default | Description                              |
| ------------- | -------- | ------- | ---------------------------------------- |
| `color`       | `color`  | `c_white` | Light color                            |
| `shadowNear`  | `number` | `0.5`   | Near plane for shadow cameras            |
| `shadowFar`   | `number` | `range` | Far plane for shadow cameras             |

**Properties**

| Property | Type                  | Default | Description                              |
| -------- | --------------------- | ------- | ---------------------------------------- |
| `range`  | `number`              | `1000`  | Maximum distance the light affects       |
| `shadow` | `UePointLightShadow`  | Auto-created | Shadow configuration (6 cube faces) |

**Example:**
```js
const lamp = new UePointLight(500, { 
    color: c_yellow,
    shadowNear: 1.0,
    shadowFar: 500
});
lamp.position.set(10, 50, 10);
lamp.castShadow = true;
scene.add(lamp);
```


## 🔁 Usage in Scene

Lights should be added to a UeScene using .add() and will be automatically collected by UeRenderer.

```js
const ambient = new UeAmbientLight(c_gray);
const sun = new UeDirectionalLight(0, 45, { color: c_white, intensity: 2 });
const point = new UePointLight(500, { color: c_yellow });

scene.add(ambient, sun, point);
```

Lights are passed to the material shader through uniforms like:

- ueAmbient
- ueDirLightDir0, ueDirLightColor0, ueDirLightIntensity0
- uePointLightPosition0, uePointLightRange0, etc.

## Shadow Properties

Lights can cast shadows when `castShadow` is enabled. The renderer will create and update shadow maps for each shadow-casting light.

| Property     | Type      | Default | Description                                                  |
| ------------ | --------- | ------- | ------------------------------------------------------------ |
| `castShadow` | `boolean` | `false` | Whether this light casts shadows                             |
| `shadow`     | `object`  | Auto-created | Shadow controller (type depends on light)                |

### Shadow Controllers by Light Type

- **DirectionalLight:** Uses [`UeDirectionalLightShadow`](/docs/reference/lights/shadows/UeDirectionalLightShadow) with orthographic camera
- **PointLight:** Uses `UePointLightShadow` with 6 perspective cameras (cube map)
- **AmbientLight:** Does not support shadows

### Shadow Map Configuration

```js
// Configure shadow map resolution
light.shadow.updateMapSize(2048, 2048);

// Access shadow map size
const { width, height } = light.shadow.mapSize;

// For directional lights, configure shadow camera bounds
light.shadow.camera.left = -500;
light.shadow.camera.right = 500;
light.shadow.camera.top = -500;
light.shadow.camera.bottom = 500;
```

### Usage Example

```js
// Directional light with shadows
const sun = new UeDirectionalLight(c_white, 1.5);
sun.castShadow = true;
sun.shadow.updateMapSize(2048, 2048);
sun.position.set(100, 200, 150);
scene.add(sun);

// Point light with omnidirectional shadows
const lamp = new UePointLight(500, { color: c_yellow });
lamp.castShadow = true;
lamp.shadow.updateMapSize(1024, 1024);
lamp.position.set(10, 50, 10);
scene.add(lamp);

// Objects must be configured to cast/receive shadows
mesh.castShadow = true;    // This object casts shadows
mesh.receiveShadow = true; // This object receives shadows

// Enable shadows in renderer
renderer.shadowMap.enabled = true;
renderer.shadowMap.autoUpdate = true;
```

### Renderer Shadow Configuration

To enable shadow rendering, configure the renderer:

```js
const renderer = new UeRenderer({
    shadowMap: {
        enabled: true,       // Enable shadow map rendering
        autoUpdate: true,    // Update shadows every frame
        needsUpdate: false   // Manual update trigger
    }
});
```

See [UeRenderer](/docs/reference/core/UeRenderer) for more details on shadow rendering.
