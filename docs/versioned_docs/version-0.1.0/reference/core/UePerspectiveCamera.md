---
sidebar_position: 6
---

The `UePerspectiveCamera` class creates a 3D camera with a perspective projection in Unique Engine.  
It inherits from `UeObject3D`, meaning it includes all transform and scene graph functionality.

### Constructor
```js
new UePerspectiveCamera(data = {})
```

### Data parameters

| Key              | Type       | Default                               | Description                          |
| ---------------- | ---------- | -------------------------             | ------------------------------------ |
| `fov`            | `number`   | `60`                                  | Field of view in degrees             |
| `near`           | `number`   | `0.1`                                 | Near clipping plane                  |
| `far`            | `number`   | `32000`                               | Far clipping plane                   |
| `view`           | `number`   | `0`                                   | Viewport to assign this camera to    |
| `aspect`         | `number`   | `view_wport[view] / view_hport[view]` | Aspect ratio (width/height)          |
| `x`, `y`, `z`    | `number`   | `0`, `-100`, `0`                      | Initial camera position              |
| `xt`, `yt`, `zt` | `number`   | `0`                                   | Look-at target coordinates           |

### Properties

| Property                 | Type          | Default                | Description                                                      |
|--------------------------|-------------  |------------------------|------------------------------------------------------------------|
| `isCamera`               | `boolean`     | `true`                 | Indicates that this is a camera                                  |
| `isPerspectiveCamera`    | `boolean`     | `true`                 | Indicates that this is a perspective camera                      |
| `type`                   | `string`      | `"PerspectiveCamera"`  | Object type                                                      |
| `camera`                 | `Camera`      | `camera_create()`      | The underlying GameMaker camera object                           |
| `target`                 | `UeVector3`   | `0,0,0`                | The current look-at target position                              |
| `matrixWorld`            | `UeMatrix4`   | `new UeMatrix4()`      | World transformation matrix of the camera                        |
| `matrixWorldInverse`     | `UeMatrix4`   | `new UeMatrix4()`      | Inverse of `matrixWorld`, used in `camera_set_view_mat()`        |
| `projectionMatrix`       | `UeMatrix4`   | `new UeMatrix4()`      | Projection matrix, used in `camera_set_proj_mat()`               |
| `projectionMatrixInverse`| `UeMatrix4`   | `new UeMatrix4()`      | Inverse of the projection matrix                                 |


## Methods

```js
dispose()
```
Cleanup the camera resource.

## Notes

- The camera projection is built using `matrix_build_projection_perspective_fov()`.
- The default .updateMatrixWorld() function uses `matrix_build_lookat()` to orient the camera toward target, with up-vector (0, 0, -1), which means that the camera is rotated 90° degrees downwards.

## Example
```js
const camera = new UePerspectiveCamera({
  x: 100, y: 80, z: 100,
  xt: 0, yt: 0, zt: 0,
  fov: 75
});

scene.add(camera);
```
