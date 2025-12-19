---
sidebar_position: 1
---

# UeLightShadow

`UeLightShadow` is the base class for light shadow controllers in Unique Engine. It provides common properties and helper methods shared by directional and point light shadows.

This class is typically not instantiated directly but serves as a foundation for specific shadow implementations like `UeDirectionalLightShadow` and `UePointLightShadow`.

---

## Constructor

```js
new UeLightShadow(data = {})
```

### Parameters

| Parameter | Type     | Default | Description                                |
| --------- | -------- | ------- | ------------------------------------------ |
| `data`    | `struct` | `{}`    | Configuration object for shadow properties |

### Data Properties

| Property    | Type     | Default | Description               |
| ----------- | -------- | ------- | ------------------------- |
| `mapWidth`  | `number` | `1024`  | Shadow map width in pixels  |
| `mapHeight` | `number` | `1024`  | Shadow map height in pixels |

---

## Properties

| Property  | Type     | Default               | Description                    |
| --------- | -------- | --------------------- | ------------------------------ |
| `mapSize` | `struct` | `{width: 1024, height: 1024}` | Shadow map dimensions |

---

## Usage

This class is used internally by specific light shadow implementations:

- **`UeDirectionalLightShadow`** - For directional lights using orthographic shadow cameras
- **`UePointLightShadow`** - For point lights using cube shadow maps (6 faces)

Example of accessing shadow properties:

```js
const dirLight = new UeDirectionalLight(c_white, 1);
dirLight.castShadow = true;

// Update shadow map resolution
dirLight.shadow.updateMapSize(2048, 2048);
```
