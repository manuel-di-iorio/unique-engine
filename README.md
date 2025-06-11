# Unique Engine

Unique Engine è una libreria 3D modulare e flessibile, ispirata a Three.js, progettata per facilitare la creazione di giochi 3D e applicazioni interattive.  
L'obiettivo è offrire un'API semplice, accessibile e potente, mantenendo una struttura chiara e facilmente estendibile.

---

## Caratteristiche attuali ✅

- **Camera**  
  Gestisce la proiezione 3D e si collega automaticamente alla view.

- **Renderer**  
  Disegna le mesh con ordinamento indipendente di materiali opachi e trasparenti. Gestisce passaggio dati luci agli shader.

- **Mesh**  
  Rendering ricorsivo dei figli, aggiornamento matrici solo se necessario. Rotazioni in gradi, con conversione interna a quaternioni.

- **Luci**  
  Supporto base per Ambient, Point e Directional light tramite shader personalizzati.

- **Materials & Textures**  
  Gestione automatica di uniform e sampler, inclusa l’integrazione con le luci.

- **VertexFormat**  
  Creazione semplice e flessibile dei formati di vertice, es.:  
  `new VertexFormat().position().normal().uv().color().build()`

- **Geometria**  
  Separata dalla mesh, con buffer vertex e indice creati automaticamente in base al formato.

- **Math Utilities**  
  Vettori, matrici, quaternioni, piani e raycasting: `Vec2`, `Vec3`, `Mat3`, `Mat4`, `Quaternion`, `Plane`, `Raycast`.

- **OrbitControls**  
  Addon per gestione interattiva di drag, pan, rotazione e zoom della camera.

- **Import modelli (demo)**  
  Supporto tramite AssimpDLL di Jak (non incluso nella libreria per motivi di licenza).

---

## Funzionalità in sviluppo ⏳

- Import/export scene graph e singoli oggetti via buffer file
- Primitive mesh aggiuntive e nuovi materiali (già disponibili billboards con rotazione via vertex shader)
- Bounding box e bounding sphere per collisioni semplici
- Shader pass multipli per effetti avanzati e post processing
- Animazioni
- Ombre, spot lights e altre features ispirate a Three.js

---

## Esempio base:

```gml
// Setup the scene and the perspective camera
renderer = new Renderer();
scene = new Scene();
camera = new PerspectiveCamera({ x: 150, y: 50, z: 50, xt: 10, yt: 0, zt: 30 });

// Create the terrain
terrain = new CircleMesh({ z: -100, radius: 500 });

// Example tree within a mesh container
tree = new Mesh();
treeShadow = new CircleMesh({ z: -24, radius: 25, color: c_gray });
treeTrunk = new ParallelepipedMesh({ rx: 90, color: c_maroon });
treeTop = new SphereMesh({ radius: 40, z: 55, color: #11aa11 });
tree.add(treeShadow, treeTrunk, treeTop);

// Basic lights
ambientLight = new AmbientLight({ color: #226622 });
pointLight = new PointLight({ x: 40, y: 40, z: 50 });

scene.add(ambientLight, pointLight, terrain, tree);
```

---

### Contribuire

Il progetto è open source e aperto a contributi!
Segnala bug, richieste di funzionalità o apri una pull request su [GitHub](https://github.com/manuel-di-iorio/unique-engine/issues).

### License

[MIT License](LICENSE.md)

Other bundled software, such as Assimp and the [free 3d model](https://free3d.com/it/3d-model/airplane-v2--659376.html), are copyrighted by their respective creators and may come with additional usage restrictions.
These components are not required to use the engine — if you prefer to avoid any third-party licensing terms, simply remove the AssimpLoader and the included 3d model from the project’s datafiles.

### Link utili

- [Documentazione](https://manuel-diiorio.github.io/unique-engine/docs)
- [Game Maker Official Website](https://gamemaker.io)
- [Game Maker Italia Community](https://gamemakeritalia.it)
