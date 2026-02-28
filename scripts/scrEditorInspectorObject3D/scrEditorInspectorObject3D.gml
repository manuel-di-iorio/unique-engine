function scrEditorInspectorObject3D() {
  return [
    // === PREVIEW ===
    inspectorField_preview(),

    // === SECTION: GENERAL ===
    inspectorField_name(),
    inspectorField_static(),

    // === SECTION: TRANSFORM ===
    inspectorSection_transform(),

    // === SECTION: GAMEMAKER INTEGRATION ===
    inspectorSection_gmIntegration(),

    // === SECTION: BOUNDING BOX ===
    inspectorSection_boundingBox(),

    // === SECTION: BOUNDING SPHERE ===
    inspectorSection_boundingSphere()
  ];
}
