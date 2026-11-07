extends Node3D
## TeamSpeak Heerlen 3D Café – LOOK v0.6
## UITSLUITEND DE VORMGEVING. Geen TeamSpeak-, audio-, PTT- of avatar-code.
## Ontworpen voor de bestaande CafeWorld + CafeHUD onder res://scenes/main.tscn.

const OAK_TEX := preload("res://assets/textures/v06_oak_floor.png")
const WALNUT_TEX := preload("res://assets/textures/v06_walnut.png")
const BRICK_TEX := preload("res://assets/textures/v06_brick.png")
const STONE_TEX := preload("res://assets/textures/v06_stone_counter.png")
const SEAT_TEX := preload("res://assets/textures/v06_upholstery.png")
const PLASTER_TEX := preload("res://assets/textures/v06_plaster.png")
const RUG_TEX := preload("res://assets/textures/v06_rug.png")
const MENU_TEX := preload("res://assets/textures/v06_coffee_menu.png")
const SIGN_TEX := preload("res://assets/textures/v06_wall_sign.png")

const AMBER := Color("ffc078")
const CREAM := Color("f6e7d4")
const BRASS := Color("bc8950")
const DARK := Color("161b20")
const TEAL := Color("5ac8bc")
const SOFT_BLUE := Color("64a9f5")

var decorative_lights: Array[OmniLight3D] = []
var light_time: float = 0.0

func _ready() -> void:
    # Hoofdscript maakt CafeWorld / CafeHUD in eigen _ready(); deferred is essentieel.
    call_deferred("_install")

func _install() -> void:
    var game := get_parent()
    var world := game.get_node_or_null("CafeWorld") as Node3D
    var hud := game.get_node_or_null("CafeHUD") as CanvasLayer
    if world == null:
        push_warning("LOOK v0.6: CafeWorld nog niet gevonden; bestaande cafe blijft werken")
        return

    _retexture_existing_world(world)
    _architectural_finishes(world)
    _coffee_bar(world)
    _wall_art(world)
    _tables_and_lounge(world)
    _plants_and_ambience(world)
    _dancefloor_and_radio(world)

    if hud != null:
        _reskin_hud(hud)
        _version_badge(hud)

    print("HEERLEN LOOK v0.6 ACTIEF: PBR-structuren, koffiebar, lounge, neon, interface")

func _process(delta: float) -> void:
    light_time += delta
    # Subtiele lichtvariatie, geen belasting voor TeamSpeak of voice.
    for i in range(decorative_lights.size()):
        var lamp := decorative_lights[i]
        if is_instance_valid(lamp):
            lamp.light_energy = 0.68 + sin(light_time * 0.45 + float(i) * 1.7) * 0.035

func _texture_material(texture: Texture2D, rough: float = 0.72, uv: Vector3 = Vector3.ONE) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = texture
    mat.uv1_scale = uv
    mat.roughness = rough
    return mat

func _plain(color: Color, rough: float = 0.60, metal: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = rough
    mat.metallic = metal
    return mat

func _glow(color: Color, power: float = 1.6) -> StandardMaterial3D:
    var mat := _plain(color, 0.2)
    mat.emission_enabled = true
    mat.emission = color
    mat.emission_energy_multiplier = power
    return mat

func _retune(world: Node3D, prop: String, texture: Texture2D, tint: Color, rough: float, repeat: Vector3) -> void:
    var raw: Variant = world.get(prop)
    if raw is StandardMaterial3D:
        var material := raw as StandardMaterial3D
        material.albedo_color = tint
        material.albedo_texture = texture
        material.uv1_scale = repeat
        material.roughness = rough

func _retexture_existing_world(world: Node3D) -> void:
    # Alle bestaande 3D-meubels blijven staan; alleen hun gedeelde materialen veranderen.
    _retune(world, "wood_floor", OAK_TEX, Color("fff4e8"), 0.76, Vector3(3.3, 3.3, 1.0))
    _retune(world, "dark_brick", BRICK_TEX, Color("e6d9ce"), 0.86, Vector3(2.0, 1.5, 1.0))
    _retune(world, "furniture", WALNUT_TEX, Color("f8e5cf"), 0.61, Vector3(1.0, 1.0, 1.0))
    _retune(world, "counter_top", STONE_TEX, Color("ffffff"), 0.28, Vector3(2.2, 1.0, 1.0))
    _retune(world, "seat_red", SEAT_TEX, Color("ffede5"), 0.86, Vector3(1.0, 1.0, 1.0))
    _retune(world, "warm_cream", PLASTER_TEX, Color("e2c5a5"), 0.91, Vector3(1.6, 1.0, 1.0))

    var leaf_mat: Variant = world.get("leaf")
    if leaf_mat is StandardMaterial3D:
        (leaf_mat as StandardMaterial3D).albedo_color = Color("3d6a4e")
    var glass_mat: Variant = world.get("glass")
    if glass_mat is StandardMaterial3D:
        (glass_mat as StandardMaterial3D).albedo_color = Color("a9d0d8")
        (glass_mat as StandardMaterial3D).roughness = 0.18

func _box(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var mesh := BoxMesh.new()
    mesh.size = size
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.material_override = material
    node.position = pos
    parent.add_child(node)
    return node

func _cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    mesh.radial_segments = 24
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.material_override = material
    node.position = pos
    parent.add_child(node)
    return node

func _sphere(parent: Node3D, pos: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 0.5
    mesh.height = 1.0
    mesh.radial_segments = 16
    mesh.rings = 8
    var node := MeshInstance3D.new()
    node.mesh = mesh
    node.material_override = material
    node.position = pos
    node.scale = size
    parent.add_child(node)
    return node

func _poster(parent: Node3D, pos: Vector3, size: Vector2, texture: Texture2D) -> void:
    var plane := QuadMesh.new()
    plane.size = size
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = texture
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    mat.cull_mode = BaseMaterial3D.CULL_DISABLED
    var node := MeshInstance3D.new()
    node.mesh = plane
    node.material_override = mat
    node.position = pos
    parent.add_child(node)

func _label(parent: Node3D, words: String, pos: Vector3, size: int, color: Color) -> void:
    var node := Label3D.new()
    node.text = words
    node.font_size = size
    node.pixel_size = 0.006
    node.outline_size = 10
    node.modulate = color
    node.position = pos
    parent.add_child(node)

func _local_light(parent: Node3D, pos: Vector3, color: Color, strength: float, radius: float) -> void:
    var node := OmniLight3D.new()
    node.light_color = color
    node.light_energy = strength
    node.omni_range = radius
    node.position = pos
    node.shadow_enabled = false
    parent.add_child(node)
    decorative_lights.append(node)

func _architectural_finishes(world: Node3D) -> void:
    var walnut := _texture_material(WALNUT_TEX, 0.55)
    var brass := _plain(BRASS, 0.35, 0.65)
    var dark_metal := _plain(Color("292e31"), 0.50, 0.45)
    var stone := _texture_material(STONE_TEX, 0.38)
    var carpet := _texture_material(RUG_TEX, 0.9, Vector3(1.0, 1.3, 1.0))
    var warm := _glow(Color("ffa65f"), 2.0)

    # Hoofdroute in het café: duidelijk en warm vanaf de ingang.
    _box(world, Vector3(0.15, 0.018, 5.00), Vector3(2.6, 0.022, 7.75), carpet)
    _box(world, Vector3(-1.18, 0.032, 5.0), Vector3(0.045, 0.018, 7.75), brass)
    _box(world, Vector3(1.48, 0.032, 5.0), Vector3(0.045, 0.018, 7.75), brass)

    # Diepe donkere houten plafondbalken geven de ruimte karakter.
    for x in [-10.5, -7.2, -3.9, -0.6, 2.7, 6.0, 9.3]:
        _box(world, Vector3(x, 4.61, 0.0), Vector3(0.14, 0.18, 18.8), walnut)
        _box(world, Vector3(x, 4.48, -9.0), Vector3(0.04, 0.03, 0.7), brass)
    for z in [-7.0, -2.0, 3.0, 8.0]:
        _box(world, Vector3(0.0, 4.58, z), Vector3(22.8, 0.10, 0.16), dark_metal)

    # Wandsierlijsten met warme ingebouwde verlichting.
    for z in [-8.3, -2.8, 2.7, 8.2]:
        _box(world, Vector3(-11.79, 1.18, z), Vector3(0.065, 2.2, 0.16), walnut)
        _box(world, Vector3(-11.73, 2.44, z), Vector3(0.035, 0.055, 0.20), brass)
    _box(world, Vector3(-11.73, 3.85, 0.0), Vector3(0.055, 0.07, 18.2), warm)

    # Steenplinten achter de koffiebar en bij de zithoek.
    _box(world, Vector3(-7.4, 0.17, -9.74), Vector3(8.9, 0.28, 0.07), stone)
    _box(world, Vector3(5.2, 0.17, -9.74), Vector3(8.5, 0.28, 0.07), stone)

func _coffee_bar(world: Node3D) -> void:
    var brass := _plain(Color("b89158"), 0.32, 0.72)
    var wood := _texture_material(WALNUT_TEX, 0.52)
    var stone := _texture_material(STONE_TEX, 0.23)
    var ceramic := _plain(Color("e8d9c8"), 0.27)
    var mocha := _plain(Color("50372d"), 0.84)
    var light := _glow(Color("ffb86e"), 2.8)
    var dark := _plain(Color("1c2326"), 0.45, 0.22)

    # Een massieve stenen toplaag en glanzende sierlijst over de bestaande bar.
    _box(world, Vector3(-7.45, 1.33, -2.65), Vector3(8.45, 0.085, 1.93), stone)
    _box(world, Vector3(-7.45, 1.26, -1.69), Vector3(8.40, 0.030, 0.040), brass)
    _box(world, Vector3(-7.45, 1.11, -1.835), Vector3(8.10, 0.043, 0.043), light)
    for x in [-10.8, -9.35, -7.9, -6.45, -5.0, -3.55]:
        _box(world, Vector3(x, 0.69, -1.83), Vector3(0.046, 0.87, 0.043), brass)
    _label(world, "HEERLEN  COFFEE  &  LOUNGE", Vector3(-7.35, 0.66, -1.78), 30, CREAM)

    # Barista-station: espresso, koppen, potjes en warme achtergrondstroken.
    _box(world, Vector3(-8.5, 1.85, -2.6), Vector3(1.05, 0.66, 0.60), dark)
    _box(world, Vector3(-8.5, 2.10, -2.29), Vector3(0.78, 0.055, 0.055), brass)
    for x in [-8.8, -8.5, -8.2]:
        _cylinder(world, Vector3(x, 2.17, -2.35), 0.10, 0.07, light)
    for x in [-6.1, -5.65, -5.2, -4.75]:
        _cylinder(world, Vector3(x, 1.46, -2.5), 0.12, 0.18, ceramic)
        _cylinder(world, Vector3(x, 1.57, -2.5), 0.115, 0.025, mocha)
    for x in [-3.7, -3.35, -3.0]:
        _cylinder(world, Vector3(x, 1.48, -2.5), 0.13, 0.24, mocha)
        _cylinder(world, Vector3(x, 1.61, -2.5), 0.135, 0.035, brass)

    # Hanglampen: duidelijke amberkleurige kappen boven de hele bar.
    for x in [-9.4, -7.4, -5.4, -3.4]:
        _cylinder(world, Vector3(x, 4.33, -0.6), 0.014, 0.75, dark)
        _cylinder(world, Vector3(x, 3.92, -0.6), 0.44, 0.20, wood)
        _cylinder(world, Vector3(x, 3.78, -0.6), 0.23, 0.060, light)
    _local_light(world, Vector3(-7.2, 3.55, -0.65), Color("ffbb7e"), 0.68, 5.5)

    # Een grote koffie-menukaart achter de bar in een bronzen lijst.
    _box(world, Vector3(-7.6, 2.77, -9.34), Vector3(6.8, 3.40, 0.07), wood)
    _box(world, Vector3(-7.6, 2.77, -9.27), Vector3(6.60, 3.18, 0.05), brass)
    _poster(world, Vector3(-7.6, 2.77, -9.232), Vector2(6.46, 3.03), MENU_TEX)
    _box(world, Vector3(-7.6, 1.03, -9.23), Vector3(6.6, 0.04, 0.06), light)

func _wall_art(world: Node3D) -> void:
    var wood := _texture_material(WALNUT_TEX, 0.55)
    var brass := _plain(BRASS, 0.34, 0.68)
    var teal_glow := _glow(TEAL, 2.8)
    var amber_glow := _glow(AMBER, 2.8)

    # Groot herkenbaar centraal TeamSpeak Heerlen-bord. Vanuit de entree zichtbaar.
    _box(world, Vector3(5.25, 2.89, -9.37), Vector3(9.2, 3.8, 0.10), wood)
    _box(world, Vector3(5.25, 2.89, -9.29), Vector3(8.98, 3.6, 0.065), brass)
    _poster(world, Vector3(5.25, 2.89, -9.245), Vector2(8.77, 3.40), SIGN_TEX)
    _box(world, Vector3(5.25, 4.76, -9.20), Vector3(9.05, 0.055, 0.055), amber_glow)
    _box(world, Vector3(5.25, 1.03, -9.20), Vector3(9.05, 0.045, 0.055), teal_glow)
    _local_light(world, Vector3(4.7, 3.4, -7.6), Color("ffa465"), 0.68, 5.5)

    # Kleine wandschilderijtjes bij de zithoek.
    for z in [-6.8, -3.4, 0.0, 3.4, 6.8]:
        _box(world, Vector3(11.70, 2.95, z), Vector3(0.075, 1.26, 1.66), wood)
        _box(world, Vector3(11.65, 2.95, z), Vector3(0.075, 1.05, 1.43), brass)

func _cup(world: Node3D, pos: Vector3) -> void:
    var china := _plain(Color("e1d8c8"), 0.22)
    var foam := _plain(Color("ad7c55"), 0.82)
    var brass := _plain(Color("aa8057"), 0.36, 0.4)
    _cylinder(world, pos + Vector3(0, 0.02, 0), 0.18, 0.03, brass)
    _cylinder(world, pos + Vector3(0, 0.135, 0), 0.13, 0.19, china)
    _cylinder(world, pos + Vector3(0, 0.234, 0), 0.12, 0.012, foam)
    _sphere(world, pos + Vector3(0.155, 0.14, 0), Vector3(0.12, 0.055, 0.12), china)

func _tables_and_lounge(world: Node3D) -> void:
    var wood := _texture_material(WALNUT_TEX, 0.62)
    var brass := _plain(BRASS, 0.35, 0.65)
    var velvet := _texture_material(SEAT_TEX, 0.86)
    var rug := _texture_material(RUG_TEX, 0.95)
    var ceramic := _plain(Color("c8b3a0"), 0.64)

    # Zes bestaande cafétafels worden visueel opgewaardeerd met afgeronde
    # houten schijven, bronzen stootrand en koffie op tafel.
    var centers := [
        Vector3(3.9, 0, -4.3), Vector3(8.1, 0, -4.0),
        Vector3(4.9, 0, 0.7), Vector3(9.0, 0, 1.3),
        Vector3(4.1, 0, 5.2), Vector3(9.1, 0, 5.5)
    ]
    for p in centers:
        _cylinder(world, p + Vector3(0, 0.855, 0), 0.85, 0.065, wood)
        _cylinder(world, p + Vector3(0, 0.815, 0), 0.87, 0.015, brass)
        _cup(world, p + Vector3(0.28, 0.88, 0.10))
        _cylinder(world, p + Vector3(-0.36, 0.93, -0.13), 0.12, 0.03, ceramic)

    # Zitkussens op de zes tafelschikkingstoelen.
    for p in centers:
        for dx in [-1.25, 1.25]:
            _box(world, p + Vector3(dx, 0.56, 0), Vector3(0.58, 0.11, 0.53), velvet)
            _box(world, p + Vector3(dx, 0.615, -0.245), Vector3(0.48, 0.024, 0.07), brass)

    # Loper en stijlvolle bankkussens in de loungehoek.
    _box(world, Vector3(8.85, 0.022, -0.5), Vector3(3.2, 0.020, 4.15), rug)
    for z in [-2.85, -1.95, -1.05, -0.15, 0.75]:
        _box(world, Vector3(10.66, 0.83, z), Vector3(1.06, 0.18, 0.78), velvet)
        _box(world, Vector3(11.23, 1.17, z), Vector3(0.17, 0.72, 0.74), velvet)
        _box(world, Vector3(10.1, 0.67, z), Vector3(0.05, 0.26, 0.67), brass)

func _tall_plant(world: Node3D, pos: Vector3, size: float) -> void:
    var dark_pot := _plain(Color("51413a"), 0.76)
    var lip := _plain(BRASS, 0.35, 0.55)
    var branch := _plain(Color("594633"), 0.9)
    var leaf1 := _plain(Color("436e4b"), 0.82)
    var leaf2 := _plain(Color("71956c"), 0.84)
    _cylinder(world, pos + Vector3(0, 0.29 * size, 0), 0.34 * size, 0.56 * size, dark_pot)
    _cylinder(world, pos + Vector3(0, 0.56 * size, 0), 0.35 * size, 0.065 * size, lip)
    _cylinder(world, pos + Vector3(0, 1.12 * size, 0), 0.07 * size, 1.3 * size, branch)
    for i in range(12):
        var a: float = float(i) * TAU / 12.0
        var direction := Vector3(cos(a), 0, sin(a))
        var y: float = (0.98 + float(i % 4) * 0.24) * size
        var place := pos + direction * (0.38 + 0.07 * float(i % 3)) * size + Vector3(0, y, 0)
        var leaf := _sphere(world, place, Vector3(0.37, 0.17, 0.64) * size, leaf1 if i % 2 == 0 else leaf2)
        leaf.rotation.y = -a
    _sphere(world, pos + Vector3(0, 1.85 * size, 0), Vector3(0.4, 0.32, 0.4) * size, leaf2)

func _plants_and_ambience(world: Node3D) -> void:
    _tall_plant(world, Vector3(-10.6, 0, 7.8), 0.82)
    _tall_plant(world, Vector3(10.4, 0, 8.5), 0.9)
    _tall_plant(world, Vector3(-2.95, 0, 8.6), 0.80)
    _tall_plant(world, Vector3(10.5, 0, -5.5), 0.72)

    var shade := _texture_material(WALNUT_TEX, 0.66)
    var brass := _plain(BRASS, 0.37, 0.50)
    var glow := _glow(Color("ffc68b"), 2.4)

    # Industriële hanglampen met echte warme uitstraling.
    for x in [4.1, 8.7]:
        for z in [3.2, -3.6]:
            _cylinder(world, Vector3(x, 4.21, z), 0.011, 0.75, brass)
            _cylinder(world, Vector3(x, 3.79, z), 0.48, 0.20, shade)
            _cylinder(world, Vector3(x, 3.65, z), 0.26, 0.06, glow)
    _local_light(world, Vector3(6.5, 3.50, 2.8), Color("ffcf99"), 0.68, 5.6)

func _dancefloor_and_radio(world: Node3D) -> void:
    var amber := _glow(AMBER, 3.2)
    var blue := _glow(SOFT_BLUE, 3.2)
    var teal := _glow(TEAL, 3.2)
    var walnut := _texture_material(WALNUT_TEX, 0.5)
    var brass := _plain(BRASS, 0.32, 0.65)
    _box(world, Vector3(-0.6, 0.125, -9.50), Vector3(4.9, 0.045, 0.055), blue)
    _box(world, Vector3(-3.0, 0.125, -7.1), Vector3(0.045, 0.045, 4.7), amber)
    _box(world, Vector3(1.80, 0.125, -7.1), Vector3(0.045, 0.045, 4.7), teal)
    _box(world, Vector3(-0.6, 3.90, -4.65), Vector3(4.7, 0.05, 0.05), amber)
    _label(world, "DANS  •  MUSIC  •  LIVE", Vector3(-0.6, 3.43, -4.60), 28, CREAM)

    # De bestaande radiohoek blijft bereikbaar.
    _box(world, Vector3(9.72, 1.19, -8.35), Vector3(1.4, 0.055, 0.72), walnut)
    _box(world, Vector3(9.72, 1.25, -8.34), Vector3(1.3, 0.025, 0.65), brass)
    for x in [9.39, 9.72, 10.05]:
        _cylinder(world, Vector3(x, 1.28, -8.08), 0.085, 0.09, amber)
    _label(world, "27MC  |  ON AIR", Vector3(9.62, 3.85, -9.60), 28, AMBER)

func _stylebox(fill: Color, stroke: Color, radius: int = 13, line: int = 1) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = stroke
    style.border_width_top = line
    style.border_width_bottom = line
    style.border_width_left = line
    style.border_width_right = line
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.content_margin_left = 11
    style.content_margin_right = 11
    style.content_margin_top = 8
    style.content_margin_bottom = 8
    return style

func _reskin_hud(hud: CanvasLayer) -> void:
    _style_recursive(hud)

func _style_recursive(node: Node) -> void:
    if node is PanelContainer:
        var panel := node as PanelContainer
        var is_circle: bool = panel.anchor_left == 1.0 and panel.anchor_right == 1.0
        var style := _stylebox(Color(0.045, 0.063, 0.072, 0.94), Color("947253"), 105 if is_circle else 17)
        style.shadow_color = Color(0, 0, 0, 0.42)
        style.shadow_size = 10
        panel.add_theme_stylebox_override("panel", style)
    elif node is Button:
        var btn := node as Button
        btn.add_theme_stylebox_override("normal", _stylebox(Color("1b2930"), Color("886849"), 10))
        btn.add_theme_stylebox_override("hover", _stylebox(Color("3b3027"), AMBER, 10, 2))
        btn.add_theme_stylebox_override("pressed", _stylebox(Color("5a3a22"), AMBER, 10, 2))
        btn.add_theme_color_override("font_color", CREAM)
        btn.add_theme_color_override("font_hover_color", AMBER)
        btn.add_theme_color_override("font_pressed_color", CREAM)
    elif node is LineEdit:
        var line := node as LineEdit
        line.add_theme_stylebox_override("normal", _stylebox(Color("19232b"), Color("8e6b50"), 9))
        line.add_theme_stylebox_override("focus", _stylebox(Color("1c2630"), AMBER, 9, 2))
        line.add_theme_color_override("font_color", CREAM)

    for child in node.get_children():
        _style_recursive(child)

func _version_badge(hud: CanvasLayer) -> void:
    # Duidelijk verschil met v0.5.1, zonder de bestaande knoppen te blokkeren.
    var box := PanelContainer.new()
    box.name = "LookV06Badge"
    box.anchor_left = 0.5
    box.anchor_right = 0.5
    box.offset_left = -183
    box.offset_right = 183
    box.offset_top = 14
    box.offset_bottom = 74
    box.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_theme_stylebox_override("panel", _stylebox(Color(0.055, 0.085, 0.098, 0.95), BRASS, 16, 2))
    var contents := VBoxContainer.new()
    contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
    box.add_child(contents)
    var title := Label.new()
    title.text = "☕  TEAM SPEAK HEERLEN"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", CREAM)
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    contents.add_child(title)
    var sub := Label.new()
    sub.text = "3D CAFÉ  •  LOOK v0.6  •  LIVE VOICE"
    sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    sub.add_theme_font_size_override("font_size", 12)
    sub.add_theme_color_override("font_color", AMBER)
    sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
    contents.add_child(sub)
    hud.add_child(box)
