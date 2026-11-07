
extends CharacterBody3D
## TeamSpeak Heerlen 3D Cafe v0.4
## Lokale speler, demo-avatar en online TeamSpeak-avatar.

var display_name: String = "Bezoeker"
var shirt_color: Color = Color("344d62")
var demo_mode: bool = false
var remote_mode: bool = false
var remote_speaking: bool = false

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
var label_node: Label3D

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

func _material(color: Color) -> StandardMaterial3D:
    var mat := StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.82
    return mat

func _cube(
    parent: Node3D,
    pos: Vector3,
    size: Vector3,
    color: Color
) -> Node3D:
    var part := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    part.mesh = mesh
    part.material_override = _material(color)
    part.position = pos
    parent.add_child(part)
    return part

func _ball(
    parent: Node3D,
    pos: Vector3,
    radius: float,
    color: Color
) -> void:
    var part := MeshInstance3D.new()
    var mesh := SphereMesh.new()
    mesh.radius = radius
    mesh.height = radius * 2.0
    part.mesh = mesh
    part.material_override = _material(color)
    part.position = pos
    parent.add_child(part)

func _make_avatar() -> void:
    var skin := Color("d7a482")
    var pants := Color("343b47")
    var shoes := Color("1b2127")

    _cube(
        visual, Vector3(0, 1.11, 0),
        Vector3(0.62, 0.75, 0.36), shirt_color
    )
    _cube(
        visual, Vector3(0, 0.72, 0),
        Vector3(0.52, 0.26, 0.34), pants
    )
    _ball(visual, Vector3(0, 1.69, 0), 0.27, skin)
    _cube(
        visual, Vector3(0, 1.91, 0),
        Vector3(0.49, 0.12, 0.47), Color("31251f")
    )

    # Ogen
    _ball(
        visual, Vector3(-0.095, 1.71, -0.242),
        0.023, Color("17181c")
    )
    _ball(
        visual, Vector3(0.095, 1.71, -0.242),
        0.023, Color("17181c")
    )

    left_arm = Node3D.new()
    left_arm.position = Vector3(-0.42, 1.41, 0)
    visual.add_child(left_arm)
    _cube(
        left_arm, Vector3(0, -0.35, 0),
        Vector3(0.19, 0.69, 0.21), shirt_color
    )
    _ball(
        left_arm, Vector3(0, -0.72, 0),
        0.105, skin
    )

    right_arm = Node3D.new()
    right_arm.position = Vector3(0.42, 1.41, 0)
    visual.add_child(right_arm)
    _cube(
        right_arm, Vector3(0, -0.35, 0),
        Vector3(0.19, 0.69, 0.21), shirt_color
    )
    _ball(
        right_arm, Vector3(0, -0.72, 0),
        0.105, skin
    )

    left_leg = Node3D.new()
    left_leg.position = Vector3(-0.17, 0.64, 0)
    visual.add_child(left_leg)
    _cube(
        left_leg, Vector3(0, -0.27, 0),
        Vector3(0.23, 0.55, 0.27), pants
    )
    _cube(
        left_leg, Vector3(0, -0.53, -0.06),
        Vector3(0.26, 0.14, 0.38), shoes
    )

    right_leg = Node3D.new()
    right_leg.position = Vector3(0.17, 0.64, 0)
    visual.add_child(right_leg)
    _cube(
        right_leg, Vector3(0, -0.27, 0),
        Vector3(0.23, 0.55, 0.27), pants
    )
    _cube(
        right_leg, Vector3(0, -0.53, -0.06),
        Vector3(0.26, 0.14, 0.38), shoes
    )

    # Gebruikersnaam boven avatar
    label_node = Label3D.new()
    label_node.text = _label_text()
    label_node.font_size = 32
    label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label_node.pixel_size = 0.006
    label_node.position = Vector3(0, 2.35, 0)
    label_node.outline_size = 9

    if demo_mode:
        label_node.modulate = Color("a8eaff")
    elif remote_mode:
        label_node.modulate = Color("a1ffb9")
    else:
        label_node.modulate = Color("ffe6b1")

    add_child(label_node)

func _label_text() -> String:
    if demo_mode:
        return "[DEMO] " + display_name

    if remote_mode:
        if remote_speaking:
            return "🎙 " + display_name
        return "● " + display_name

    return display_name

func update_display_name(value: String) -> void:
    display_name = value

    if is_instance_valid(label_node):
        label_node.text = _label_text()

func set_speaking(active: bool) -> void:
    remote_speaking = active

    if is_instance_valid(label_node):
        label_node.text = _label_text()

        if active:
            label_node.modulate = Color("ffe08c")
        else:
            label_node.modulate = Color("a1ffb9")

func _physics_process(delta: float) -> void:
    var axis := Input.get_vector(
        "move_left", "move_right",
        "move_forward", "move_backward"
    )

    if seated:
        if axis.length() > 0.2:
            stand_up()
        else:
            velocity = Vector3.ZERO
            return

    var right := Vector3(
        cos(camera_heading), 0.0,
        -sin(camera_heading)
    )
    var forward := Vector3(
        -sin(camera_heading), 0.0,
        -cos(camera_heading)
    )

    var direction := (
        right * axis.x + forward * (-axis.y)
    )

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
        visual.rotation.y = lerp_angle(
            visual.rotation.y,
            atan2(-direction.x, -direction.z),
            minf(1.0, delta * 12.0)
        )

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
        left_arm.rotation.x = lerpf(
            left_arm.rotation.x, 0.0, delta * 8.0
        )
        right_arm.rotation.x = lerpf(
            right_arm.rotation.x, 0.0, delta * 8.0
        )
        left_leg.rotation.x = lerpf(
            left_leg.rotation.x, 0.0, delta * 8.0
        )
        right_leg.rotation.x = lerpf(
            right_leg.rotation.x, 0.0, delta * 8.0
        )
        visual.position.y = lerpf(
            visual.position.y, 0.0, delta * 6.0
        )

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
