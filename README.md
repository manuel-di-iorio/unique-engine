# Unique Engine

Unique Engine is a modular and flexible 3D library, inspired by Three.js, designed to make it easy to create 3D games and interactive applications.
The goal is to offer a simple, accessible and powerful API, while maintaining a clear and easily extensible structure.

---

## Current Features ✅

- **Camera**
Manages 3D projection and automatically connects to the view.

- **Renderer**
Draws meshes with independent ordering of opaque and transparent materials. Manages passing light data to shaders.

- **Mesh**
Recursive rendering of children, updating matrices only if necessary. Rotations in degrees, with internal conversion to quaternions.

- **Lights**
Basic support for Ambient, Point and Directional lights via custom shaders.

- **Materials & Textures**
Automatic management of uniforms and samplers, including integration with lights.

- **VertexFormat**
Easy and flexible creation of vertex formats, e.g.:
`new VertexFormat().position().normal().uv().color().build()`

- **Geometry**
Separated from the mesh, with vertex buffer and index automatically created based on the format.

- **Math Utilities**
Vectors, matrices, quaternions, planes and raycasting: `Vec2`, `Vec3`, `Mat3`, `Mat4`, `Quaternion`, `Plane`, `Raycast`.

- **OrbitControls**
Addon for interactive drag, pan, rotate and zoom of the camera.

- **Import models (demo)**
Support via AssimpDLL by Jak (not included in the library for licensing reasons).

---

## In development features ⏳

- Import/export scene graph and single objects via buffer file
- Additional mesh primitives and new materials (billboards with rotation via vertex shader are already available)
- Bounding box and bounding sphere for simple collisions
- Multiple shader passes for advanced effects and post processing
- Animations
- Shadows, spot lights and other Three.js inspired features

---

## Basic example:

```gml
renderer = new UeRenderer();
scene = new UeScene();
camera = new UePerspectiveCamera();

cubeGeometry = new UeBoxGeometry({ color: c_blue });
cubeMesh = new UeMesh(cubeGeometry);

ambientLight = new UeAmbientLight();
dirLight = new UeDirectionalLight({ xt: -100, yt: -50, zt: -70 });

scene.add(cubeMesh, ambientLight, dirLight);
```

---

### Contribute

The project is open source and open to contributions!
Report bugs, feature requests or open a pull request on [GitHub](https://github.com/manuel-di-iorio/unique-engine/issues).

### License

[MIT License](LICENSE.md)

Other bundled software, such as Assimp and the [free 3d model](https://free3d.com/it/3d-model/airplane-v2--659376.html), are copyrighted by their respective creators and may come with additional usage restrictions.
These components are not required to use the engine — if you prefer to avoid any third-party licensing terms, simply remove the AssimpLoader and the included 3d model from the project's datafiles.

### Useful Links

- [Documentation](https://manuel-diiorio.github.io/unique-engine/docs)
- [Game Maker Official Website](https://gamemaker.io)
- [Game Maker Italia Community](https://gamemakeritalia.it)
