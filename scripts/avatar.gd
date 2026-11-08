extends CharacterBody3D
## LOOK v0.8: uitsluitend Polygonal Mind / Poly Pizza 100 Avatars R1.
## Geen procedurele persoon-avatars of andere externe avatarbronnen.
## TS3-audio, roster en PTT blijven in hun eigen bestaande scripts.

const R1_CATALOG = preload("res://scripts/r1_avatar_catalog.gd")

var display_name: String = "Bezoeker"
var shirt_color: Color = Color("344d62")  # compatibiliteit met online_avatars.gd
var demo_mode: bool = false
var remote_mode: bool = false
var label_node: Label3D
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
var speaking_ring: MeshInstance3D
var idle_phase: float = 0.0
var model_index: int = -1
var model_node: Node3D
var animation_player: AnimationPlayer
var animation_state: String = ""

static func avatar_count() -> int:
    return R1_CATALOG.AVATARS.size()

func _ready() -> void:
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.30
    capsule.height = 1.72
    var shape := CollisionShape3D.new()
    shape.shape = capsule
    shape.position = Vector3(0, 0.87, 0)
    add_child(shape)
    visual = Node3D.new()
    visual.name = "AvatarVisual"
    add_child(visual)
    # Bestaande loop-, zit- en dansbediening mag op deze draaipunten blijven werken.
    # Voor een GLTF/VRM-skelet zijn eigen animatieclips nodig.
    left_arm = Node3D.new()
    right_arm = Node3D.new()
    left_leg = Node3D.new()
    right_leg = Node3D.new()
    for pivot in [left_arm, right_arm, left_leg, right_leg]:
        visual.add_child(pivot)

    speaking_ring = _make_speaking_ring()
    visual.add_child(speaking_ring)
    speaking_ring.visible = remote_mode and remote_speaking

    label_node = Label3D.new()
    label_node.text = _label_text()
    label_node.font_size = 36
    label_node.pixel_size = 0.0055
    label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label_node.outline_size = 12
    label_node.position = Vector3(0.0, 2.36, 0.0)
    label_node.modulate = Color("a8eaff") if demo_mode else (Color("a1ffb9") if remote_mode else Color("ffe6b1"))
    add_child(label_node)

    select_avatar(model_index)
    if demo_mode or remote_mode:
        collision_layer = 0
        collision_mask = 0
        set_physics_process(false)
    else:
        collision_layer = 1
        collision_mask = 1

func _make_speaking_ring() -> MeshInstance3D:
    var mesh := TorusMesh.new()
    mesh.inner_radius = 0.33
    mesh.outer_radius = 0.38
    mesh.ring_segments = 32
    mesh.rings = 6
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("f8bd69")
    material.roughness = 0.25
    material.emission_enabled = true
    material.emission = Color("f8bd69")
    material.emission_energy_multiplier = 2.0
    var ring := MeshInstance3D.new()
    ring.name = "TeamSpeakSpeakingIndicator"
    ring.mesh = mesh
    ring.material_override = material
    ring.position = Vector3(0, 0.057, 0)
    return ring

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
    if active:
        _play_action("talk")
    else:
        _play_action("idle")

func _effective_index(requested: int) -> int:
    var total: int = avatar_count()
    if total == 0:
        return -1
    if requested >= 0:
        return posmod(requested, total)
    return posmod(display_name.hash(), total)

func select_avatar(requested: int) -> bool:
    model_index = _effective_index(requested)
    if not is_instance_valid(visual):
        return false
    if is_instance_valid(model_node):
        model_node.queue_free()
        model_node = null
        animation_player = null
        animation_state = ""
    if model_index < 0:
        # Bewust geen fictieve avatar genereren: alleen de gekozen R1-collectie.
        push_warning("100 Avatars R1 ontbreekt. Importeer eerst de Poly Pizza GLTF-bundel.")
        return false
    var path: String = R1_CATALOG.AVATARS[model_index]
    var packed: Resource = load(path)
    if not packed is PackedScene:
        push_warning("Kon 100Avatars R1-model niet laden: " + path)
        return false
    var instance: Node = (packed as PackedScene).instantiate()
    if not instance is Node3D:
        instance.queue_free()
        push_warning("R1-model heeft geen Node3D-root: " + path)
        return false
    model_node = instance as Node3D
    model_node.name = "PolygonalMind_R1_" + str(model_index + 1)
    visual.add_child(model_node)
    _normalize_model(model_node)
    var players: Array[Node] = model_node.find_children("*", "AnimationPlayer", true, false)
    if not players.is_empty():
        animation_player = players[0] as AnimationPlayer
    _play_action("idle")
    return true

func cycle_avatar(step: int) -> int:
    if avatar_count() == 0:
        return -1
    var current: int = _effective_index(model_index)
    select_avatar(posmod(current + step, avatar_count()))
    return model_index

func _normalize_model(scene_root: Node3D) -> void:
    # Modelleerschalen kunnen verschillen: schaal naar ongeveer 1.9 meter,
    # met de voeten op de grond en de figuur gecentreerd.
    var meshes: Array[Node] = scene_root.find_children("*", "MeshInstance3D", true, false)
    if scene_root is MeshInstance3D:
        meshes.push_back(scene_root)
    var min_p := Vector3(INF, INF, INF)
    var max_p := Vector3(-INF, -INF, -INF)
    var seen := false
    for item in meshes:
        var mesh := item as MeshInstance3D
        if mesh.mesh == null:
            continue
        var bounds: AABB = mesh.get_aabb()
        var relative: Transform3D = visual.global_transform.affine_inverse() * mesh.global_transform
        for dx in [0.0, 1.0]:
            for dy in [0.0, 1.0]:
                for dz in [0.0, 1.0]:
                    var local: Vector3 = bounds.position + bounds.size * Vector3(dx, dy, dz)
                    var point: Vector3 = relative * local
                    min_p = min_p.min(point)
                    max_p = max_p.max(point)
                    seen = true
    if not seen:
        return
    var height: float = max_p.y - min_p.y
    if height <= 0.0001:
        return
    var factor: float = clampf(1.92 / height, 0.001, 1000.0)
    scene_root.scale *= factor
    scene_root.position = Vector3(
        -(min_p.x + max_p.x) * 0.5 * factor,
        -min_p.y * factor,
        -(min_p.z + max_p.z) * 0.5 * factor
    )

func _play_action(action: String) -> void:
    if not is_instance_valid(animation_player):
        return
    if animation_state == action:
        return
    for clip in animation_player.get_animation_list():
        var lowered: String = str(clip).to_lower()
        if lowered.contains(action):
            animation_player.play(clip)
            animation_state = action
            return
    # Geen animatieclip? Model blijft zichtbaar; geen skelet fictief aanpassen.

func _process(delta: float) -> void:
    if not (remote_mode or demo_mode):
        return
    idle_phase += delta
    if is_instance_valid(visual):
        visual.position.y = sin(idle_phase * 1.55) * 0.008
        visual.rotation.z = sin(idle_phase * 0.9) * 0.008
    if remote_speaking and is_instance_valid(speaking_ring):
        var pulse: float = 1.0 + sin(idle_phase * 7.0) * 0.09
        speaking_ring.scale = Vector3(pulse, 1.0, pulse)

func _physics_process(delta: float) -> void:
    var axis: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
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
    var moving: bool = direction.length_squared() > 0.03
    if moving:
        visual.rotation.y = lerp_angle(visual.rotation.y, atan2(-direction.x, -direction.z), minf(1.0, delta * 12.0))
    anim_time += delta
    if dancing:
        var sway: float = sin(anim_time * 6.5)
        visual.position.y = absf(sway) * 0.06
        visual.rotation.z = sway * 0.12
        _play_action("dance")
    elif moving:
        var stride: float = sin(anim_time * 11.0) * 0.50
        visual.position.y = absf(stride) * 0.025
        visual.rotation.z = 0.0
        _play_action("walk")
    else:
        visual.position.y = lerpf(visual.position.y, 0.0, minf(delta * 6.0, 1.0))
        visual.rotation.z = lerpf(visual.rotation.z, 0.0, minf(delta * 8.0, 1.0))
        _play_action("idle")

func sit_at(seat: Node3D) -> void:
    seated = true
    dancing = false
    global_position = seat.global_position + Vector3(0, 0.12, 0)
    velocity = Vector3.ZERO
    visual.position.y = -0.3
    visual.rotation.y = seat.global_rotation.y
    _play_action("sit")

func stand_up() -> void:
    seated = false
    visual.position.y = 0.0
    global_position += Vector3(0, 0.12, -0.68)
    _play_action("idle")

func toggle_dance() -> bool:
    if seated:
        stand_up()
    dancing = not dancing
    return dancing
