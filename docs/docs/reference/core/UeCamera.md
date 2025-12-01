---
sidebar_position: 5
---

The `UeCamera` is an abstract base class for all cameras in Unique Engine.  
It contains common functionality shared by all camera types and should not be instantiated directly.  
Instead, use one of its subclasses like `UePerspectiveCamera` or `UeOrthographicCamera`.

## Inheritance

```
UeObject3D
    └─ UeCamera (abstract)
        ├─ UePerspectiveCamera
        └─ UeOrthographicCamera
```

### Constructor
```js
new UeCamera(data = {})
```

:::caution
`UeCamera` is an abstract base class and should not be instantiated directly.  
Use `UePerspectiveCamera` or `UeOrthographicCamera` instead.
:::

### Data parameters

| Key              | Type       | Default                               | Description                          |
| ---------------- | ---------- | -------------------------             | ------------------------------------ |
| `view`           | `number`   | `0`                                   | Viewport to assign this camera to    |
| `x`, `y`, `z`    | `number`   | `0`, `-100`, `0`                      | Initial camera position              |
| `xt`, `yt`, `zt` | `number`   | `0`, `1`, `0`                         | Look-at target coordinates           |
| `upX`, `upY`, `upZ` | `number` | `0`, `0`, `-1`                       | Camera up vector                     |

### Properties

| Property                 | Type          | Default                | Description                                                      |
|--------------------------|-------------  |------------------------|------------------------------------------------------------------|
| `isCamera`               | `boolean`     | `true`                 | Indicates that this is a camera                                  |
| `type`                   | `string`      | `"Camera"`             | Object type                                                      |
| `camera`                 | `Camera`      | `camera_create()`      | The underlying GameMaker camera object                           |
| `view`                   | `number`      | `0`                    | The viewport index this camera is assigned to                    |
| `target`                 | `UeVector3`   | `(0,1,0)`              | The current look-at target position                              |
| `upX`, `upY`, `upZ`      | `number`      | `0,0,-1`               | Camera up vector components                                      |
| `matrixWorld`            | `UeMatrix4`   | `new UeMatrix4()`      | World transformation matrix of the camera                        |
| `matrixWorldInverse`     | `UeMatrix4`   | `new UeMatrix4()`      | Inverse of `matrixWorld`, used in `camera_set_view_mat()`        |
| `projectionMatrix`       | `UeMatrix4`   | `new UeMatrix4()`      | Projection matrix, used in `camera_set_proj_mat()`               |
| `projectionMatrixInverse`| `UeMatrix4`   | `new UeMatrix4()`      | Inverse of the projection matrix                                 |

## Methods

### updateMatrixWorld()
```js
updateMatrixWorld()
```
Updates the camera's world matrix and view matrix using a lookat transformation.  
This method calculates the view matrix based on the camera's position, target, and up vector.

### updateProjectionMatrix()
```js
updateProjectionMatrix()
```
Updates the camera's projection matrix.  
This is an abstract method that must be implemented by subclasses.

:::caution
Calling this method on the base `UeCamera` class will throw an error.  
Subclasses must implement their own version.
:::

### dispose()
```js
dispose()
```
Destroys the GameMaker camera instance and cleans up resources.

## Notes

- The camera uses `matrix_build_lookat()` to orient toward the target
- The default up vector is `(0, 0, -1)`, which rotates the camera 90° downwards
- The view matrix is automatically set on the associated viewport
