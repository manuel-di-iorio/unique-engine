---
sidebar_position: 3
---

# UeBone

:::warning
Animations module is under costruction and do not works yet.
:::

Represents an individual bone in a skeleton. Inherits from `UeObject3D`.

## Constructor
```js
new UeBone(data = {})
```

### Inherits from [UeObject3D](../core/UeObject3D.md)

## Properties
- `offsetMatrix`: Matrix that transforms from mesh space to the bone's local space (Inverse Bind Pose).
- `index`: Unique index of the bone in the skeleton.
- `type`: `"Bone"`.
- `isBone`: `true`.
