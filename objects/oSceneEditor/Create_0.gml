ideVersion = "2025.8.25.1";
uiDebug = false;

scrSetupUI();
scrSetup3D();

// Project
projectLocation = undefined;
projectFiles = undefined;
projectEdited = false;
projectTextures = [];
projectMaterials = [];
projectModels = [];
projectLights = [];
projectCameras = [];
projectScenes = [];

function countUI(node) {
    c = 1
    
    for (var i=0; i<array_length(node.children); i++) {
        c += countUI(node.children[i])
    }
    
    return c
}