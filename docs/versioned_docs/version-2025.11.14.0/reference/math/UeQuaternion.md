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

| Method                       | Returns        | Description                                                                              |
| -------------------------    | -------------- | ---------------------------------------------------------------                          |
| `set()`                      | `sekf`         | Sets the quaternion components.                                                          |
| `clone()`                    | `UeQuaternion` | Returns a copy of this quaternion.                                                       |
| `copy()`                     | `self`         | Copies values from another quaternion.                                                   |
| `normalize()`                | `self`         | Normalizes the quaternion to unit length.                                                |
| `multiply()`                 | `self`         | Multiplies this quaternion by another (combines rotations).                              |
| `setFromAxisAngle()`         | `self`         | Sets the quaternion from a rotation axis and angle.                                      |
| `slerp()`                    | `self`         | Spherically interpolates toward another quaternion.                                      |
| `rotate()`                   | `self`         | Applies rotation around a given axis.                                                    |
| `rotateX()`                  | `self`         | Rotates around the X axis.                                                               |
| `rotateY()`                  | `self`         | Rotates around the Y axis.                                                               |
| `rotateZ()`                  | `self`         | Rotates around the Z axis.                                                               |
| `toMat3()`                   | `UeMatrix3`    | Converts this quaternion to a 3×3 rotation matrix.                                       |
| `setFromRotationMatrix()`    | `self`         | Sets the quaternion from a rotation matrix.                                              |
| `setFromUnitVectors()`       | `self`         | Sets the quaternion from two unit vectors (rotation from → to).                          |
| `identity()`                 | `self`         | Resets this quaternion to the identity rotation.                                         |
| `rotateTowards(q, step)`     | `self`         | Rotates toward another quaternion by a given angular step.                               |
| `conjugate()`                | `self`         | Returns the rotational conjugate (opposite direction).                                   |
| `invert()`                   | `self`         | Inverts this quaternion (same as conjugate if unit length).                              |
| `lengthSq()`                 | `real`         | Returns the squared length of the quaternion.                                            |
| `length()`                   | `real`         | Returns the magnitude (length) of the quaternion.                                        |
| `dot(q)`                     | `real`         | Returns the dot product between this quaternion and `q`.                                 |     
| `angleTo(q)`                 | `real`         | Returns the angle in degrees between this quaternion and `q`.                            |  
| `multiplyQuaternions(a, b)`  | `self`         | Sets this quaternion to the multiplication `a * b`, composing the two rotations.         |       
| `equals(q)`                  | `boolean`      | Returns `true` if all components are approximately equal within `UE_EPSILON`.            |
| `toArray()`                  | `array`        | Returns a 4-element array `[x, y, z, w]`.                                                |
| `setFromEuler()`             | `self`         | Sets the quaternion from Euler angles (in degrees). It assumes imperfections             |



## Example

```js
var q = new UeQuaternion();
q.setFromEuler(0, 90, 0).normalize();

var axis = new UeVector3(0, 1, 0);
q.rotate(axis, 45);

var mat3 = q.toMat3();
```
