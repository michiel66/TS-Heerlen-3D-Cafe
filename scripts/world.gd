
extends Node3D
## TeamSpeak Heerlen 3D Cafe v0.4
## Caféwereld, meubels, verlichting en demo-avatars.

const AVATAR_SCRIPT = preload("res://scripts/avatar.gd")

var wood_floor: StandardMaterial3D
var dark_brick: StandardMaterial3D
var furniture: StandardMaterial3D
var counter_top: StandardMaterial3D
var dark_metal: StandardMaterial3D
var warm_cream: StandardMaterial3D
var seat_red: StandardMaterial3D
var tile_glow: StandardMaterial3D
var leaf: StandardMaterial3D
var glass: StandardMaterial3D
var neon_blue: StandardMaterial3D
var neon_orange: StandardMaterial3D
var dance_tile: StandardMaterial3D

var demo_people: Array[Node3D] = []
var demo_all: Array[Node3D] = []
var dance_timer := 0.0

func _ready() -> void:
    _prepare_materials()
    _room()
    _counter_and_coffee()
    _tables_and_seats()
    _dance_room()
    _decorations()
    _demo_avatars()

func set_online_mode(is_online: bool) -> void:
    for npc in demo_all:
        if is_instance_valid(npc):
            npc.visible = not is_online

func _process(delta: float) -> void:
    dance_timer += delta

    for i in range(demo_people.size()):
        var npc := demo_people[i]

        if is_instance_valid(npc) and npc.visible:
            npc.rotation.y = sin(
                dance_timer * (1.0 + 0.15 * i) + i
            ) * 0.12

func _plain(
    color: Color,
    metal: float = 0.0,
    rough: float = 0.8,
    emission: float = 0.0
) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.metallic = metal
    mat.roughness = rough

    if emission > 0.0:
        mat.emission_enabled = true
        mat.emission = color
        mat.emission_energy_multiplier = emission

    return mat

func _image_mat(
    path: String,
    repeat: Vector3
) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = load(path) as Texture2D
    mat.uv1_scale = repeat
    mat.roughness = 0.85
    return mat

func _prepare_materials() -> void:
    wood_floor = _image_mat(
        "res://assets/textures/wood_floor.png",
        Vector3(3, 3, 3)
    )
    dark_brick = _image_mat(
        "res://assets/textures/dark_brick.png",
        Vector3(2, 2, 2)
    )
    furniture = _image_mat(
        "res://assets/textures/bar_wood.png",
        Vector3.ONE
    )

    counter_top = _plain(Color("503527"), 0.06, 0.24)
    dark_metal = _plain(Color("28272b"), 0.5, 0.34)
    warm_cream = _plain(Color("bd9873"))
    seat_red = _plain(Color("713b43"), 0.0, 0.72)
    leaf = _plain(Color("477943"))
    glass = _plain(Color("77a8b5"), 0.2, 0.21)

    neon_blue = _plain(
        Color("2f9cff"), 0.0, 0.2, 4.0
    )
    neon_orange = _plain(
        Color("ff9842"), 0.0, 0.3, 3.5
    )
    dance_tile = _image_mat(
        "res://assets/textures/dance_tiles.png",
        Vector3.ONE
    )
    tile_glow = _plain(
        Color("ae62e6"), 0.0, 0.2, 2.0
    )

func _box(
    pos: Vector3,
    size: Vector3,
    mat: Material,
    parent: Node3D = null,
    solid: bool = false
) -> MeshInstance3D:
    if parent == null:
        parent = self

    var item := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    item.mesh = mesh
    item.material_override = mat
    item.position = pos
    parent.add_child(item)

    if solid:
        var rigid := StaticBody3D.new()
        var shape := CollisionShape3D.new()
        var box_shape := BoxShape3D.new()
        box_shape.size = size
        shape.shape = box_shape
        rigid.add_child(shape)
        item.add_child(rigid)

    return item

func _cylinder(
    pos: Vector3,
    radius: float,
    height: float,
    mat: Material,
    parent: Node3D = null
) -> MeshInstance3D:
    if parent == null:
        parent = self

    var item := MeshInstance3D.new()
    var mesh := CylinderMesh.new()
    mesh.top_radius = radius
    mesh.bottom_radius = radius
    mesh.height = height
    item.mesh = mesh
    item.material_override = mat
    item.position = pos
    parent.add_child(item)
    return item

func _sphere(
    pos: Vector3,
    radius: float,
    mat: Material,
    parent: Node3D = null
) -> MeshInstance3D:
    if parent == null:
        parent = self

    var item := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    item.mesh = mesh
    item.material_override = mat
    item.position = pos
    parent.add_child(item)
    return item

func _label(
    text: String,
    pos: Vector3,
    color: Color,
    size: int = 46,
    width: float = 0.008,
    parent: Node3D = null
) -> Label3D:
    if parent == null:
        parent = self

    var label := Label3D.new()
    label.text = text
    label.font_size = size
    label.pixel_size = width
    label.modulate = color
    label.outline_size = 10
    label.position = pos
    parent.add_child(label)
    return label

func _light(
    pos: Vector3,
    color: Color,
    energy: float,
    radius: float
) -> void:
    var l := OmniLight3D.new()
    l.position = pos
    l.light_color = color
    l.light_energy = energy
    l.omni_range = radius
    l.shadow_enabled = false
    add_child(l)

func _room() -> void:
    _box(
        Vector3(0, -0.22, 0),
        Vector3(24, 0.42, 20),
        wood_floor, self, true
    )
    _box(
        Vector3(0, 4.9, 0),
        Vector3(24, 0.35, 20),
        warm_cream
    )
    _box(
        Vector3(-12.05, 2.35, 0),
        Vector3(0.32, 5.0, 20),
        dark_brick, self, true
    )
    _box(
        Vector3(12.05, 2.35, 0),
        Vector3(0.32, 5.0, 20),
        warm_cream, self, true
    )
    _box(
        Vector3(0, 2.35, -10.0),
        Vector3(24, 5.0, 0.28),
        dark_brick, self, true
    )
    _box(
        Vector3(0, 0.65, 10.05),
        Vector3(24, 1.3, 0.26),
        furniture, self, true
    )

    for x in [-9.0, -3.0, 3.0, 9.0]:
        _box(
            Vector3(x, 4.55, 0),
            Vector3(0.16, 0.65, 19.4),
            furniture
        )

    for z in [-8.0, -2.0, 4.0, 9.0]:
        _box(
            Vector3(0, 4.52, z),
            Vector3(23.6, 0.17, 0.14),
            furniture
        )

    for z in [-6.5, -1.5, 3.5, 7.8]:
        _box(
            Vector3(11.83, 2.65, z),
            Vector3(0.08, 2.6, 2.3),
            glass
        )

        for dy in [1.3, 4.0]:
            _box(
                Vector3(11.75, dy, z),
                Vector3(0.18, 0.14, 2.55),
                furniture
            )

        for dz in [-1.19, 1.19]:
            _box(
                Vector3(11.75, 2.65, z + dz),
                Vector3(0.18, 2.9, 0.14),
                furniture
            )

        _box(
            Vector3(11.71, 2.65, z),
            Vector3(0.18, 0.1, 2.5),
            furniture
        )

    for x in [-8.0, -2.0, 4.5, 9.0]:
        for z in [-6.0, 0.6, 6.4]:
            _cylinder(
                Vector3(x, 4.15, z),
                0.38, 0.24, dark_metal
            )
            _cylinder(
                Vector3(x, 4.0, z),
                0.16, 0.14, neon_orange
            )
            _light(
                Vector3(x, 3.85, z),
                Color("ffd4a0"), 0.65, 6.2
            )

    var env := WorldEnvironment.new()
    env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR
    env.environment.background_color = Color("15141a")
    env.environment.ambient_light_source = (
        Environment.AMBIENT_SOURCE_COLOR
    )
    env.environment.ambient_light_color = Color("ffe5c3")
    env.environment.ambient_light_energy = 0.62
    add_child(env)

func _counter_and_coffee() -> void:
    _box(
        Vector3(-7.45, 0.60, -2.7),
        Vector3(8.0, 1.2, 1.6),
        furniture, self, true
    )
    _box(
        Vector3(-7.45, 1.25, -2.7),
        Vector3(8.4, 0.14, 1.9),
        counter_top
    )
    _box(
        Vector3(-11.0, 0.63, -1.1),
        Vector3(1.1, 1.26, 2.1),
        furniture, self, true
    )
    _box(
        Vector3(-11.0, 1.3, -1.0),
        Vector3(1.18, 0.12, 2.2),
        counter_top
    )
    _box(
        Vector3(-7.35, 0.15, -1.84),
        Vector3(8.15, 0.05, 0.08),
        neon_orange
    )

    _box(
        Vector3(-8.8, 1.55, -2.78),
        Vector3(1.4, 0.62, 0.72),
        dark_metal
    )
    _box(
        Vector3(-8.8, 1.92, -2.45),
        Vector3(1.35, 0.12, 0.17),
        warm_cream
    )

    for x in [-9.25, -8.75, -8.25]:
        _cylinder(
            Vector3(x, 1.99, -2.39),
            0.13, 0.12, neon_orange
        )

    for x in [-5.0, -4.45, -3.9]:
        _cylinder(
            Vector3(x, 1.34, -2.3),
            0.15, 0.19, warm_cream
        )

    for level in [1.6, 2.6, 3.6]:
        _box(
            Vector3(-7.4, level, -9.67),
            Vector3(8.5, 0.15, 0.56),
            furniture
        )

        for x in [
            -10.4, -9.6, -8.5, -7.4,
            -6.3, -5.2, -4.3
        ]:
            _cylinder(
                Vector3(x, level + 0.15, -9.45),
                0.13, 0.15, warm_cream
            )

    _label(
        "KOFFIE  •  THEE  •  GEZELLIGHEID",
        Vector3(-7.15, 4.0, -9.75),
        Color("ffddb2"), 34, 0.007
    )

    for x in [-10.4, -9.1, -7.8, -6.5, -5.2, -3.9]:
        _stool(Vector3(x, 0, -0.95))

func _stool(pos: Vector3) -> void:
    _cylinder(
        pos + Vector3(0, 0.78, 0),
        0.30, 0.11, seat_red
    )

    for dx in [-0.20, 0.20]:
        for dz in [-0.18, 0.18]:
            _box(
                pos + Vector3(dx, 0.38, dz),
                Vector3(0.055, 0.76, 0.055),
                furniture
            )

func _table(
    pos: Vector3,
    size: float = 0.83
) -> void:
    _cylinder(
        pos + Vector3(0, 0.77, 0),
        size, 0.12, furniture
    )
    _cylinder(
        pos + Vector3(0, 0.40, 0),
        0.13, 0.73, dark_metal
    )
    _cylinder(
        pos + Vector3(0, 0.09, 0),
        0.44, 0.10, dark_metal
    )
    _cylinder(
        pos + Vector3(0.22, 0.86, 0.15),
        0.11, 0.13, warm_cream
    )
    _cylinder(
        pos + Vector3(-0.15, 0.85, -0.25),
        0.08, 0.12, warm_cream
    )
    _light(
        pos + Vector3(0, 1.15, 0),
        Color("ffa74f"), 0.18, 1.5
    )

func _chair(
    pos: Vector3,
    angle: float = 0.0
) -> void:
    var body := Node3D.new()
    body.position = pos
    body.rotation.y = angle
    add_child(body)

    _box(
        Vector3(0, 0.48, 0),
        Vector3(0.7, 0.13, 0.68),
        seat_red, body
    )
    _box(
        Vector3(0, 0.90, 0.31),
        Vector3(0.71, 0.77, 0.13),
        furniture, body
    )

    for x in [-0.27, 0.27]:
        for z in [-0.25, 0.25]:
            _box(
                Vector3(x, 0.25, z),
                Vector3(0.075, 0.52, 0.075),
                furniture, body
            )

    var seat := Node3D.new()
    seat.position = Vector3.ZERO
    seat.set_meta("seat_angle", body.rotation.y)
    seat.add_to_group("cafe_seats")
    body.add_child(seat)

func _tables_and_seats() -> void:
    var positions := [
        Vector3(3.9, 0, -4.3),
        Vector3(8.1, 0, -4.0),
        Vector3(4.9, 0, 0.7),
        Vector3(9.0, 0, 1.3),
        Vector3(4.1, 0, 5.2),
        Vector3(9.1, 0, 5.5)
    ]

    for p in positions:
        _table(p)
        _chair(
            p + Vector3(1.25, 0, 0),
            -PI * 0.5
        )
        _chair(
            p + Vector3(-1.25, 0, 0),
            PI * 0.5
        )

    _box(
        Vector3(10.7, 0.45, -1.1),
        Vector3(1.45, 0.7, 4.8),
        seat_red
    )
    _box(
        Vector3(11.36, 1.07, -1.1),
        Vector3(0.18, 1.05, 4.9),
        furniture
    )

    for p in [
        Vector3(1.6, 0, 6.8),
        Vector3(7.0, 0, 8.3)
    ]:
        _plant(p, 0.9)

func _plant(
    pos: Vector3,
    scale: float = 1.0
) -> void:
    _cylinder(
        pos + Vector3(0, 0.26 * scale, 0),
        0.31 * scale,
        0.51 * scale,
        furniture
    )
    _cylinder(
        pos + Vector3(0, 0.73 * scale, 0),
        0.08 * scale,
        0.75 * scale,
        leaf
    )

    for i in range(7):
        var a := i * TAU / 7.0
        var t := Vector3(cos(a), 0, sin(a))

        _sphere(
            pos
            + Vector3(0, 1.20 * scale, 0)
            + t * 0.35 * scale,
            0.29 * scale,
            leaf
        )

    _sphere(
        pos + Vector3(0, 1.48 * scale, 0),
        0.34 * scale,
        leaf
    )

func _dance_room() -> void:
    _box(
        Vector3(-0.6, 0.035, -7.2),
        Vector3(4.8, 0.065, 4.8),
        dance_tile
    )

    for x in [-3.15, 1.95]:
        _box(
            Vector3(x, 2.0, -4.76),
            Vector3(0.2, 4.0, 0.2),
            dark_metal
        )

    _box(
        Vector3(-0.6, 4.0, -4.76),
        Vector3(5.3, 0.26, 0.24),
        dark_metal
    )
    _label(
        "DANSVLOER",
        Vector3(-0.6, 3.63, -4.65),
        Color("f9d5ff"), 50, 0.0065
    )
    _box(
        Vector3(-0.6, 0.09, -4.83),
        Vector3(4.9, 0.06, 0.08),
        neon_blue
    )
    _sphere(
        Vector3(-0.6, 3.12, -7.8),
        0.32, dark_metal
    )

    for x in [-2.25, 1.1]:
        _box(
            Vector3(x, 0.85, -9.12),
            Vector3(0.7, 1.7, 0.55),
            dark_metal
        )
        _sphere(
            Vector3(x, 1.17, -8.81),
            0.18, dark_metal
        )

    _light(
        Vector3(-0.7, 3.05, -7.0),
        Color("a35cff"), 1.75, 5.0
    )
    _light(
        Vector3(1.2, 2.6, -6.0),
        Color("38a5ff"), 1.25, 4.5
    )

func _decorations() -> void:
    _box(
        Vector3(5.15, 3.10, -9.79),
        Vector3(6.6, 2.3, 0.12),
        dark_metal
    )
    _box(
        Vector3(5.15, 3.10, -9.71),
        Vector3(6.5, 2.20, 0.035),
        dark_brick
    )
    _label(
        "◉ TeamSpeak Heerlen",
        Vector3(5.15, 3.43, -9.65),
        Color("c7e4ff"), 55, 0.008
    )
    _label(
        "3D CAFÉ",
        Vector3(5.15, 2.65, -9.64),
        Color("ffa34d"), 70, 0.008
    )

    _box(
        Vector3(10.9, 1.77, -7.7),
        Vector3(0.12, 2.2, 3.15),
        dark_metal
    )
    _label(
        "27MC  •  RADIO  •  ZELLO",
        Vector3(10.8, 2.12, -7.7),
        Color("b9e7ff"), 24, 0.005
    )

    var radio := Node3D.new()
    radio.position = Vector3(9.7, 0, -7.5)
    radio.add_to_group("radio_spots")
    add_child(radio)

    _box(
        Vector3(9.8, 0.88, -8.45),
        Vector3(1.5, 0.12, 0.75),
        furniture
    )
    _box(
        Vector3(9.8, 1.05, -8.45),
        Vector3(0.9, 0.26, 0.5),
        dark_metal
    )
    _box(
        Vector3(9.8, 1.06, -8.16),
        Vector3(0.48, 0.12, 0.03),
        neon_blue
    )

    for p in [
        Vector3(-10.7, 0, 6.0),
        Vector3(-2.8, 0, 6.4),
        Vector3(10.8, 0, -5.1)
    ]:
        _plant(p, 0.87)

func _demo_avatars() -> void:
    var positions := [
        Vector3(-8.5, 0, -0.1),
        Vector3(-5.0, 0, 2.8),
        Vector3(2.8, 0, -4.0),
        Vector3(7.2, 0, 0.0),
        Vector3(-0.8, 0, -6.8),
        Vector3(0.7, 0, -7.5)
    ]

    var names := [
        "Demo Bar",
        "Demo Bezoeker",
        "Demo Kees",
        "Demo Linda",
        "Demo Danser",
        "Demo DJ"
    ]

    var coats := [
        Color("29485a"),
        Color("923d36"),
        Color("576a37"),
        Color("53476d"),
        Color("292d50"),
        Color("665038")
    ]

    for i in range(positions.size()):
        var npc = AVATAR_SCRIPT.new()
        npc.display_name = names[i]
        npc.shirt_color = coats[i]
        npc.demo_mode = true

        add_child(npc)
        demo_all.append(npc)

        npc.position = positions[i]
        npc.rotation.y = -0.3 + i * 0.49

        if i >= 4:
            demo_people.append(npc)
