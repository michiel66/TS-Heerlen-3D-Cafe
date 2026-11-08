extends Node3D
## Night Club world chooser: no changes to main.gd, hud.gd or TeamSpeak PTT.
## The world is a local visual choice; it does NOT synchronize the remote TS3 clients.

const NIGHT_CLUB_PATH := "res://assets/worlds/night_club/night_club.glb"
const COFFEE_SHOP_PATH := "res://assets/worlds/coffee_shop/coffee_shop.glb"
# De Coffee Shop is aangeleverd in Z-omhoog-coordinaten, circa 132 x 139 bron-eenheden.
# Rotatie -90 graden X + schaal 0.18 levert een ruimte van circa 24 x 25 meter op.
const COFFEE_SCALE: float = 0.18
const COFFEE_FLOOR_Z: float = -12.5
const COFFEE_SPAWN := Vector3(2.5, 0.15, 6.0)
const COFFEE_LOUNGE := Vector3(3.0, 0.15, 0.2)
const COFFEE_COUNTER := Vector3(-2.0, 0.15, 3.0)
# 1.0 = origineel; 2.4 = ongeveer 22 x 23 meter. Alleen Night Club wordt vergroot.
const CLUB_SCALE: float = 2.4
const CAFE_SPAWN := Vector3(2.3, 0.15, 5.8)
const CLUB_SPAWN := Vector3(0.0, 0.15, 3.2 * CLUB_SCALE)
const CLUB_DANCE := Vector3(0.0, 0.15, 0.6 * CLUB_SCALE)
const CLUB_DJ := Vector3(0.0, 0.15, -1.7 * CLUB_SCALE)

var game: Node3D
var hud
var cafe: Node3D
var player: Node3D
var visitors
var club_root: Node3D
var club_model: Node3D
var coffee_root: Node3D
var coffee_model: Node3D
var coffee_collision_state: Dictionary = {}
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
    # Uniforme schaal schaalt zowel de GLB als de collider-wereld mee.
    # Avatars blijven op hun bestaande grootte, buiten club_root.
    club_root.scale = Vector3.ONE * CLUB_SCALE
    club_root.visible = false
    add_child(club_root)

    coffee_root = Node3D.new()
    coffee_root.name = "ImportedCoffeeShop"
    coffee_root.scale = Vector3.ONE * COFFEE_SCALE
    coffee_root.visible = false
    add_child(coffee_root)

    _install_settings_tab()
    hud.action_requested.connect(_on_hud_action)

    var cfg: ConfigFile = game.get("profile") as ConfigFile
    var stored: String = str(cfg.get_value("world", "selected", "cafe")) if cfg != null else "cafe"
    if stored == "night_club" or stored == "coffee_shop":
        _activate_world(stored, false)
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
    world_picker.add_item("Night Club – MBRODERI2 (2,4×)", 1)
    world_picker.add_item("Coffee Shop – majesticmaje (ca. 24 x 25 m)", 2)
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

    var coffee_credit := Button.new()
    coffee_credit.text = "Coffee Shop · majesticmaje · CC BY 3.0 · Bron en licentie"
    coffee_credit.tooltip_text = "https://poly.pizza/m/FDG8rFhvv7"
    coffee_credit.pressed.connect(func() -> void: OS.shell_open("https://poly.pizza/m/FDG8rFhvv7"))
    world_form.add_child(coffee_credit)

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
    var selected_id: int = 0
    if current_world_id == "night_club":
        selected_id = 1
    elif current_world_id == "coffee_shop":
        selected_id = 2
    world_picker.select(selected_id)
    _preview_world_selection(selected_id)

func _preview_world_selection(index: int) -> void:
    if not is_instance_valid(world_description):
        return
    if index == 1:
        world_description.text = "Vergrote nachtclub: circa 22 x 23 meter (2,4x origineel). DJ-podium, dansvloer, bar en botsingen."
    elif index == 2:
        world_description.text = "Coffee Shop van majesticmaje: circa 24 x 25 meter, originele meubels, vloer en muren. Licentie CC BY 3.0."
    else:
        world_description.text = "Het originele TeamSpeak Heerlen 3D Café met koffiebar, lounge en radiohoek."

func _apply_selected_world() -> void:
    if not is_instance_valid(world_picker):
        return
    var world_id: String = "cafe"
    if world_picker.selected == 1:
        world_id = "night_club"
    elif world_picker.selected == 2:
        world_id = "coffee_shop"
    if not _activate_world(world_id, true):
        _sync_picker()
        return
    hud.overlay.visible = false

func _activate_world(world_id: String, save_choice: bool) -> bool:
    if cafe == null or player == null:
        return false
    if world_id != "cafe" and world_id != "night_club" and world_id != "coffee_shop":
        return false

    # Laad eerst de nieuwe omgeving. Bij een fout blijft de huidige wereld actief.
    if world_id == "night_club" and not _load_night_club():
        hud.set_status("Night Club kan niet worden geladen; huidige wereld behouden.")
        return false
    if world_id == "coffee_shop" and not _load_coffee_shop():
        hud.set_status("Coffee Shop kan niet worden geladen; huidige wereld behouden.")
        return false

    cafe.visible = world_id == "cafe"
    _set_collisions(cafe, world_id == "cafe", cafe_collision_state)
    club_root.visible = world_id == "night_club"
    _set_collisions(club_root, world_id == "night_club", club_collision_state)
    coffee_root.visible = world_id == "coffee_shop"
    _set_collisions(coffee_root, world_id == "coffee_shop", coffee_collision_state)

    _set_guest_positions(world_id)
    if world_id == "night_club":
        _teleport(CLUB_SPAWN)
    elif world_id == "coffee_shop":
        _teleport(COFFEE_SPAWN)
    else:
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
    if world_id == "night_club":
        hud.set_status("Night Club geladen: 2,4x vergroot · MBRODERI2 · CC BY 4.0.")
    elif world_id == "coffee_shop":
        hud.set_status("Coffee Shop geladen · majesticmaje · CC BY 3.0.")
    else:
        hud.set_status("Origineel TeamSpeak Heerlen café geladen.")
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

func _load_coffee_shop() -> bool:
    if is_instance_valid(coffee_model):
        return true
    if not ResourceLoader.exists(COFFEE_SHOP_PATH):
        push_warning("Coffee Shop GLB niet gevonden: " + COFFEE_SHOP_PATH)
        return false
    var resource: Resource = load(COFFEE_SHOP_PATH)
    if not resource is PackedScene:
        push_warning("Coffee Shop is geen geldige 3D-scene: " + COFFEE_SHOP_PATH)
        return false
    var instance: Node = (resource as PackedScene).instantiate()
    if not instance is Node3D:
        instance.queue_free()
        return false
    coffee_model = instance as Node3D
    coffee_model.name = "CoffeeShop_majesticmaje"
    # De originele GLB gebruikt Z als hoogte, terwijl Godot Y omhoog heeft.
    # Rotatie -90 graden X zet Z omhoog; de verschuiving brengt de vloer op Y=0.
    coffee_model.rotation_degrees.x = -90.0
    coffee_model.position = Vector3(0.0, -COFFEE_FLOOR_Z, 0.0)
    coffee_root.add_child(coffee_model)

    # Loopbare vloer en randbotsingen; alle maten zijn in ongeschaalde broneenheden.
    # Coffee Shop heeft oorspronkelijke XY-afmetingen 132 x 139 en een Z-vloer op -12.5.
    _static_box(Vector3(2.3, -0.16, -3.2), Vector3(135.0, 0.32, 143.0), coffee_root)
    _static_box(Vector3(-64.3, 17.0, -3.2), Vector3(0.5, 38.0, 143.0), coffee_root)
    _static_box(Vector3(69.3, 17.0, -3.2), Vector3(0.5, 38.0, 143.0), coffee_root)
    _static_box(Vector3(2.3, 17.0, -73.8), Vector3(135.0, 38.0, 0.5), coffee_root)
    _static_box(Vector3(2.3, 17.0, 67.5), Vector3(135.0, 38.0, 0.5), coffee_root)

    # Botsingen op echte muren en grote meubels, zonder honderden kleine versieringen.
    for item in coffee_model.find_children("*", "MeshInstance3D", true, false):
        var mesh := item as MeshInstance3D
        var label: String = mesh.name.to_lower()
        if mesh.mesh != null and (
            label.contains("wall") or label.contains("floor-col") or
            label.contains("counter") or label.contains("couch") or
            label.contains("pooltable") or label.contains("door") or
            label.contains("barstool")
        ):
            mesh.create_trimesh_collision()

    _add_coffee_light(Vector3(-37.0, 27.0, -14.0), Color("ffe4c0"), 0.9, 74.0)
    _add_coffee_light(Vector3(26.0, 26.0, 4.0), Color("ffe7c6"), 0.95, 74.0)
    _add_coffee_light(Vector3(5.0, 26.0, 44.0), Color("d3e4ff"), 0.65, 60.0)
    return true

func _add_coffee_light(at: Vector3, tint: Color, energy: float, radius: float) -> void:
    var light := OmniLight3D.new()
    light.position = at
    light.light_color = tint
    light.light_energy = energy
    light.omni_range = radius * COFFEE_SCALE
    light.shadow_enabled = false
    coffee_root.add_child(light)

func _create_floor_and_edges() -> void:
    # Bronmodel ~9.27 x 9.78 m (x/z), dus groter dan de oude steunvloer.
    # De hele club_root (ook deze statische botsingen) krijgt CLUB_SCALE.
    _static_box(Vector3(0.0, -0.17, 0.0), Vector3(10.0, 0.30, 10.3))
    _static_box(Vector3(-5.07, 3.1, 0), Vector3(0.18, 6.5, 10.3))
    _static_box(Vector3(5.07, 3.1, 0), Vector3(0.18, 6.5, 10.3))
    _static_box(Vector3(0, 3.1, -5.21), Vector3(10.0, 6.5, 0.18))
    _static_box(Vector3(0, 3.1, 5.21), Vector3(10.0, 6.5, 0.18))

func _static_box(at: Vector3, dimensions: Vector3, parent: Node3D = null) -> void:
    var body := StaticBody3D.new()
    body.position = at
    var shape := CollisionShape3D.new()
    var box := BoxShape3D.new()
    box.size = dimensions
    shape.shape = box
    body.add_child(shape)
    if parent == null:
        parent = club_root
    parent.add_child(body)

func _add_nightclub_light(at: Vector3, tint: Color, energy: float, radius: float) -> void:
    var light := OmniLight3D.new()
    light.position = at
    light.light_color = tint
    light.light_energy = energy
    # Houd het bereik gelijk aan de grotere wereld (positie schaalt via club_root).
    light.omni_range = radius * CLUB_SCALE
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

func _set_guest_positions(world_id: String) -> void:
    if visitors == null:
        return
    if old_visitor_positions.is_empty():
        old_visitor_positions = visitors.slot_positions.duplicate()
    if world_id == "night_club":
        var positions: Array[Vector3] = []
        for z in [3.4, 2.5, 1.6, 0.7, -0.2, -1.1, -2.0, -2.9]:
            for x in [-3.0, -2.0, -1.0, 0.0, 1.0, 2.0, 3.0]:
                positions.append(Vector3(x * CLUB_SCALE, 0.15, z * CLUB_SCALE))
        visitors.slot_positions = positions
    elif world_id == "coffee_shop":
        var positions: Array[Vector3] = []
        for z in [5.8, 4.6, 3.4, 2.2, 1.0, -0.2, -1.4, -2.6]:
            for x in [1.3, 3.0, 4.7, 6.4, 8.1, 9.8]:
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
    if current_world_id == "night_club":
        if action == "cafe":
            _teleport(CLUB_SPAWN)
            hud.set_status("Night Club: bij de ingang.")
        elif action == "dance":
            _teleport(CLUB_DANCE)
            hud.set_status("Night Club: dansvloer. Druk F om te dansen.")
        elif action == "radio":
            _teleport(CLUB_DJ)
            hud.set_status("Night Club: DJ-booth.")
    elif current_world_id == "coffee_shop":
        if action == "cafe":
            _teleport(COFFEE_SPAWN)
            hud.set_status("Coffee Shop: bij de ingang.")
        elif action == "dance":
            _teleport(COFFEE_LOUNGE)
            hud.set_status("Coffee Shop: lounge. Druk F om te dansen.")
        elif action == "radio":
            _teleport(COFFEE_COUNTER)
            hud.set_status("Coffee Shop: koffiebar.")

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("reset_position") and not event.is_echo():
        # main.gd still uses the original cafe spawn; override it after that handler.
        if current_world_id == "night_club":
            call_deferred("_teleport", CLUB_SPAWN)
        elif current_world_id == "coffee_shop":
            call_deferred("_teleport", COFFEE_SPAWN)
