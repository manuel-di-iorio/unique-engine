---
sidebar_position: 6
---

Helper object to assist with visualizing a `UeDirectionalLight` effect on the scene. This consists of a plane and a line representing the light's position and direction.

## Constructor

```js
new UeDirectionalLightHelper(light, size = 1, color = undefined)
```

> Inherits from [UeObject3D](/docs/reference/core/UeObject3D)

### Parameters

| Name  | Type                  | Default     | Description                                                                 |
| ----- | --------------------- | ----------- | --------------------------------------------------------------------------- |
| light | `UeDirectionalLight`  | `undefined` | The light to be visualized.                                                 |
| size  | `number`              | `1`         | The dimensions of the plane.                                                |
| color | `Color`               | `undefined` | The helper's color. If not set, the helper will take the color of the light. |

## Properties

| Property      | Type      | Description                                                                              |
| ------------- | --------- | ---------------------------------------------------------------------------------------- |
| `light`       | `Object`  | The `UeDirectionalLight` being visualized.                                               |
| `color`       | `Color`   | The color parameter passed in the constructor.                                           |
| `lightPlane`  | `UeLine`  | Contains the square showing the location of the directional light.                       |
| `targetLine`  | `UeLine`  | Represents the line pointing towards the target of the directional light.                |

## Methods

| Method      | Returns | Description                                                                         |
| ----------- | ------- | ----------------------------------------------------------------------------------- |
| `.update()` | `self`  | Updates the helper to match the position and direction of the light being visualized. |
| `.dispose()`| `self`  | Frees the GPU-related resources allocated by this instance.                          |

## Example

```js
const light = new UeDirectionalLight(c_white, 1);
scene.add(light);

const helper = new UeDirectionalLightHelper(light, 5);
scene.add(helper);

// In your step/update event
helper.update();
```
