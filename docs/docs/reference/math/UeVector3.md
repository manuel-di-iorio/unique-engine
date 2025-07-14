---
sidebar_position: 3
---

A 3D vector class that supports common vector math operations. Used for positions, directions, and geometric calculations in 3D space.

---

## Constructor

```js
new UeVector3(x = 0, y = 0, z = 0)
```

### Data parameters

| Name | Type     | Default | Description |
| ---- | -------- | ------- | ----------- |
| `x`  | `number` | `0`     | X component |
| `y`  | `number` | `0`     | Y component |
| `z`  | `number` | `0`     | Z component |

## Methods

| Method                   | Returns     | Description                                                    |
| ------------------------ | ----------- | -------------------------------------------------------------- |
| `set(x, y, z)`           | `this`      | Sets the vector components                                     |
| `clone()`                | `UeVector3` | Returns a deep copy                                            |
| `copy(vec)`              | `this`      | Copies values from another vector                              |
| `add(vec)`               | `this`      | Adds another vector                                            |
| `sub(vec)`               | `this`      | Subtracts another vector                                       |
| `multiply(vec)`          | `this`      | Multiplies by another vector component-wise                    |
| `scale(scalar)`          | `this`      | Multiplies all components by a scalar                          |
| `dot(vec)`               | `number`    | Dot product with another vector                                |
| `cross(vec)`             | `UeVector3` | Returns the cross product with another vector                  |
| `length()`               | `number`    | Computes the Euclidean length of the vector                    |
| `normalize()`            | `this`      | Normalizes the vector (makes it unit length)                   |
| `equals(vec)`            | `boolean`   | Checks if the vectors are equal in all components              |
| `lerp(vec, t)`           | `this`      | Linearly interpolates toward another vector                    |
| `angleTo(vec)`           | `number`    | Returns the angle (in degrees) between this and another vector |
| `distanceTo(vec)`        | `number`    | Euclidean distance to another vector                           |
| `distanceSquaredTo(vec)` | `number`    | Squared distance (faster, avoids square root)                  |
