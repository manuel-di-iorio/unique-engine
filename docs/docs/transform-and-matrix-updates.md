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

### Auto-Update & Dirty Flags

Unique Engine uses a "dirty flag" system to minimize calculations.

- **`matrixAutoUpdate`** (bool): If `true` (default), the local `matrix` is automatically recalculated from position/rotation/scale.
- **`matrixWorldAutoUpdate`** (bool): If `true` (default), the `matrixWorld` is automatically recalculated based on the parent's world matrix.
- **`matrixWorldNeedsUpdate`** (bool): An internal flag that indicates if the world matrix needs to be refreshed.

The `UeRenderer` automatically calls `updateMatrixWorld()` on the scene graph before rendering, ensuring all matrices are up-to-date.

---

## ⚡ Manual Updates

Sometimes you may want to manually control when matrices are updated, for example to optimize static objects or when moving objects outside the normal render loop.

### `updateMatrix()`
Updates the local `matrix` based on current position, rotation, and scale. Sets `matrixWorldNeedsUpdate = true`.

### `updateMatrixWorld(force)`
Updates the global `matrixWorld` of the object and its children.
- If `force` is true, it recalculates everything even if `matrixWorldNeedsUpdate` is false.
- This is the method called by the renderer.

### `updateWorldMatrix(updateParents, updateChildren)`
A more granular control method:
- `updateParents`: If true, recursively updates parents first.
- `updateChildren`: If true, recursively updates children after.

### `forceUpdate(startFromRoot)`
Forces an update of the local and world matrices on this object and its children, even on static objects (where `matrixAutoUpdate` or `matrixWorldAutoUpdate` is false).
- `startFromRoot`: If true, the update starts from the absolute root of the scene graph, ensuring the entire hierarchy is synchronized. 
- ⚠️ This is an expensive operation and should generally be used during initialization or major scene restructuring.

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
