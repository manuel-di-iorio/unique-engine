/// @description Global service registry for the editor, decoupling scripts from oSceneEditor instance.
/// Access via global.editor.editorManager, global.editor.sceneManager, etc.
/// Follows the same singleton-global pattern used by global.UI for UniqueUI.

global.editor = {
    editorManager: undefined,
    sceneManager: undefined,
    assetManager: undefined,
    projectManager: undefined,
    selectionManager: undefined,
    events: undefined,
};

/// Registers all editor services into the global registry.
/// Called once from oSceneEditor Create_0 after all managers are instantiated.
function editorServices_register(editorManager, sceneManager, assetManager, projectManager, events) {
    global.editor.editorManager = editorManager;
    global.editor.sceneManager = sceneManager;
    global.editor.assetManager = assetManager;
    global.editor.projectManager = projectManager;
    global.editor.selectionManager = new EditorSelectionManager();
    global.editor.events = events;
}
