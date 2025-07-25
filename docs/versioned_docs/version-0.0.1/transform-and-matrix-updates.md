---
sidebar_position: 5
---

# Transform & Matrix Updates

Every `UeObject3D` in Unique Engine has its own local `UeTransform`, and these combine recursively to form the final world transform. The engine handles matrix updates in an efficient way, recalculating them only one time per frame. 

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

## ⚡ Static Objects

Unique Engine will skip matrix updates whenever they have the `matrixAutoUpdate` flag set to `false`. 
This is useful to avoid doing calculations for objects that don't move. 
You may still update their matrix calling `forceUpdate()` after modifying their properties

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

Unique Engine uses a right-handed coordinate system, where the Y+ is the forward/depth axis (where the camera looks at), and the Z+ is the up axis (sky).

```markdown
+Z (up)
↑
|   
|  / +Y (forward or depth)
| /
|/
└───→ +X (right)
```

### 🧱 Common Conventions
The ground plane lies on the XY axis
→ Z = 0 is the default floor height

Vertical motion (e.g., jumping) happens along the Z axis

ℹ️ If you're importing assets from engines with different coordinate systems (like Unity or Blender), make sure to adjust orientation accordingly.
