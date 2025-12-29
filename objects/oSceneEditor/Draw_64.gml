if (!enableUI) exit;

if (sceneManager.transformControls.object != undefined) {
  sceneManager.transformControls.render();
}

draw_set_font(fText);
global.UI.render(uiDebug);

draw_set_font(fTextSmall);
draw_set_halign(fa_right); draw_set_valign(fa_top); draw_set_color(c_gray);
draw_text(winW - 15, 10, $"Version {global.UE_VERSION}");
