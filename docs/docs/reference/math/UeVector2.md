---
sidebar_position: 2
---

A 2D vector class with common vector operations. Useful for positions, directions, and geometry in 2D space.

---

### Constructor

```js
new UeVector2(x = 0, y = 0)
```

### Data parameters

| Name | Type     | Default | Description  |
| ---- | -------- | ------- | ------------ |
| `x`  | `number` | `0`     | X coordinate |
| `y`  | `number` | `0`     | Y coordinate |

## Methods

| Method            | Returns     | Description                                        |
| ----------------- | ----------- | -------------------------------------------------- |
| `set(x, y)`       | `this`      | Sets the X and Y components                        |
| `clone()`         | `UeVector2` | Returns a copy of this vector                      |
| `copy(vec)`       | `this`      | Copies values from another vector                  |
| `add(vec)`        | `this`      | Adds another vector                                |
| `sub(vec)`        | `this`      | Subtracts another vector                           |
| `multiply(vec)`   | `this`      | Multiplies each component by another vector        |
| `scale(s)`        | `this`      | Scales both components by scalar `s`               |
| `dot(vec)`        | `number`    | Dot product with another vector                    |
| `length()`        | `number`    | Magnitude (Euclidean norm)                         |
| `normalize()`     | `this`      | Converts to a unit vector                          |
| `equals(vec)`     | `boolean`   | Checks if two vectors are identical                |
| `lerp(vec, t)`    | `this`      | Linear interpolation toward `vec` by factor `t`    |
| `angleTo(vec)`    | `number`    | Returns angle in radians between the vectors       |
| `distanceTo(vec)` | `number`    | Euclidean distance to another vector               |
| `perp()`          | `UeVector2` | Returns a perpendicular vector (`-y, x`)           |
| `rotate(angle)`   | `this`      | Rotates the vector counterclockwise by angle       |
