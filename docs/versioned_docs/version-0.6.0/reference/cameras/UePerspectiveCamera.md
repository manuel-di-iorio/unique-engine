---
sidebar_position: 2
---

The `UePerspectiveCamera` class creates a 3D camera with a perspective projection in Unique Engine.  
In perspective projection, objects appear smaller as they get farther from the camera, mimicking how human eyes perceive depth.

It inherits from `UeCamera`, meaning it includes all camera functionality plus scene graph features from `UeObject3D`.

### Constructor
```js
new UePerspectiveCamera(data = {})
```

### Data parameters

| Key              | Type       | Default                               | Description                          |
| ---------------- | ---------- | -------------------------             | ------------------------------------ |
| `fov`            | `number`   | `60`                                  | Field of view in degrees             |
| `near`           | `number`   | `0.1`                                 | Near clipping plane                  |
| `far`            | `number`   | `2000`                                | Far clipping plane                   |
| `view`           | `number`   | `0`                                   | Viewport to assign this camera to    |
| `aspect`         | `number`   | `view_wport[view] / view_hport[view]` | Aspect ratio (width/height)          |
| `x`, `y`, `z`    | `number`   | `0`, `-100`, `0`                      | Initial camera position              |
| `xt`, `yt`, `zt` | `number`   | `0`, `1`, `0`                         | Look-at target coordinates           |
| `upX`, `upY`, `upZ` | `number` | `0`, `0`, `-1`                       | Camera up vector                     |

### Properties

| Property                 | Type          | Default                | Description                                                      |
|--------------------------|-------------  |------------------------|------------------------------------------------------------------|
| `isCamera`               | `boolean`     | `true`                 | Indicates that this is a camera                                  |
| `isPerspectiveCamera`    | `boolean`     | `true`                 | Indicates that this is a perspective camera                      |
| `type`                   | `string`      | `"PerspectiveCamera"`  | Object type                                                      |
| `fov`                    | `number`      | `60`                   | Field of view in degrees                                         |
| `aspect`                 | `number`      | `width/height`         | Aspect ratio of the viewport                                     |
| `near`                   | `number`      | `0.1`                  | Near clipping plane distance                                     |
| `far`                    | `number`      | `2000`                 | Far clipping plane distance                                      |
| `camera`                 | `Camera`      | `camera_create()`      | The underlying GameMaker camera object                           |
| `target`                 | `UeVector3`   | `(0,1,0)`              | The current look-at target position                              |
| `matrixWorld`            | `UeMatrix4`   | `new UeMatrix4()`      | World transformation matrix of the camera                        |
| `matrixWorldInverse`     | `UeMatrix4`   | `new UeMatrix4()`      | Inverse of `matrixWorld`, used in `camera_set_view_mat()`        |
| `projectionMatrix`       | `UeMatrix4`   | `new UeMatrix4()`      | Projection matrix, used in `camera_set_proj_mat()`               |
| `projectionMatrixInverse`| `UeMatrix4`   | `new UeMatrix4()`      | Inverse of the projection matrix                                 |


## Methods

### updateProjectionMatrix()
```js
updateProjectionMatrix()
```
Updates the camera's projection matrix using perspective projection based on fov, aspect, near, and far values.

### updateMatrixWorld()
```js
updateMatrixWorld()
```
Inherited from `UeCamera`. Updates the view matrix based on position, target, and up vector.

### dispose()
```js
dispose()
```
Inherited from `UeCamera`. Cleans up the camera resource.

## Notes

- The camera projection is built using `matrix_build_projection_perspective_fov()`
- The default `updateMatrixWorld()` function uses `matrix_build_lookat()` to orient the camera toward target, with up-vector (0, 0, -1), which means that the camera is rotated 90° degrees downwards
- Objects farther from the camera appear smaller, creating realistic depth perception
- This is the most commonly used camera type for 3D games and applications

- Perspective cameras are used internally for point-light shadow faces: six perspective cameras with `fov = 90` are created by `UePointLightShadow` to render omnidirectional shadow maps. Ensure `updateProjectionMatrix()` and `updateMatrixWorld()` are correctly called when the camera parameters change.

## Example
```js
const camera = new UePerspectiveCamera({
  x: 100, y: 80, z: 100,
  xt: 0, yt: 0, zt: 0,
  fov: 75,
  near: 0.1,
  far: 1000
});
```
