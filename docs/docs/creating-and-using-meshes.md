---
sidebar_position: 3
---

# Creating and Using Meshes

Meshes are built from geometry classes (primitives), which define their vertex data. Each geometry can be reused across multiple meshes, and passed directly when creating a new mesh.

🔹 Example: Creating a circular terrain
```js
terrainGeometry = new UeCircleGeometry(500);
terrain = new UeMesh(terrainGeometry, { z: 50 });
// The second argument is an optional struct of properties to apply to the mesh (such as position, rotation, material, etc.).
```

## 🧱 Available Geometry Primitives

**These are the built-in geometry types available:**

- UePlaneGeometry
- UeBoxGeometry
- UeCircleGeometry
- UeSphereGeometry
- UeParallelepipedGeometry
- UePyramidGeometry

You can instantiate them with relevant parameters (e.g., radius, width, height), and they automatically generate the vertex/index buffers needed for rendering.

## 🎨 Adding a Material

**You can assign a material to the mesh by including it in the creation properties:**

```js
var material = new UeMaterial({
  color: make_color_rgb(200, 200, 255),
  transparent: true
});

var sphere = new UeMesh(new UeSphereGeometry(1), {
  position: new UeVector3(0, 0, 0),
  material: material
});
```

✅ Note: You can still modify the mesh's transform, material, or geometry after creation if needed.

## 💾 Exporting and Importing Meshes (WORK IN PROGRESS)

Importing a model from a buffer is extremely fast, compared to load it with an OBJLoader or AssimpLoader.

Usually you will import all meshes from buffers that you will place in the "Included files" of your game, at the start of your game, or eg. before of a level, in order to reduce loading times.

**This is useful for:**

- Reduce load times when loading large external models (.obj, .3ds, etc..)
- Saving procedural geometries
- Caching expensive computations
- Sharing custom assets between scenes or sessions 

```js
buffer = myMesh.export();   // Serializes data
new Mesh().import(buffer);  // Loads mesh from buffer
```
📌 Tip: You can use buffer_save() and buffer_load() in combination to persist data between sessions.

The exported buffer will contain data about the geometry, mesh's children, local and world matrix, used material, etc..
