---
sidebar_position: 5
---

# Transform & Matrix Updates

Every `UeObject3D` in Unique Engine has its own local `UeTransform`, and these combine recursively to form the final world transform. The engine handles matrix updates in an efficient way, recalculating only when necessary.

---

## 🔄 Local Transform

Each object has:

- `position` → Vector3 (default is 0,0,0)
- `rotation` → Quaternion (default is 0,0,0,1)
- `scale` → Vector3 (default is 1,1,1)

🧠 Most rotations methods usually expect XYZ euler values, which are converted internally to quaternion components, so you can just work with degrees and forget the math, Unique Engine handles it for you.

---

## 🧮 Internal Matrices

Each object computes the following:

- `matrix` → transformation from local space (based on position, rotation, scale)
- `matrixWorld` → full transform including parent objects

The `matrixWorld` is what the renderer uses for drawing and lighting.

---

## ⚡ Matrix Optimization
Unique Engine minimizes redundant matrix computations using a dirty flag system.

Whenever you call a transform method like .rotateY() or .setScale(), it sets `matrixNeedsUpdate = true`, ensuring the matrix is rebuilt only once during rendering.

This is not automatic if you mutate .position, .rotation or .scale manually:

```js
// ❌ This won't trigger matrix update
mesh.position.x += 1;

// ✅ This will
mesh.translate(1, 0, 0);
```
✅ Best Practice: Always prefer using transform methods to ensure consistent and optimized matrix updates.

---

## 🎮 Common Methods
```js
// Move object directly
object.setPosition(x, y, z);

// Translate (relative)
object.translate(dx, dy, dz);
object.translateX(value);

// Rotate
object.rotate(x, y, z);
object.rotateY(angle);

// Look at a point
object.lookAt(x, y, z);

// Scale
object.setScale(x, y, z);
object.scaleZ(0.5);
```

---

## 🧭 Coordinate System

Unique Engine uses a right-handed coordinate system, where the Z axis is up, to stay consistent with the GameMaker experience.


```markdown
        ↑ +Z (up)
        |
        |
        └───→ +X (right)
       /
      /
    +Y (forward)
```

### 🧱 Common Conventions
The ground plane lies on the XY axis
→ Z = 0 is the default floor height

Vertical motion (e.g., jumping) happens along the Z axis

ℹ️ If you're importing assets from engines with different coordinate systems (like Unity or Blender), make sure to adjust orientation accordingly.
