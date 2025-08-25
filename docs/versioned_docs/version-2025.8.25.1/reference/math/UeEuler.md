---
sidebar_position: 13
---

Represents Euler angles for rotations in 3D space.
Angles are stored in degrees, and rotations can be applied in a specified order (`XYZ`, `YXZ`, `ZXY`, `ZYX`, `YZX`, `XZY`).

---

## Constructor

```js
new UeEuler(x = 0, y = 0, z = 0, order = "XYZ");
```

## Properties

| Property  | Type    | Description                                |
| --------- | ------- | ------------------------------------------ |
| `isEuler` | Boolean | Flag to identify the object as Euler type. |
| `x`       | Float   | Rotation around X-axis (radians).          |
| `y`       | Float   | Rotation around Y-axis (radians).          |
| `z`       | Float   | Rotation around Z-axis (radians).          |
| `order`   | String  | Rotation order (`XYZ` by default).         |

## Methods

| Method                                             | Returns   | Description                                                                   |
| -------------------------------------------------- | --------- | ----------------------------------------------------------------------------- |
| `set(x, y, z, order = "XYZ")`                      | `self`    | Sets the Euler angles and optionally the rotation order.                      |
| `clone()`                                          | `UeEuler` | Returns a new `UeEuler` instance with the same angles and order.              |
| `copy(euler)`                                      | `self`    | Copies angles and order from another `UeEuler`.                               |
| `equals(euler)`                                    | `Boolean` | Returns true if this Euler has the same angles and order as `euler`.          |
| `fromArray(array)`                                 | `self`    | Sets Euler angles (and optionally order) from an array.                       |
| `toArray(array = array_create(4), offset = 0)`     | `self`    | Writes angles and order to an array and returns it.                           |
| `setFromVector3(vector, order = undefined)`        | `self`    | Sets Euler angles from a 3D vector; optionally updates the rotation order.    |
| `reorder(newOrder)`                                | `self`    | Changes the rotation order by converting to quaternion and back.              |
| `setFromQuaternion(quaternion, order = undefined)` | `self`    | Sets Euler angles from a quaternion, respecting the specified rotation order. |
| `setFromRotationMatrix(matrix, order = undefined)` | `self`    | Sets Euler angles from a 4x4 rotation matrix according to the rotation order. |
