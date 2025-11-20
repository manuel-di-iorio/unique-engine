---
sidebar_position: 3
---

Displays the 3 main coordinate axes in red (X), green (Y), and blue (Z). Useful for debugging object orientation in 3D space.

## Constructor

```js
new UeAxesHelper(size = 1)
```

> Inherits from [UeLineSegments](/docs/reference/objects/UeLineSegments)

## Methods

| Method                               | Returns | Description                                              |
| ------------------------------------ | ------- | -------------------------------------------------------- |
| `.setColors(xColor, yColor, zColor)` | `self`  | Changes axis colors.                                     |
| `.dispose()`                         | `self`  | Frees GPU resources used by the helper.                  |
