function UiSprite(sprite, style = {}, props = {}): UiNode(style, props) constructor {
    self.sprite = sprite;
    self.hoverable = false;
    subimg = 0;
    setSize(sprite_get_width(sprite), sprite_get_height(sprite));
    
    function draw(x1, y1, x2, y2) {
        draw_sprite(sprite, subimg, ~~mean(x1, x2), ~~mean(y1, y2));
    }
}