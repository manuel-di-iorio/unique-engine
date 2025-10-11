var ui = global.UI;

// Correctly resize the application surface to match the new window size
var winWNew = window_get_width();
var winHNew = window_get_height();
if ((winW != winWNew || winH != winHNew) && winWNew != 0 && winHNew != 0) {
    winW = winWNew;
    winH = winHNew;
    surface_resize(application_surface, winW, winH);
    ui.setSize(winW, winH).update();
    
    // Resize the views
    view_set_wport(0, winW);
    view_set_hport(0, winH);
    
    var uiScenePos = ui.Main.Scene.layout;
    // Container disponibile per la scena (dentro l'UI)
    var containerX = uiScenePos.left;
    var containerY = uiScenePos.top;
    var containerW = uiScenePos.width;
    var containerH = uiScenePos.height - uiScenePos.top - 1;

    // Manteniamo l'aspect ratio desiderato: 16:9
    // Modalità disponibile:
    //  - "fit": mantiene 16:9 all'interno del contenitore (letterbox/pillarbox)
    //  - "cover": mantiene 16:9 ma scala la view per coprire tutto il
    //             contenitore e ritaglia l'eccesso (equivalente a CSS cover)
    var aspectMode = "cover"; // cambia in "fit" per comportamento precedente
    var desiredAspect = 16/9;
    var viewW = containerW;
    var viewH = containerH;
    var viewX = containerX;
    var viewY = containerY;

    // Calcola letterbox / pillarbox per adattare la view al contenitore
    if (containerW > 0 && containerH > 0) {
        var containerAspect = containerW / containerH;
        // Prima calcoliamo le dimensioni della "fit view" (la più grande 16:9
        // che sta dentro il contenitore). La useremo sia per fit che per cover
        // per calcolare lo zoom necessario nella modalità cover.
        var fitViewW, fitViewH, fitViewX, fitViewY;
        if (containerAspect > desiredAspect) {
            // pillarbox
            fitViewH = containerH;
            fitViewW = fitViewH * desiredAspect;
            fitViewX = containerX + (containerW - fitViewW) / 2;
            fitViewY = containerY;
        } else {
            // letterbox
            fitViewW = containerW;
            fitViewH = fitViewW / desiredAspect;
            fitViewX = containerX;
            fitViewY = containerY + (containerH - fitViewH) / 2;
        }

        if (aspectMode == "fit") {
            if (containerAspect > desiredAspect) {
                // Container più largo del 16:9 -> barra ai lati (pillarbox)
                viewH = containerH;
                viewW = viewH * desiredAspect;
                viewX = containerX + (containerW - viewW) / 2;
                viewY = containerY;
            } else {
                // Container più alto del 16:9 -> barra sopra/sotto (letterbox)
                viewW = containerW;
                viewH = viewW / desiredAspect;
                viewX = containerX;
                viewY = containerY + (containerH - viewH) / 2;
            }
        } else {
            // cover: scala la view per coprire tutto il contenitore, mantenendo
            // aspect 16:9, poi ritaglia l'eccesso centrato
            // In cover Non spostiamo la viewport fuori dal container: manteniamo
            // la viewport pari al container e invece zoomiamo la camera (riducendo
            // il FOV) per ottenere l'effetto crop.
            viewW = containerW;
            viewH = containerH;
            viewX = containerX;
            viewY = containerY;
            
            // Calcola lo scale necessario per coprire il container rispetto alla
            // fitView (valore >= 1 quando serve ingrandire)
            var scaleX = (fitViewW > 0) ? (containerW / fitViewW) : 1;
            var scaleY = (fitViewH > 0) ? (containerH / fitViewH) : 1;
            var zoomScale = max(scaleX, scaleY);
        }
    }

    // Imposta la view (posizione e dimensione) con il risultato dell'adattamento
    view_set_xport(1, viewX);
    view_set_yport(1, viewY);
    view_set_wport(1, viewW);
    view_set_hport(1, viewH);

    // Aggiorna l'aspect della camera 3D e chiedi il ricalcolo della projection
    // (se l'oggetto camera espone updateProjectionMatrix) - usiamo l'aspect
    // corrispondente alla view effettiva usata per il rendering
    if (viewW > 0 && viewH > 0) {
        camera.aspect = viewW / viewH;
        camera.updateProjectionMatrix();
    }
}
ui.update();

// Wrap the mouse coords when out of bounds
var winMouseX = window_mouse_get_x();
var winMouseY = window_mouse_get_y();

if (mouse_button != mb_none && orbit.transforming) {
    var fixMousePos = false;

    if (winMouseX < 1) {
        winMouseX = winW - 2;
        fixMousePos = true;
    } else if (winMouseY < 1) {
        winMouseY = winH - 2;
        fixMousePos = true;
    } else if (winMouseX > winW - 2) {
        winMouseX = 2;
        fixMousePos = true;
    } else if (winMouseY > winH - 1) {
        winMouseY = 2;
        fixMousePos = true;
    }

    if (fixMousePos) {
        window_mouse_set(winMouseX, winMouseY); 
        
        orbit._prevMouseX = winMouseX;
        orbit._prevMouseY = winMouseY;
    }
}


// Update transform controls based on current tool
// orbit.update(winMouseX, winMouseY);
switch (tool) {
    case "view": 
        orbit.update(winMouseX, winMouseY);
        transformControls.updateGizmo();
    break;
    case "move":
    case "rotate":
    case "scale":
        transformControls.update();
    break;
}
