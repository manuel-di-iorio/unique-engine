---
sidebar_position: 5
---

A helper class for visualizing a 3D camera's view frustum in world space. Useful for debugging projection matrices, visibility, and frustum culling logic.
This helper is actually useful only when viewing the scene from a second camera

## Constructor

```js
new UeCameraHelper(camera, color = c_yellow)
```

> Inherits from [UeLineSegments](/docs/reference/objects/UeLineSegments)

## Properties

| Name         | Type                     | Description                                                       |
| ------------ | ------------------------ | ----------------------------------------------------------------- |
| `camera`     | `Object`                 | Reference to the associated camera.                               |
| `color`      | `GM.Color`               | Line color of the frustum (c_yellow by default).                  |


## Methods

| Method                               | Returns | Description                                                        |
| ------------------------------------ | ------- | --------------------------------------------------------           |
| `.update()`         | `self`  | Updates the helper's position and rotation to align with the camera's world matrix. |
| `.setColors(newCol)` | `self`  | Sets a new line color and rebuilds the geometry.                                    |
| `.dispose()`        | `self`  | Frees GPU resources used by the helper.                                             |
