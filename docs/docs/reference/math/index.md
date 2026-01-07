---
sidebar_position: 0
---

# Math Documentation

The complete Unique Math documentation can be viewed to a dedicated documentation:

**👉 [Visit Unique Math Documentation](https://manuel-di-iorio.github.io/unique-math)**

### Quick Links

- [Vector2](https://manuel-di-iorio.github.io/unique-math/docs/Math/Vector2)
- [Vector3](https://manuel-di-iorio.github.io/unique-math/docs/Math/Vector3)
- [Matrix3](https://manuel-di-iorio.github.io/unique-math/docs/Math/Matrix3)
- [Matrix4](https://manuel-di-iorio.github.io/unique-math/docs/Math/Matrix4)
- [Quaternion](https://manuel-di-iorio.github.io/unique-math/docs/Math/Quaternion)
- [Plane](https://manuel-di-iorio.github.io/unique-math/docs/Math/Plane)
- [Ray](https://manuel-di-iorio.github.io/unique-math/docs/Math/Ray)
- [Box2](https://manuel-di-iorio.github.io/unique-math/docs/Math/Box2)
- [Box3](https://manuel-di-iorio.github.io/unique-math/docs/Math/Box3)
- [Sphere](https://manuel-di-iorio.github.io/unique-math/docs/Math/Sphere)
- [Frustum](https://manuel-di-iorio.github.io/unique-math/docs/Math/Frustum)
- [Euler](https://manuel-di-iorio.github.io/unique-math/docs/Math/Euler)
- [Capsule](https://manuel-di-iorio.github.io/unique-math/docs/Math/Capsule)

## Unique Engine Extensions

Unique Engine extends the base math library with additional utility functions.

### Box3 Extensions
- `box3_set_from_object(box, object)`: Computes the bounding box of an [UeObject3D](../core/UeObject3D.md) and its children.

### Vector3 Extensions
- `vec3_project(vector, camera)`: Projects a vector from world space into NDC space.
- `vec3_unproject(vector, camera)`: Unprojects a vector from NDC space into world space.

