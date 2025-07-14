---
sidebar_position: 6
---

Represents a quaternion used to encode 3D rotations in a compact and stable way. Useful for interpolating rotations and avoiding gimbal lock, especially in 3D animation and camera movement.

---

## Constructor

```js
new UeQuaternion(x = 0, y = 0, z = 0)
```

### Data parameters

| Name | Type   | Default | Description                                  |
| ---- | ------ | ------- | -------------------------------------------- |
| `x`  | number | `0`     | X component (the constructor auto-fills `w`) |
| `y`  | number | `0`     | Y component                                  |
| `z`  | number | `0`     | Z component                                  |


## Methods

| Method                      | Returns        | Description                                                   |
| --------------------------- | -------------- | ------------------------------------------------------------- |
| `set(x, y, z, w)`           | `self`         | Sets all four quaternion components                           |
| `clone()`                   | `UeQuaternion` | Returns a deep copy of the quaternion                         |
| `copy(q)`                   | `self`         | Copies values from another quaternion                         |
| `normalize()`               | `self`         | Normalizes the quaternion (unit length)                       |
| `multiply(q)`               | `self`         | Multiplies (combines) this quaternion with another            |
| `setFromEuler(rx, ry, rz)`  | `self`         | Sets rotation using Euler angles (degrees)                    |
| `setFromAxisAngle(axis, a)` | `self`         | Sets rotation from an axis and angle in degrees               |
| `rotate(axis, angle)`       | `self`         | Rotates around a specified axis (angle in degrees)            |
| `rotateX(angle)`            | `self`         | Rotates around the X axis                                     |
| `rotateY(angle)`            | `self`         | Rotates around the Y axis                                     |
| `rotateZ(angle)`            | `self`         | Rotates around the Z axis                                     |
| `slerp(q, t)`               | `self`         | Performs spherical linear interpolation toward quaternion `q` |
| `toMat3()`                  | `UeMatrix3`    | Converts this quaternion into a 3×3 rotation matrix           |
| `setFromRotationMatrix(m)`  | `self`         | Sets rotation based on a 4×4 matrix rotation component        |
| `setFromUnitVectors(a, b)`  | `self`         | Sets rotation from one normalized vector to another           |


## Example

```js
var q = new UeQuaternion();
q.setFromEuler(0, 90, 0).normalize();

var axis = new UeVector3(0, 1, 0);
q.rotate(axis, 45);

var mat3 = q.toMat3();
```
