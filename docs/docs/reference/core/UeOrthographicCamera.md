---
sidebar_position: 7
---

The `UeOrthographicCamera` class creates a 3D camera with orthographic projection in Unique Engine.  
In orthographic projection, objects appear the same size regardless of their distance from the camera, making it ideal for 2D games, technical drawings, or isometric views.

It inherits from `UeCamera`, meaning it includes all camera functionality plus scene graph features from `UeObject3D`.

### Constructor
```js
new UeOrthographicCamera(data = {})
```

### Data parameters

| Key              | Type       | Default                    | Description                                      |
| ---------------- | ---------- | -------------------------- | ------------------------------------------------ |
| `left`           | `number`   | `-view_wport[view] / 2`    | Left plane of the camera frustum                 |
| `right`          | `number`   | `view_wport[view] / 2`     | Right plane of the camera frustum                |
| `top`            | `number`   | `view_hport[view] / 2`     | Top plane of the camera frustum                  |
| `bottom`         | `number`   | `-view_hport[view] / 2`    | Bottom plane of the camera frustum               |
| `near`           | `number`   | `0.1`                      | Near clipping plane                              |
| `far`            | `number`   | `2000`                     | Far clipping plane                               |
| `zoom`           | `number`   | `1`                        | Zoom factor (scales the frustum)                 |
| `view`           | `number`   | `0`                        | Viewport to assign this camera to                |
| `x`, `y`, `z`    | `number`   | `0`, `-100`, `0`           | Initial camera position                          |
| `xt`, `yt`, `zt` | `number`   | `0`, `1`, `0`              | Look-at target coordinates                       |
| `upX`, `upY`, `upZ` | `number` | `0`, `0`, `-1`            | Camera up vector                                 |

### Properties

| Property                 | Type          | Default                  | Description                                                      |
|--------------------------|---------------|--------------------------|------------------------------------------------------------------|
| `isCamera`               | `boolean`     | `true`                   | Indicates that this is a camera                                  |
| `isOrthographicCamera`   | `boolean`     | `true`                   | Indicates that this is an orthographic camera                    |
| `type`                   | `string`      | `"OrthographicCamera"`   | Object type                                                      |
| `left`                   | `number`      | `-width/2`               | Left plane of the viewing frustum                                |
| `right`                  | `number`      | `width/2`                | Right plane of the viewing frustum                               |
| `top`                    | `number`      | `height/2`               | Top plane of the viewing frustum                                 |
| `bottom`                 | `number`      | `-height/2`              | Bottom plane of the viewing frustum                              |
| `near`                   | `number`      | `0.1`                    | Near clipping plane distance                                     |
| `far`                    | `number`      | `2000`                   | Far clipping plane distance                                      |
| `zoom`                   | `number`      | `1`                      | Zoom factor that scales the frustum                              |
| `camera`                 | `Camera`      | `camera_create()`        | The underlying GameMaker camera object                           |
| `target`                 | `UeVector3`   | `(0,1,0)`                | The current look-at target position                              |
| `matrixWorld`            | `UeMatrix4`   | `new UeMatrix4()`        | World transformation matrix of the camera                        |
| `matrixWorldInverse`     | `UeMatrix4`   | `new UeMatrix4()`        | Inverse of `matrixWorld`, used in `camera_set_view_mat()`        |
| `projectionMatrix`       | `UeMatrix4`   | `new UeMatrix4()`        | Projection matrix, used in `camera_set_proj_mat()`               |
| `projectionMatrixInverse`| `UeMatrix4`   | `new UeMatrix4()`        | Inverse of the projection matrix                                 |

## Methods

### updateProjectionMatrix()
```js
updateProjectionMatrix()
```
Updates the camera's projection matrix using orthographic projection.  
The zoom factor is applied to scale the frustum dimensions.

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

- The camera projection is built using `matrix_build_projection_ortho()`
- Objects maintain the same size regardless of distance (parallel projection)
- The frustum is automatically calculated from viewport dimensions if not specified
- The `zoom` property scales the frustum: higher values = zoomed in, lower values = zoomed out
- Perfect for 2D games, isometric views, or technical/architectural visualizations

## Orthographic vs Perspective

| Feature                    | Orthographic                        | Perspective                           |
|----------------------------|-------------------------------------|---------------------------------------|
| Projection type            | Parallel                            | Converging to a point                 |
| Distance affects size      | No                                  | Yes (objects farther = smaller)       |
| Depth perception           | Flat, no depth cues                 | Realistic depth                       |
| Typical use cases          | 2D games, CAD, isometric views      | 3D games, realistic rendering         |
| Frustum shape              | Box (rectangular prism)             | Truncated pyramid                     |

## Example

### Basic Usage
```js
const camera = new UeOrthographicCamera({
  left: -400,
  right: 400,
  top: 300,
  bottom: -300,
  near: 0.1,
  far: 1000,
  x: 100, y: -300, z: 70,
  xt: 0, yt: 0, zt: 0
});

scene.add(camera);
```

### Isometric View
```js
// Create an isometric camera
const camera = new UeOrthographicCamera({
  zoom: 2, // Zoom in 2x
  x: 100, y: -100, z: 100,
  xt: 0, yt: 0, zt: 0
});

// Position creates 45-degree isometric angle
camera.setPosition(100, -100, 100);
camera.target.set(0, 0, 0);
camera.updateMatrixWorld();
```

### Dynamic Zoom
```js
// Zoom in/out dynamically
camera.zoom = 1.5;
camera.updateProjectionMatrix();
```
