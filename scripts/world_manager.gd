extends Node3D
## Night Club world chooser: no changes to main.gd, hud.gd or TeamSpeak PTT.
## The world is a local visual choice; it does NOT synchronize the remote TS3 clients.

const NIGHT_CLUB_PATH := "res://assets/worlds/night_club/night_club.glb"
const CAFE_SPAWN := Vector3(2.3, 0.15, 5.8)
const CLUB_SPAWN := Vector3(0.0, 0.15, 3.2)
const CLUB_DANCE := Vector3(0.0, 0.15, 0.6)
const CLUB_DJ := Vector3(0.0, 0.15, -1.7)

var game: Node3D
var hud
var cafe: Node3D
var player: Node3D
var visitors
var club_root: Node3D
var club_model: Node3D
var world_form: VBoxContainer
var world_picker: OptionButton
var world_description: Label
var current_world_id: String = "cafe"
var cafe_collision_state: Dictionary = {}
var club_collision_state: Dictionary = {}
var old_visitor_positions: Array[Vector3] = []

func _ready() -> void:
    # main.gd creates the HUD and the cafe in _ready; this must run afterwards.
    call_deferred("_install")

func _install() -> void:
    game = get_parent() as Node3D
    if game == null:
        push_warning("WorldManager: hoofdscene niet gevonden")
        return
    hud = game.get_node_or_null("CafeHUD")
    cafe = game.get_node_or_null("CafeWorld") as Node3D
    player = game.get_node_or_null("LocalAvatar") as Node3D
    visitors = game.get_node_or_null("OnlineVisitors")
    if hud == null or cafe == null or player == null:
        push_warning("WorldManager: cafe, speler of HUD ontbreekt; oorspronkelijke wereld blijft actief")
        return

    club_root = Node3D.new()
    club_root.name = "ImportedNightClub"
    club_root.visible = false
    add_child(club_root)

    _install_settings_tab()
    hud.action_requested.connect(_on_hud_action)

    var cfg: ConfigFile = game.get("profile") as ConfigFile
    var stored: String = str(cfg.get_value("world", "selected", "cafe")) if cfg != null else "cafe"
    if stored == "night_club":
        _activate_world("night_club", false)
    else:
        _sync_picker()
    print("WORLD_MANAGER_OK: wereldbeheer aanwezig; huidige wereld = " + current_world_id)

func _install_settings_tab() -> void:
    var tabs: HBoxContainer = hud.settings_tabs as HBoxContainer
    var overlay: PanelContainer = hud.overlay as PanelContainer
    if tabs == null or overlay == null:
        push_warning("WorldManager: instellingen-tabs ontbreken")
        return

    # Existing profile and TS buttons already have their own callbacks.
    # Hide our additional form whenever one of those tabs is selected.
    for child in tabs.get_children():
        if child is BaseButton:
            (child as BaseButton).pressed.connect(_hide_world_form)

    var tab := Button.new()
    tab.text = "🌐 Wereldbeheer"
    tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    tab.pressed.connect(_show_world_tab)
    tabs.add_child(tab)

    var body: VBoxContainer = overlay.get_child(0) as VBoxContainer
    if body == null:
        push_warning("WorldManager: instellingeninhoud niet gevonden")
        return

    world_form = VBoxContainer.new()
    world_form.name = "WorldSettingsForm"
    world_form.add_theme_constant_override("separation", 9)
    world_form.visible = false
    body.add_child(world_form)

    var title := Label.new()
    title.text = "Kies jouw 3D-omgeving"
    title.add_theme_font_size_override("font_size", 18)
    title.add_theme_color_override("font_color", Color("ffbb78"))
    world_form.add_child(title)

    world_picker = OptionButton.new()
    world_picker.add_item("TeamSpeak Heerlen – Origineel café", 0)
    world_picker.add_item("Night Club – MBRODERI2", 1)
    world_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    world_picker.item_selected.connect(_preview_world_selection)
    world_form.add_child(world_picker)

    world_description = Label.new()
    world_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    world_description.text = "Kies een wereld en klik op 'Wereld laden'."
    world_form.add_child(world_description)

    var apply := Button.new()
    apply.text = "✓ Wereld laden en bewaren"
    apply.pressed.connect(_apply_selected_world)
    world_form.add_child(apply)

    var attribution := Button.new()
    attribution.text = "Night Club © MBRODERI2 · CC BY 4.0 · Bron en licentie"
    attribution.tooltip_text = "https://skfb.ly/ouHGD"
    attribution.pressed.connect(func() -> void: OS.shell_open("https://skfb.ly/ouHGD"))
    world_form.add_child(attribution)

    var notice := Label.new()
    notice.text = "Jouw keuze wordt op deze pc opgeslagen. Andere TeamSpeak-gebruikers kunnen hun eigen wereld kiezen."
    notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    notice.add_theme_font_size_override("font_size", 12)
    world_form.add_child(notice)

    overlay.visibility_changed.connect(_on_overlay_visibility_changed)
    _sync_picker()

func _on_overlay_visibility_changed() -> void:
    if is_instance_valid(world_form):
        world_form.visible = false

func _hide_world_form() -> void:
    if is_instance_valid(world_form):
        world_form.visible = false

func _show_world_tab() -> void:
    hud.overlay_title.text = "Instellingen · Wereldbeheer"
    hud.profile_form.visible = false
    hud.teamspeak_form.visible = false
    hud.chat_entry.visible = false
    hud.overlay_scroll.custom_minimum_size = Vector2(0, 50)
    hud.overlay_text.custom_minimum_size = Vector2(0, 42)
    hud.overlay_text.text = "Verander alleen de 3D-omgeving. Je avatar, microfoon en TeamSpeak-verbinding blijven behouden."
    world_form.visible = true
    _sync_picker()

func _sync_picker() -> void:
    if not is_instance_valid(world_picker):
        return
    world_picker.select(1 if current_world_id == "night_club" else 0)
    _preview_world_selection(world_picker.selected)

func _preview_world_selection(index: int) -> void:
    if not is_instance_valid(world_description):
        return
    if index == 1:
        world_description.text = "Complete 3D-nachtclub (DJ-podium, dansvloer en bar). Met botsingen en eigen verlichting."
    else:
        world_description.text = "Het originele TeamSpeak Heerlen 3D Café met koffiebar, lounge en radiohoek."

func _apply_selected_world() -> void:
    if not is_instance_valid(world_picker):
        return
    var world_id := "night_club" if world_picker.selected == 1 else "cafe"
    if not _activate_world(world_id, true):
        _sync_picker()
        return
    hud.overlay.visible = false

func _activate_world(world_id: String, save_choice: bool) -> bool:
    if cafe == null or player == null:
        return false
    if world_id != "cafe" and world_id != "night_club":
        return false

    if world_id == "night_club":
        if not _load_night_club():
            hud.set_status("Night Club kon niet worden geladen. Het café blijft beschikbaar.")
            return false
        cafe.visible = false
        _set_collisions(cafe, false, cafe_collision_state)
        club_root.visible = true
        _set_collisions(club_root, true, club_collision_state)
        _set_guest_positions(true)
        _teleport(CLUB_SPAWN)
    else:
        if is_instance_valid(club_root):
            club_root.visible = false
            _set_collisions(club_root, false, club_collision_state)
        cafe.visible = true
        _set_collisions(cafe, true, cafe_collision_state)
        _set_guest_positions(false)
        _teleport(CAFE_SPAWN)

    current_world_id = world_id
    _sync_picker()
    if save_choice:
        var cfg: ConfigFile = game.get("profile") as ConfigFile
        if cfg != null:
            cfg.set_value("world", "selected", world_id)
            var result: Error = cfg.save("user://cafe_profiel.cfg")
            if result != OK:
                hud.set_status("Wereld actief, maar instellingen opslaan mislukt.")
                return true
    hud.set_status("Night Club van MBRODERI2 geladen (CC BY 4.0)." if world_id == "night_club" else "Origineel TeamSpeak Heerlen café geladen.")
    return true

func _load_night_club() -> bool:
    if is_instance_valid(club_model):
        return true
    if not ResourceLoader.exists(NIGHT_CLUB_PATH):
        push_warning("Nachtclub GLB niet gevonden: " + NIGHT_CLUB_PATH)
        return false
    var resource: Resource = load(NIGHT_CLUB_PATH)
    if not resource is PackedScene:
        push_warning("Nachtclub is geen geldige 3D-scene: " + NIGHT_CLUB_PATH)
        return false
    var instance: Node = (resource as PackedScene).instantiate()
    if not instance is Node3D:
        instance.queue_free()
        return false
    club_model = instance as Node3D
    club_model.name = "NightClub_MBRODERI2"
    club_root.add_child(club_model)

    # Static geometry only: triangles are created once, not each frame.
    # A safe floor and perimeter also prevent falling out of the supplied scene.
    _create_floor_and_edges()
    for item in club_model.find_children("*", "MeshInstance3D", true, false):
        var mesh := item as MeshInstance3D
        var lower := mesh.name.to_lower()
        if mesh.mesh != null and (
            lower.contains("_wall_") or lower.contains("_bar_") or
            lower.contains("_table_") or lower.contains("_bench_") or
            lower.contains("_rail_") or lower.contains("_door_") or
            lower.contains("dj_stand")
        ):
            mesh.create_trimesh_collision()

    _add_nightclub_light(Vector3(-2.7, 3.25, 0.0), Color("7d8cff"), 1.15, 8.0)
    _add_nightclub_light(Vector3(2.7, 3.25, 1.1), Color("f47dcb"), 1.25, 8.0)
    _add_nightclub_light(Vector3(0.0, 3.5, -2.9), Color("ffe4b1"), 1.0, 6.0)
    return true

func _create_floor_and_edges() -> void:
    _static_box(Vector3(0.0, -0.17, 0.0), Vector3(9.1, 0.30, 9.1))
    _static_box(Vector3(-4.61, 1.45, 0), Vector3(0.18, 3.0, 9.1))
    _static_box(Vector3(4.61, 1.45, 0), Vector3(0.18, 3.0, 9.1))
    _static_box(Vector3(0, 1.45, -4.61), Vector3(9.1, 3.0, 0.18))
    _static_box(Vector3(0, 1.45, 4.61), Vector3(9.1, 3.0, 0.18))

func _static_box(at: Vector3, dimensions: Vector3) -> void:
    var body := StaticBody3D.new()
    body.position = at
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = dimensions
    shape.shape = box
    body.add_child(shape)
    club_root.add_child(body)

func _add_nightclub_light(at: Vector3, tint: Color, energy: float, radius: float) -> void:
    var light := OmniLight3D.new()
    light.position = at
    light.light_color = tint
    light.light_energy = energy
    light.omni_range = radius
    light.shadow_enabled = false
    club_root.add_child(light)

func _set_collisions(world_root: Node3D, enabled: bool, values: Dictionary) -> void:
    if not is_instance_valid(world_root):
        return
    for item in world_root.find_children("*", "CollisionObject3D", true, false):
        var object := item as CollisionObject3D
        if not values.has(object):
            values[object] = [object.collision_layer, object.collision_mask]
        if enabled:
            object.collision_layer = int(values[object][0])
            object.collision_mask = int(values[object][1])
        else:
            object.collision_layer = 0
            object.collision_mask = 0

func _set_guest_positions(nightclub: bool) -> void:
    if visitors == null:
        return
    if old_visitor_positions.is_empty():
        old_visitor_positions = visitors.slot_positions.duplicate()
    if nightclub:
        var positions: Array[Vector3] = []
        for z in [3.4, 2.5, 1.6, 0.7, -0.2, -1.1, -2.0, -2.9]:
            for x in [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0]:
                positions.append(Vector3(x, 0.15, z))
        visitors.slot_positions = positions
    else:
        visitors.slot_positions = old_visitor_positions.duplicate()
    for id in visitors.avatars.keys():
        var guest: Node3D = visitors.avatars[id] as Node3D
        if is_instance_valid(guest) and visitors.slots.has(id):
            guest.global_position = visitors._position_for_slot(int(visitors.slots[id]))

func _teleport(at: Vector3) -> void:
    if not is_instance_valid(player):
        return
    if player.seated:
        player.stand_up()
    player.seated = false
    player.dancing = false
    player.velocity = Vector3.ZERO
    player.global_position = at

func _on_hud_action(action: String) -> void:
    if current_world_id != "night_club":
        return
    if action == "cafe":
        _teleport(CLUB_SPAWN)
        hud.set_status("Night Club: bij de ingang.")
    elif action == "dance":
        _teleport(CLUB_DANCE)
        hud.set_status("Night Club: op de dansvloer. Druk F om te dansen.")
    elif action == "radio":
        _teleport(CLUB_DJ)
        hud.set_status("Night Club: bij de DJ-booth.")

func _unhandled_input(event: InputEvent) -> void:
    if current_world_id == "night_club" and event.is_action_pressed("reset_position") and not event.is_echo():
        # main.gd still uses the original cafe spawn; override it after that handler.
        call_deferred("_teleport", CLUB_SPAWN)
