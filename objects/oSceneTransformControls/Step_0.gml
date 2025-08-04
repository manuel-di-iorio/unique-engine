switch (tool) {
    case "view": 
        orbit.update(); 
        control.updateGizmo();
    break;
    case "move":
    case "rotate":
    case "scale":
        control.update();
    break;
}