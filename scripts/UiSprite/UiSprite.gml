function UiSprite(sprite, style = {}, props = {}): UiNode(style, props) constructor {
    setName(style[$ "name"] ?? "UiSprite");
    self.sprite = sprite;
    self.subimg = 0;
    self.autoResize = props[$ "autoResize"] ?? (style[$ "width"] == undefined && style[$ "height"] == undefined) ?? true;
    
    if (self.autoResize) setSize(sprite_get_width(sprite), sprite_get_height(sprite));
    
    function onDraw() {
        draw_sprite(self.sprite, self.subimg, ~~mean(self.x1, self.x2), ~~mean(self.y1, self.y2));
    }
}