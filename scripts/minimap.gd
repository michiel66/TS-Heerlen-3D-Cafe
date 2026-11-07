extends Control
## Decoratieve kaart van het lokale café, niet van TeamSpeak-gebruikers.

var avatar: Node3D
const SCALE := 6.2

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var center := size * 0.5
    var radius := minf(size.x, size.y) * 0.48
    draw_circle(center, radius, Color(0.02, 0.03, 0.04, 0.90))
    draw_arc(center, radius, 0.0, TAU, 90, Color("cbb999"), 2.0)
    var a := center + Vector2(-11.6, -9.4) * SCALE
    var b := center + Vector2(11.6, 9.4) * SCALE
    draw_rect(Rect2(a, b - a), Color("725840"), false, 2.0)
    draw_rect(Rect2(center + Vector2(-11.0, -3.5) * SCALE, Vector2(8.0, 1.8) * SCALE), Color("cf9864"), true)
    draw_rect(Rect2(center + Vector2(-3.0, -9.0) * SCALE, Vector2(5.0, 5.0) * SCALE), Color("813fbc"), true)
    for p in [Vector2(4,-4),Vector2(8,-4),Vector2(5,0.7),Vector2(9,1.3),Vector2(4,5.2),Vector2(9,5.5)]:
        draw_circle(center + p * SCALE, 4.5, Color("ffdd8a"))
    if is_instance_valid(avatar):
        var point := center + Vector2(avatar.global_position.x, avatar.global_position.z) * SCALE
        draw_circle(point, 5.8, Color("38dfff"))
        draw_arc(point, 8.0, 0.0, TAU, 30, Color("ffffff"), 1.5)
