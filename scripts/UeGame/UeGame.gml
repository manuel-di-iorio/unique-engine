// @doc @todo
// Handle the methods to manage your game, imported from UeBufferLoader
function UeGame() constructor {
    assets = {};
    scene = undefined;
    scenes = {};
    
    function get(name) {
        return assets[$ name];
    }
    
    function setScene(newScene) {
        scene = newScene;
        return self;
    }
}