---
sidebar_position: 12
---

A class representing a 3D view frustum used for visibility testing and culling operations. It maintains six clipping planes and provides methods to test intersection against points, boxes, spheres, and objects.

This class is used internally from the renderer.

---

## Constructor

```js
new UeFrustum()
```

### Properties

| Name     | Type         | Description                      |
| -------- | ------------ | -------------------------------- |
| `planes` | `UePlane[6]` | Array of 6 planes in the frustum |


## Methods

| Method                            | Returns     | Description                                                                 |
| --------------------------------- | ----------- | --------------------------------------------------------------------------- |
| `clone()`                         | `UeFrustum` | Returns a deep copy of this frustum                                         |
| `containsPoint(point)`            | `boolean`   | Returns `true` if the point is inside the frustum                           |
| `copy(frustum)`                   | `self`      | Copies the planes from another frustum                                      |
| `intersectsBox(box)`              | `boolean`   | Returns `true` if the box intersects the frustum                            |
| `intersectsObject(object)`        | `boolean`   | Returns `true` if the object's bounding sphere intersects the frustum       |
| `intersectsSphere(sphere)`        | `boolean`   | Returns `true` if the sphere intersects the frustum                         |
| `intersectsSprite(sprite)`        | `boolean`   | Returns `true` if the sprite intersects the frustum (using bounding sphere) |
| `set(p0, p1, p2, p3, p4, p5)`     | `self`      | Sets the frustum planes directly                                            |
| `setFromProjectionMatrix(matrixArray)` | `self`      | Extracts frustum planes from a projection matrix (4x4 array)           |

## Notes

- The intersectsObject method will return true by default if the object lacks a bounding sphere (safe approach).
