extends CharacterBody3D
## v0.7: gestileerde, menselijkere 3D-avatars. Zelfde beweging en online-data.
## Dit zijn GEEN echte persoonsgezichten of TeamSpeak-profielafbeeldingen.

var display_name: String = "Bezoeker"
var shirt_color: Color = Color("344d62")
var demo_mode: bool = false
var remote_mode: bool = false
var label_node: Label3D
var remote_speaking := false
var camera_heading: float = 0.0
var seated: bool = false
var dancing: bool = false
var speed: float = 4.0
var anim_time: float = 0.0
var visual: Node3D
var left_arm: Node3D
var right_arm: Node3D
var left_leg: Node3D
var right_leg: Node3D
var speaking_ring: MeshInstance3D
var idle_phase: float = 0.0

func _ready() -> void:
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.30
    capsule.height = 1.72
    var shape := CollisionShape3D.new()
    shape.shape = capsule
    shape.position = Vector3(0, 0.87, 0)
    add_child(shape)
    visual = Node3D.new()
    add_child(visual)
    _make_avatar()
    if demo_mode or remote_mode:
        collision_layer = 0
        collision_mask = 0
        set_physics_process(false)
    else:
        collision_layer = 1
        collision_mask = 1

func _material(color: Color, rough: float = 0.72, metal: float = 0.0) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = rough
    mat.metallic = metal
    return mat

func _ellipsoid(parent: Node3D, pos: Vector3, dimensions: Vector3, mat: Material) -> MeshInstance3D:
    var shape := SphereMesh.new()
    shape.radius = 0.5
    shape.height = 1.0
    shape.radial_segments = 16
    shape.rings = 8
    var part := MeshInstance3D.new()
    part.mesh = shape
    part.material_override = mat
    part.position = pos
    part.scale = dimensions
    parent.add_child(part)
    return part

func _capsule(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
    var shape := CapsuleMesh.new()
    shape.radius = radius
    shape.height = maxf(height, 2.0 * radius + 0.01)
    shape.radial_segments = 16
    shape.rings = 6
    var part := MeshInstance3D.new()
    part.mesh = shape
    part.material_override = mat
    part.position = pos
    parent.add_child(part)
    return part

func _box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
    var shape := BoxMesh.new()
    shape.size = size
    var part := MeshInstance3D.new()
    part.mesh = shape
    part.material_override = mat
    part.position = pos
    parent.add_child(part)
    return part

func _ring(parent: Node3D, pos: Vector3, color: Color) -> MeshInstance3D:
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.33
    mesh.outer_radius = 0.38
    mesh.ring_segments = 32
    mesh.rings = 6
    var material := _material(color, 0.25)
    material.emission_enabled = true
    material.emission = color
    material.emission_energy_multiplier = 2.0
    var part := MeshInstance3D.new()
    part.mesh = mesh
    part.material_override = material
    part.position = pos
    parent.add_child(part)
    return part

func _make_avatar() -> void:
    # Kleuren worden stabiel bepaald door de gebruikersnaam. Geen netwerkdata nodig.
    var seed: int = absi(display_name.hash())
    var skin_tones: Array[Color] = [
        Color("efd0b6"), Color("e8b894"), Color("dca47b"),
        Color("bc7957"), Color("895440"), Color("624338")
    ]
    var hair_tones: Array[Color] = [
        Color("27282b"), Color("4a332b"), Color("604736"),
        Color("aa7550"), Color("c49b62"), Color("393d48")
    ]
    var skin := _material(skin_tones[seed % skin_tones.size()], 0.84)
    var hair := _material(hair_tones[int(seed / 7) % hair_tones.size()], 0.88)
    var shirt := _material(shirt_color.lightened(0.07), 0.78)
    var jacket := _material(shirt_color.darkened(0.15), 0.80)
    var trim := _material(shirt_color.lightened(0.29), 0.65)
    var tee := _material(Color("e8e3dd"), 0.91)
    var denim := _material(Color("2d3847") if seed % 3 else Color("464147"), 0.90)
    var soles := _material(Color("e4e0d8"), 0.83)
    var shoes := _material(Color("232b31") if seed % 2 else Color("a7a49b"), 0.77)
    var eye_whites := _material(Color("f6f1e9"), 0.39)
    var iris := _material(Color("2d2b28"), 0.38)
    var lips := _material(Color("a66a61"), 0.87)
    var accent := _material(Color("dbad75"), 0.36, 0.38)

    # Afgeronde, menselijkere contour: taille, schouders, nek en jas.
    _ellipsoid(visual, Vector3(0, 1.14, 0.0), Vector3(0.56, 0.80, 0.39), jacket)
    _ellipsoid(visual, Vector3(0, 1.18, -0.191), Vector3(0.29, 0.55, 0.054), tee)
    _ellipsoid(visual, Vector3(0, 0.76, 0.0), Vector3(0.51, 0.25, 0.36), denim)
    _capsule(visual, Vector3(0, 1.51, 0.0), 0.105, 0.26, skin)

    # Nek, natuurlijke kaaklijn, oren, subtiele ogen, wenkbrauwen en neus.
    _ellipsoid(visual, Vector3(0, 1.72, -0.025), Vector3(0.49, 0.59, 0.45), skin)
    for side in [-1.0, 1.0]:
        _ellipsoid(visual, Vector3(side * 0.245, 1.71, -0.02), Vector3(0.09, 0.16, 0.09), skin)
        _ellipsoid(visual, Vector3(side * 0.094, 1.748, -0.240), Vector3(0.080, 0.040, 0.021), eye_whites)
        _ellipsoid(visual, Vector3(side * 0.094, 1.747, -0.255), Vector3(0.033, 0.034, 0.015), iris)
        _ellipsoid(visual, Vector3(side * 0.097, 1.811, -0.242), Vector3(0.102, 0.023, 0.024), hair)
    _ellipsoid(visual, Vector3(0, 1.668, -0.262), Vector3(0.075, 0.117, 0.080), skin)
    _ellipsoid(visual, Vector3(0, 1.584, -0.253), Vector3(0.125, 0.018, 0.013), lips)

    # Verschillende neutrale kapsels: kort, warrig of halflang.
    var style: int = seed % 3
    _ellipsoid(visual, Vector3(0, 1.960, -0.005), Vector3(0.51, 0.245, 0.46), hair)
    for i in range(5):
        var x: float = (float(i) - 2.0) * 0.095
        var lower: float = 1.875 - float((i + style) % 3) * 0.023
        _ellipsoid(visual, Vector3(x, lower, -0.194), Vector3(0.13, 0.12, 0.13), hair)
    if style == 1:
        for i in range(4):
            var angle: float = float(i) * TAU / 4.0
            _ellipsoid(visual, Vector3(sin(angle) * 0.14, 2.06, cos(angle) * 0.13), Vector3(0.18, 0.17, 0.19), hair)
    elif style == 2:
        for side in [-1.0, 1.0]:
            _ellipsoid(visual, Vector3(side * 0.205, 1.63, 0.03), Vector3(0.14, 0.39, 0.29), hair)
        _ellipsoid(visual, Vector3(0, 1.64, 0.19), Vector3(0.42, 0.42, 0.16), hair)

    # Kledingdetails: halslijn, jaspanden, zakjes en knopen.
    _ellipsoid(visual, Vector3(0, 1.50, -0.193), Vector3(0.27, 0.105, 0.055), tee)
    for side in [-1.0, 1.0]:
        var lapel := _box(visual, Vector3(side * 0.154, 1.325, -0.230), Vector3(0.092, 0.34, 0.045), trim)
        lapel.rotation.z = side * 0.24
        _box(visual, Vector3(side * 0.185, 1.004, -0.194), Vector3(0.10, 0.033, 0.023), accent)
    for y in [1.25, 1.14, 1.03]:
        _ellipsoid(visual, Vector3(0.15, y, -0.250), Vector3(0.026, 0.026, 0.012), accent)

    # Armen zijn afzonderlijke draaipunten voor lopen en dansen.
    left_arm = Node3D.new()
    left_arm.position = Vector3(-0.38, 1.41, 0.0)
    visual.add_child(left_arm)
    right_arm = Node3D.new()
    right_arm.position = Vector3(0.38, 1.41, 0.0)
    visual.add_child(right_arm)
    for arm in [left_arm, right_arm]:
        _ellipsoid(arm, Vector3(0, -0.08, 0), Vector3(0.30, 0.27, 0.30), shirt)
        _capsule(arm, Vector3(0, -0.34, 0), 0.125, 0.60, jacket)
        _capsule(arm, Vector3(0, -0.665, 0), 0.085, 0.16, skin)
        _ellipsoid(arm, Vector3(0, -0.755, -0.018), Vector3(0.19, 0.19, 0.17), skin)

    # Broek, enkels en schoenen met duidelijke zool en afgeronde neus.
    left_leg = Node3D.new()
    left_leg.position = Vector3(-0.145, 0.70, 0.0)
    visual.add_child(left_leg)
    right_leg = Node3D.new()
    right_leg.position = Vector3(0.145, 0.70, 0.0)
    visual.add_child(right_leg)
    for leg in [left_leg, right_leg]:
        _capsule(leg, Vector3(0, -0.29, 0.0), 0.142, 0.61, denim)
        _ellipsoid(leg, Vector3(0, -0.56, -0.08), Vector3(0.30, 0.18, 0.42), shoes)
        _ellipsoid(leg, Vector3(0, -0.628, -0.096), Vector3(0.31, 0.07, 0.43), soles)

    # Lichtcirkel verschijnt alleen wanneer een online bezoeker spreekt.
    speaking_ring = _ring(visual, Vector3(0, 0.057, 0), Color("f8bd69"))
    speaking_ring.visible = remote_mode and remote_speaking

    label_node = Label3D.new()
    label_node.text = _label_text()
    label_node.font_size = 36
    label_node.pixel_size = 0.0055
    label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label_node.outline_size = 12
    label_node.position = Vector3(0, 2.36, 0)
    label_node.modulate = Color("a8eaff") if demo_mode else (Color("a1ffb9") if remote_mode else Color("ffe6b1"))
    add_child(label_node)

func _label_text() -> String:
    if demo_mode:
        return "[DEMO] " + display_name
    if remote_mode:
        return ("▶ " if remote_speaking else "● ") + display_name
    return display_name

func update_display_name(value: String) -> void:
    display_name = value
    if is_instance_valid(label_node):
        label_node.text = _label_text()

func set_speaking(active: bool) -> void:
    remote_speaking = active
    if is_instance_valid(label_node):
        label_node.text = _label_text()
        label_node.modulate = Color("ffe08c") if active else Color("a1ffb9")
    if is_instance_valid(speaking_ring):
        speaking_ring.visible = active and remote_mode

func _process(delta: float) -> void:
    if not (remote_mode or demo_mode):
        return
    idle_phase += delta
    if is_instance_valid(visual):
        visual.position.y = sin(idle_phase * 1.55) * 0.008
    if remote_speaking and is_instance_valid(speaking_ring):
        var pulse: float = 1.0 + sin(idle_phase * 7.0) * 0.09
        speaking_ring.scale = Vector3(pulse, 1.0, pulse)

func _physics_process(delta: float) -> void:
    var axis := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
    if seated:
        if axis.length() > 0.2:
            stand_up()
        else:
            velocity = Vector3.ZERO
            return
    var right := Vector3(cos(camera_heading), 0.0, -sin(camera_heading))
    var forward := Vector3(-sin(camera_heading), 0.0, -cos(camera_heading))
    var direction := right * axis.x + forward * (-axis.y)
    if direction.length_squared() > 1.0:
        direction = direction.normalized()
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    if is_on_floor():
        velocity.y = 0.0
    else:
        velocity.y -= 19.6 * delta
    move_and_slide()
    var moving := direction.length_squared() > 0.03
    if moving:
        visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 12.0))
    anim_time += delta
    if dancing:
        var sway := sin(anim_time * 6.5)
        visual.position.y = absf(sway) * 0.06
        left_arm.rotation.x = -0.7 + sway * 0.6
        right_arm.rotation.x = -0.7 - sway * 0.6
    elif moving:
        var stride := sin(anim_time * 11.0) * 0.50
        left_arm.rotation.x = stride
        right_arm.rotation.x = -stride
        left_leg.rotation.x = -stride
        right_leg.rotation.x = stride
        visual.position.y = absf(stride) * 0.025
    else:
        left_arm.rotation.x = lerpf(left_arm.rotation.x, 0.0, delta * 8.0)
        right_arm.rotation.x = lerpf(right_arm.rotation.x, 0.0, delta * 8.0)
        left_leg.rotation.x = lerpf(left_leg.rotation.x, 0.0, delta * 8.0)
        right_leg.rotation.x = lerpf(right_leg.rotation.x, 0.0, delta * 8.0)
        visual.position.y = lerpf(visual.position.y, 0.0, delta * 6.0)

func sit_at(seat: Node3D) -> void:
    seated = true
    dancing = false
    global_position = seat.global_position + Vector3(0, 0.12, 0)
    velocity = Vector3.ZERO
    visual.position.y = -0.3
    left_leg.rotation.x = -1.1
    right_leg.rotation.x = -1.1
    visual.rotation.y = seat.global_rotation.y

func stand_up() -> void:
    seated = false
    visual.position.y = 0.0
    left_leg.rotation.x = 0.0
    right_leg.rotation.x = 0.0
    global_position += Vector3(0, 0.12, -0.68)

func toggle_dance() -> bool:
    if seated:
        stand_up()
    dancing = not dancing
    return dancing
