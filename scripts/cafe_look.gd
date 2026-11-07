extends Node3D
## TeamSpeak Heerlen 3D Café – zichtbare uiterlijkfix v0.5.1
## Staat los van TeamSpeak, online gebruikers, microfoon en PTT.
## Gebruikt uitsluitend Godot 4.x-procedurele vormen en materialen.

const DARK := Color("171b22")
const PANEL := Color("20222a")
const AMBER := Color("ffae58")
const BRASS := Color("c58d4d")
const WARM_WHITE := Color("f6e3c9")

var glow_time := 0.0
var decorative_lights: Array[OmniLight3D] = []

func _ready() -> void:
    # Het hoofdscript maakt de caféwereld en HUD in zijn eigen _ready().
    # Met call_deferred komen wij er pas daarna aan.
    call_deferred("_install")

func _install() -> void:
    var game := get_parent()
    var cafe := game.get_node_or_null("CafeWorld") as Node3D
    var hud := game.get_node_or_null("CafeHUD") as CanvasLayer

    if cafe != null:
        _decorate_cafe(cafe)
        _make_entrance(cafe)
    else:
        push_warning("CafeLook v0.5.1: CafeWorld niet gevonden")
    if hud != null:
        _restyle_hud(hud)
        _add_version_banner(hud)
    else:
        push_warning("CafeLook v0.5.1: CafeHUD niet gevonden")

    print("HEERLEN LOOK v0.5.1 ACTIEF: entree, lichten en bediening geladen")

func _material(color: Color, metallic: float = 0.0, shine: float = 0.0) -> StandardMaterial3D:
    var result := StandardMaterial3D.new()
    result.albedo_color = color
    result.metallic = metallic
    result.roughness = 0.42 if metallic > 0.0 else 0.79
    if shine > 0.0:
        result.emission_enabled = true
        result.emission = color
        result.emission_energy_multiplier = shine
    return result

func _box(world: Node3D, position: Vector3, size: Vector3, mat: Material) -> void:
    var part := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.material_override = mat
    part.position = position
    world.add_child(part)

func _cylinder(world: Node3D, position: Vector3, radius: float, height: float, mat: Material) -> void:
    var part := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    part.mesh = mesh
    part.material_override = mat
    part.position = position
    world.add_child(part)

func _sphere(world: Node3D, position: Vector3, radius: float, mat: Material) -> void:
    var part := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = 2.0 * radius
    part.mesh = mesh
    part.material_override = mat
    part.position = position
    world.add_child(part)

func _sign(world: Node3D, message: String, position: Vector3, font_size: int, ink: Color) -> void:
    var label := Label3D.new()
    label.text = message
    label.font_size = font_size
    label.pixel_size = 0.007
    label.outline_size = 10
    label.modulate = ink
    label.position = position
    world.add_child(label)

func _warm_light(world: Node3D, pos: Vector3, strength: float, distance: float) -> void:
    var lamp := OmniLight3D.new()
    lamp.position = pos
    lamp.light_color = Color("ffbd80")
    lamp.light_energy = strength
    lamp.omni_range = distance
    lamp.shadow_enabled = false
    world.add_child(lamp)
    decorative_lights.append(lamp)

func _plant(world: Node3D, pos: Vector3, scale: float) -> void:
    var pot := _material(Color("4b342d"))
    var leaves := _material(Color("416649"))
    var highlights := _material(Color("64905e"))
    _cylinder(world, pos + Vector3(0, 0.25 * scale, 0), 0.32 * scale, 0.46 * scale, pot)
    _cylinder(world, pos + Vector3(0, 0.68 * scale, 0), 0.07 * scale, 0.62 * scale, leaves)
    for i in range(7):
        var angle := float(i) * TAU / 7.0
        var offset := Vector3(cos(angle), 0.0, sin(angle)) * 0.30 * scale
        _sphere(world, pos + Vector3(0, 1.09 * scale, 0) + offset, 0.22 * scale, leaves if i % 2 == 0 else highlights)
    _sphere(world, pos + Vector3(0, 1.34 * scale, 0), 0.30 * scale, highlights)

func _decorate_cafe(world: Node3D) -> void:
    var brass := _material(BRASS, 0.65)
    var wood := _material(Color("573628"))
    var velvet := _material(Color("542c37"))
    var gold_light := _material(AMBER, 0.0, 2.1)
    var blue_light := _material(Color("48a8ff"), 0.0, 2.5)
    var cream := _material(Color("e5cba2"))

    # Warme lichtlijnen langs de voorkant van de koffiebar.
    _box(world, Vector3(-7.45, 1.17, -1.84), Vector3(7.9, 0.045, 0.045), gold_light)
    _box(world, Vector3(-7.45, 0.16, -1.84), Vector3(7.9, 0.035, 0.035), brass)
    _sign(world, "☕  HEERLEN  •  KOFFIEBAR", Vector3(-7.3, 0.80, -1.835), 31, WARM_WHITE)

    # Extra warme details bij de trap-/barstools.
    for x in [-10.4, -9.1, -7.8, -6.5, -5.2, -3.9]:
        _cylinder(world, Vector3(x, 0.84, -0.95), 0.295, 0.025, velvet)
        _cylinder(world, Vector3(x, 0.89, -0.95), 0.12, 0.012, brass)

    # Decoratief looppad vanuit de ingang richting bar.
    _box(world, Vector3(0.0, 0.003, 4.35), Vector3(1.55, 0.014, 7.4), wood)
    _box(world, Vector3(-0.80, 0.014, 4.35), Vector3(0.028, 0.016, 7.4), brass)
    _box(world, Vector3(0.80, 0.014, 4.35), Vector3(0.028, 0.016, 7.4), brass)

    # Tegenlicht achter het bestaande TeamSpeak Heerlen-bord.
    _box(world, Vector3(5.15, 4.28, -9.59), Vector3(6.0, 0.042, 0.035), blue_light)
    _box(world, Vector3(5.15, 1.93, -9.59), Vector3(6.0, 0.042, 0.035), gold_light)
    _sign(world, "LIVE VOICE  •  TEAMSPEAK", Vector3(5.15, 1.73, -9.55), 23, WARM_WHITE)
    _warm_light(world, Vector3(5.15, 3.25, -8.6), 0.68, 4.0)

    # Twee extra hanglampen bij de zithoek, met metalen frame.
    for x in [4.1, 8.3]:
        _cylinder(world, Vector3(x, 4.32, 4.6), 0.012, 0.55, brass)
        _cylinder(world, Vector3(x, 4.01, 4.6), 0.46, 0.16, wood)
        _cylinder(world, Vector3(x, 3.89, 4.6), 0.25, 0.07, gold_light)
        _warm_light(world, Vector3(x, 3.83, 4.6), 0.75, 4.0)

    # Decoratieve raamlichtstroken; geen wijzigingen aan botsingen.
    for z in [-6.5, -1.5, 3.5, 7.8]:
        _box(world, Vector3(11.70, 3.98, z), Vector3(0.06, 0.04, 2.26), brass)

    # Kamerplanten op plekken buiten de hoofdlooppaden.
    _plant(world, Vector3(-10.85, 0.0, 8.65), 0.72)
    _plant(world, Vector3(10.72, 0.0, 8.65), 0.74)
    _plant(world, Vector3(-10.85, 0.0, -7.2), 0.64)

    # Randverlichting langs de dansvloer.
    _box(world, Vector3(-0.6, 0.10, -9.53), Vector3(4.75, 0.045, 0.045), blue_light)
    _box(world, Vector3(-2.98, 0.10, -7.2), Vector3(0.045, 0.045, 4.5), gold_light)
    _box(world, Vector3(1.78, 0.10, -7.2), Vector3(0.045, 0.045, 4.5), blue_light)

    # Borden boven de radiohoek.
    _sign(world, "27MC  •  ON AIR", Vector3(8.92, 3.55, -9.65), 24, AMBER)
    _cylinder(world, Vector3(9.65, 1.18, -8.4), 0.10, 0.12, brass)
    _cylinder(world, Vector3(9.95, 1.18, -8.4), 0.10, 0.12, brass)
    _cylinder(world, Vector3(10.25, 1.18, -8.4), 0.10, 0.12, brass)

func _style_box(fill: Color, edge: Color, radius: int = 12, border: int = 1) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = edge
    s.border_width_left = border
    s.border_width_right = border
    s.border_width_top = border
    s.border_width_bottom = border
    s.corner_radius_top_left = radius
    s.corner_radius_top_right = radius
    s.corner_radius_bottom_left = radius
    s.corner_radius_bottom_right = radius
    s.content_margin_left = 11
    s.content_margin_right = 11
    s.content_margin_top = 7
    s.content_margin_bottom = 7
    return s

func _restyle_hud(hud: CanvasLayer) -> void:
    _style_controls(hud)

func _style_controls(node: Node) -> void:
    if node is PanelContainer:
        var panel := node as PanelContainer
        var is_minimap := panel.anchor_left == 1.0 and panel.anchor_right == 1.0
        var style := _style_box(Color(0.070, 0.075, 0.091, 0.93), Color("765843"), 100 if is_minimap else 15)
        style.shadow_color = Color(0.0, 0.0, 0.0, 0.25)
        style.shadow_size = 9
        panel.add_theme_stylebox_override("panel", style)
    elif node is Button:
        var button := node as Button
        button.add_theme_stylebox_override("normal", _style_box(PANEL, Color("624936"), 10))
        button.add_theme_stylebox_override("hover", _style_box(Color("3a302d"), AMBER, 10, 2))
        button.add_theme_stylebox_override("pressed", _style_box(Color("533924"), AMBER, 10, 2))
        button.add_theme_stylebox_override("disabled", _style_box(DARK, Color("35343a"), 10))
        button.add_theme_color_override("font_color", WARM_WHITE)
        button.add_theme_color_override("font_hover_color", AMBER)
        button.add_theme_color_override("font_pressed_color", Color("fff1d3"))
    elif node is LineEdit:
        var entry := node as LineEdit
        entry.add_theme_stylebox_override("normal", _style_box(Color("181b21"), Color("8c6945"), 9))
        entry.add_theme_stylebox_override("focus", _style_box(Color("222125"), AMBER, 9, 2))
        entry.add_theme_color_override("font_color", WARM_WHITE)
        entry.add_theme_color_override("font_placeholder_color", Color("9e978f"))

    for child in node.get_children():
        _style_controls(child)


# Duidelijk zichtbare ingang - alleen decoratie, geen botsingen en geen audio.
func _make_entrance(world: Node3D) -> void:
    var gold := _material(Color("ffb85e"), 0.24, 2.1)
    var teal := _material(Color("45dbe4"), 0.15, 2.4)
    var dark := _material(Color("232a31"), 0.10)
    var carpet := _material(Color("4a292b"))

    # Brede loper in het zicht vanaf de startcamera.
    _box(world, Vector3(2.3, 0.018, 4.8), Vector3(3.25, 0.04, 6.5), carpet)
    _box(world, Vector3(0.62, 0.043, 4.8), Vector3(0.07, 0.02, 6.5), gold)
    _box(world, Vector3(3.98, 0.043, 4.8), Vector3(0.07, 0.02, 6.5), gold)

    # Ingangsportaal met warme en blauwe neonstrips.
    _box(world, Vector3(0.52, 1.56, 2.9), Vector3(0.16, 3.12, 0.16), dark)
    _box(world, Vector3(4.08, 1.56, 2.9), Vector3(0.16, 3.12, 0.16), dark)
    _box(world, Vector3(0.52, 1.58, 3.03), Vector3(0.055, 3.00, 0.045), gold)
    _box(world, Vector3(4.08, 1.58, 3.03), Vector3(0.055, 3.00, 0.045), teal)
    _box(world, Vector3(2.3, 3.08, 2.9), Vector3(3.68, 0.36, 0.18), dark)
    _box(world, Vector3(2.3, 3.22, 3.04), Vector3(3.55, 0.055, 0.07), gold)
    _sign(world, "WELKOM IN HEERLEN", Vector3(2.3, 2.94, 3.06), 34, Color("fff1d2"))

    # Lichtpalen bij de ingang, zichtbaar terwijl je rondloopt.
    _warm_light(world, Vector3(0.55, 2.52, 3.1), 1.30, 5.4)
    var cyan_lamp := OmniLight3D.new()
    cyan_lamp.position = Vector3(4.04, 2.45, 3.05)
    cyan_lamp.light_color = Color("4fddfa")
    cyan_lamp.light_energy = 0.95
    cyan_lamp.omni_range = 5.2
    cyan_lamp.shadow_enabled = false
    world.add_child(cyan_lamp)

    # Extra forse, van dichtbij goed zichtbare bartafelpanelen.
    _box(world, Vector3(-7.35, 0.65, -1.837), Vector3(7.7, 0.14, 0.08), gold)
    _box(world, Vector3(-7.35, 0.43, -1.785), Vector3(7.7, 0.035, 0.035), teal)


# Altijd zichtbaar. Hiermee kun je controleren of deze build echt geladen is.
func _add_version_banner(hud: CanvasLayer) -> void:
    if hud.get_node_or_null("LookVersionBanner") != null:
        return
    var plaque := PanelContainer.new()
    plaque.name = "LookVersionBanner"
    plaque.anchor_left = 0.5
    plaque.anchor_right = 0.5
    plaque.offset_left = -225.0
    plaque.offset_right = 225.0
    plaque.offset_top = 14.0
    plaque.offset_bottom = 62.0
    plaque.mouse_filter = Control.MOUSE_FILTER_IGNORE
    plaque.add_theme_stylebox_override(
        "panel", _style_box(Color("171b22"), Color("ffb85e"), 12, 2)
    )

    var caption := Label.new()
    caption.text = "TEAMSpeak HEERLEN  |  LOOK v0.5.1"
    caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
    caption.add_theme_font_size_override("font_size", 18)
    caption.add_theme_color_override("font_color", Color("fff0d6"))
    plaque.add_child(caption)
    hud.add_child(plaque)
