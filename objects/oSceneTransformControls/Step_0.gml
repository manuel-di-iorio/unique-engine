switch (tool) {
    case "view": orbit.update(); break;
    case "move": 
    case "rotate": 
    case "scale": 
        control.update();
    break;
}
