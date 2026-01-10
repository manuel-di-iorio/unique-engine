---
sidebar_position: 1
---

All lights in Unique Engine inherit from `UeLight`. These include `AmbientLight`, `DirectionalLight`, and `PointLight`.

Lights affect materials that have lighting enabled (e.g. `UeMeshStandardMaterial`) and are collected by the renderer from the scene.

> Note: By default, the engine supports up to **1 Directional Light** and **8 Point Lights** simultaneously on the standard shader. Only 1 Directional and 1 Point light can cast shadows at the same time.

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
| `distance`  | `number`  | `500`       | (Only for point lights) max influence distance |
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
new UePointLight(color = c_white, intensity = 1, distance = 0, decay = 2, data = {})
```
Emits light in all directions from a single point, attenuated by distance. Supports omnidirectional shadow casting.

**Constructor Parameters**

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `color` | `color` | `c_white` | Light color |
| `intensity` | `number` | `1` | The light's strength/intensity (candela) |
| `distance` | `number` | `0` | Maximum range of the light. 0 means no limit. |
| `decay` | `number` | `2` | The amount the light dims along the distance of the light. |
| `data` | `struct` | `{}` | Additional data (e.g. `shadowNear`, `shadowFar`) |

**Properties**

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `distance` | `number` | `0` | Maximum distance the light affects. |
| `decay` | `number` | `2` | The amount the light dims along the distance. |
| `power` | `number` | | The light's power (luminous power in lumens). |
| `isPointLight`| `boolean`| `true` | Read-only flag for type testing. |
| `shadow` | `UePointLightShadow` | Auto-created | Shadow configuration (6 cube faces) |

**Example:**
```js
const lamp = new UePointLight(c_yellow, 1.5, 500, 2);
lamp.position.set(10, 50, 10);
lamp.castShadow = true;
scene.add(lamp);
```


## 🔁 Usage in Scene

Lights should be added to a UeScene using .add() and will be automatically collected by UeRenderer.

```js
const ambient = new UeAmbientLight(c_gray);
const sun = new UeDirectionalLight(c_white, 2);
const point = new UePointLight(c_yellow, 1, 500);

scene.add(ambient, sun, point);
```

Lights are passed to the material shader through uniforms like:

- ueAmbient
- ueDirLightDir0, ueDirLightColor0, ueDirLightIntensity0
- uePointLightPosition0, uePointLightRange0, uePointLightIntensity0, uePointLightDecay0, etc.

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
const lamp = new UePointLight(c_yellow, 1, 500);
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
