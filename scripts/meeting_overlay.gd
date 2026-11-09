extends CanvasLayer
## TeamSpeak Heerlen - Live vergaderkamer (2.5D).
## Geen fictieve gebruikers: uitsluitend gebruikers uit TeamSpeak-roster.
## Bestaande TeamSpeak/voice/PTT-scripts worden niet aangepast.

const AVATAR_SCRIPT = preload("res://scripts/avatar.gd")
const IMAGE_PATH := "res://assets/meeting/meeting_room.png"
const DESIGN_SIZE := Vector2(1672.0, 941.0)
const SERVER := "Heerlen.MIJNTS3.NL"
const INK := Color(0.005, 0.035, 0.07, 0.94)
const BLUE := Color("19a9ff")
const GREEN := Color("4bff8f")
const GOLD := Color("ffd185")
const SEATS := [
    Rect2(670, 310, 180, 232),
    Rect2(350, 326, 164, 252),
    Rect2(213, 387, 178, 286),
    Rect2(75, 460, 203, 316),
    Rect2(1019, 332, 165, 251),
    Rect2(1152, 382, 170, 283),
    Rect2(1238, 442, 127, 289),
    Rect2(705, 594, 180, 242)
]

var game: Node3D
var hud
var voice
var interface_root: Control
var design: Control
var seats_layer: Control
var sidebar: PanelContainer
var online_total: Label
var online_header: Label
var channel_label: Label
var clock_label: Label
var status_text: Label
var connection_label: Label
var roster_rows: VBoxContainer
var channel_rows: VBoxContainer
var connect_button: Button
var ptt_button: Button
var return_button: Button
var connected := false
var members: Dictionary = {}
var assignments: Dictionary = {}
var seat_nodes: Dictionary = {}
var own_id := ""
var own_channel := ""
var talking_id := ""
var talking_until := 0
var show_native_settings := false
var show_3d_world := false
var clock_elapsed := 0.0
var last_ptt := false

func _ready() -> void:
    layer = 30
    call_deferred("_install")

func _install() -> void:
    game = get_parent() as Node3D
    if game == null:
        return
    hud = game.get_node_or_null("CafeHUD")
    voice = game.get_node_or_null("LocalTeamSpeakBridge")
    if hud == null or voice == null:
        push_warning("Vergaderkamer: TeamSpeak/HUD niet gevonden")
        return
    _build_interface()
    _build_return_button()
    get_viewport().size_changed.connect(_fit_to_screen)
    _fit_to_screen()
    voice.roster_updated.connect(_on_roster)
    voice.status_updated.connect(_on_connection)
    voice.voice_active.connect(_on_talking)
    hud.overlay.visibility_changed.connect(_on_native_overlay_changed)
    connected = bool(voice.connected)
    hud.root.visible = false
    _refresh_all()
    print("MEETING_OVERLAY_OK: live vergaderkamer actief")

func _label(value: String, size_px: int, tint: Color) -> Label:
    var lbl := Label.new()
    lbl.text = value
    lbl.add_theme_font_size_override("font_size", size_px)
    lbl.add_theme_color_override("font_color", tint)
    lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
    return lbl

func _panel(bg: Color, edge: Color, radius: int = 12, edge_size: int = 1) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = bg
    box.border_color = edge
    box.border_width_left = edge_size
    box.border_width_top = edge_size
    box.border_width_right = edge_size
    box.border_width_bottom = edge_size
    box.corner_radius_top_left = radius
    box.corner_radius_top_right = radius
    box.corner_radius_bottom_left = radius
    box.corner_radius_bottom_right = radius
    box.content_margin_left = 12
    box.content_margin_right = 12
    box.content_margin_top = 9
    box.content_margin_bottom = 9
    return box

func _action_button(caption: String, action: String, accent: Color) -> Button:
    var button := Button.new()
    button.text = caption
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", Color.WHITE)
    button.add_theme_stylebox_override("normal", _panel(Color(0.005, 0.09, 0.16, 0.96), accent, 11))
    button.add_theme_stylebox_override("hover", _panel(Color(0.03, 0.17, 0.27, 0.99), accent, 11, 2))
    button.add_theme_stylebox_override("pressed", _panel(Color(0.02, 0.24, 0.21, 1.0), accent, 11, 2))
    button.pressed.connect(_handle_action.bind(action))
    return button

func _build_interface() -> void:
    interface_root = Control.new()
    interface_root.name = "MeetingInterface"
    interface_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    interface_root.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(interface_root)
    design = Control.new()
    design.name = "MeetingDesign1672x941"
    design.size = DESIGN_SIZE
    interface_root.add_child(design)

    if ResourceLoader.exists(IMAGE_PATH):
        var photo: Texture2D = load(IMAGE_PATH) as Texture2D
        if photo != null:
            var background := TextureRect.new()
            background.name = "OfficePhoto"
            background.texture = photo
            background.position = Vector2.ZERO
            background.size = DESIGN_SIZE
            background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            background.stretch_mode = TextureRect.STRETCH_SCALE
            background.mouse_filter = Control.MOUSE_FILTER_IGNORE
            design.add_child(background)
    else:
        # Het project moet blijven opstarten, ook als de PNG nog niet is geupload.
        var fallback := ColorRect.new()
        fallback.name = "MissingOfficePhoto"
        fallback.color = Color("162331")
        fallback.size = DESIGN_SIZE
        fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
        design.add_child(fallback)
        var notice := _label("Vergaderkamerachtergrond ontbreekt.\nUpload assets/meeting/meeting_room.png", 27, GOLD)
        notice.position = Vector2(390, 270)
        notice.size = Vector2(850, 90)
        notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        design.add_child(notice)

    var top := PanelContainer.new()
    top.name = "TopBar"
    top.position = Vector2.ZERO
    top.size = Vector2(1672, 75)
    top.add_theme_stylebox_override("panel", _panel(INK, BLUE, 0, 2))
    design.add_child(top)

    var brand := _label("◉ TeamSpeak Heerlen\n    3D Café – Vergadering", 21, Color.WHITE)
    brand.position = Vector2(24, 9)
    brand.size = Vector2(355, 59)
    design.add_child(brand)
    online_total = _label("● Online gebruikers: 0", 21, GREEN)
    online_total.position = Vector2(400, 20)
    online_total.size = Vector2(365, 42)
    design.add_child(online_total)
    channel_label = _label("Kanaal: onbekend", 18, Color("d9edff"))
    channel_label.position = Vector2(794, 22)
    channel_label.size = Vector2(310, 38)
    design.add_child(channel_label)
    var server := _label("Server: " + SERVER, 18, GREEN)
    server.position = Vector2(1116, 23)
    server.size = Vector2(366, 38)
    design.add_child(server)
    clock_label = _label("", 14, Color("cce8ff"))
    clock_label.position = Vector2(1510, 18)
    clock_label.size = Vector2(145, 49)
    clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    design.add_child(clock_label)
    _update_clock()

    seats_layer = Control.new()
    seats_layer.name = "LiveSeatAvatars"
    seats_layer.size = DESIGN_SIZE
    seats_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    design.add_child(seats_layer)

    _build_sidebar()
    _build_bottom_bar()
    status_text = _label("● Offline – alle stoelen zijn leeg", 16, GOLD)
    status_text.position = Vector2(25, 813)
    status_text.size = Vector2(1300, 37)
    design.add_child(status_text)

func _build_sidebar() -> void:
    sidebar = PanelContainer.new()
    sidebar.name = "LiveSidebar"
    sidebar.position = Vector2(1370, 85)
    sidebar.size = Vector2(287, 715)
    sidebar.add_theme_stylebox_override("panel", _panel(INK, BLUE, 16, 2))
    design.add_child(sidebar)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 9)
    sidebar.add_child(body)
    online_header = _label("● Online gebruikers (0)", 19, GREEN)
    body.add_child(online_header)
    body.add_child(HSeparator.new())
    var list_scroll := ScrollContainer.new()
    list_scroll.custom_minimum_size = Vector2(0, 310)
    list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(list_scroll)
    roster_rows = VBoxContainer.new()
    roster_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    roster_rows.add_theme_constant_override("separation", 6)
    list_scroll.add_child(roster_rows)
    body.add_child(HSeparator.new())
    body.add_child(_label("◉ Kanalen (zichtbaar)", 19, Color("c5eaff")))
    var channels_scroll := ScrollContainer.new()
    channels_scroll.custom_minimum_size = Vector2(0, 153)
    body.add_child(channels_scroll)
    channel_rows = VBoxContainer.new()
    channel_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    channels_scroll.add_child(channel_rows)
    connect_button = _action_button("🎙 Verbinden met TeamSpeak", "connect", GREEN)
    body.add_child(connect_button)
    connection_label = _label("Offline", 13, GOLD)
    connection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.add_child(connection_label)

func _build_bottom_bar() -> void:
    var bottom := PanelContainer.new()
    bottom.name = "NavigationBar"
    bottom.position = Vector2(0, 859)
    bottom.size = Vector2(1672, 82)
    bottom.add_theme_stylebox_override("panel", _panel(Color(0.008, 0.034, 0.07, 0.98), BLUE, 0))
    design.add_child(bottom)
    var actions := [
        ["⌂ Vergadering", "home"],
        ["👥 Gebruikers", "users"],
        ["◉ Kanalen", "channels"],
        ["💬 Chat", "chat"],
        ["🎙 PTT", "ptt"],
        ["⚙ Instellingen", "settings"],
        ["▣ 3D Werelden", "worlds"],
        ["⏻ Afsluiten", "exit"]
    ]
    for i in range(actions.size()):
        var action: Array = actions[i]
        var accent: Color = GREEN if i == 0 else (Color("ff7777") if i == 7 else BLUE)
        var button := _action_button(str(action[0]), str(action[1]), accent)
        button.name = "Nav_" + str(action[1])
        button.position = Vector2(20 + i * 206, 877)
        button.size = Vector2(192, 50)
        design.add_child(button)
        if str(action[1]) == "ptt":
            ptt_button = button

func _build_return_button() -> void:
    return_button = _action_button("← Terug naar vergadering", "return", BLUE)
    return_button.name = "ReturnMeetingButton"
    return_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
    return_button.offset_left = -298
    return_button.offset_right = -18
    return_button.offset_top = 18
    return_button.offset_bottom = 68
    return_button.visible = false
    interface_root.add_child(return_button)

func _fit_to_screen() -> void:
    if not is_instance_valid(design):
        return
    var screen: Vector2 = get_viewport().get_visible_rect().size
    if screen.x <= 0.0 or screen.y <= 0.0:
        return
    var factor: float = minf(screen.x / DESIGN_SIZE.x, screen.y / DESIGN_SIZE.y)
    design.scale = Vector2.ONE * factor
    design.position = (screen - DESIGN_SIZE * factor) * 0.5
    if is_instance_valid(return_button):
        return_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
        return_button.offset_left = -298
        return_button.offset_right = -18
        return_button.offset_top = 18
        return_button.offset_bottom = 68

func _on_connection(is_online: bool, message: String) -> void:
    connected = is_online
    if not connected:
        _on_roster([], "", "")
    if is_instance_valid(connection_label):
        connection_label.text = message
    if is_instance_valid(status_text):
        status_text.text = ("● Live TeamSpeak-gebruikers" if connected else "● Offline – alle stoelen zijn leeg")
    _refresh_header()

func _on_roster(users: Array, own_client_id: String, active_channel: String) -> void:
    own_id = own_client_id
    own_channel = active_channel
    var fresh: Dictionary = {}
    for entry in users:
        if typeof(entry) != TYPE_DICTIONARY:
            continue
        var id: String = str(entry.get("id", "")).strip_edges()
        if id.is_empty() or fresh.has(id):
            continue
        var nickname: String = str(entry.get("name", "Onbekend")).strip_edges().substr(0, 60)
        if nickname.is_empty():
            nickname = "Onbekend"
        fresh[id] = {"id": id, "name": nickname, "channel": str(entry.get("channel", ""))}
    for id in members.keys():
        if not fresh.has(id):
            _release_seat(str(id))
    members = fresh
    if not own_id.is_empty() and members.has(own_id) and not assignments.has(own_id):
        _occupy_seat(own_id)
    for id in members.keys():
        if not assignments.has(id):
            _occupy_seat(str(id))
        elif seat_nodes.has(id):
            _update_seat(str(id))
    if not members.has(talking_id):
        talking_id = ""
    _refresh_all()

func _occupy_seat(id: String) -> void:
    if not members.has(id):
        return
    var free_slot := -1
    for slot in range(SEATS.size()):
        if not assignments.values().has(slot):
            free_slot = slot
            break
    if free_slot < 0:
        return
    assignments[id] = free_slot
    _create_seat(id, free_slot)

func _release_seat(id: String) -> void:
    if seat_nodes.has(id):
        var control: Control = seat_nodes[id] as Control
        if is_instance_valid(control):
            control.queue_free()
        seat_nodes.erase(id)
    assignments.erase(id)

func _create_seat(id: String, slot: int) -> void:
    if not is_instance_valid(seats_layer):
        return
    var rect: Rect2 = SEATS[slot]
    var seat := Control.new()
    seat.name = "OccupiedSeat_" + str(slot)
    seat.position = rect.position
    seat.size = rect.size
    seat.mouse_filter = Control.MOUSE_FILTER_IGNORE
    seats_layer.add_child(seat)
    seat_nodes[id] = seat

    var view := SubViewport.new()
    view.name = "SeatedAvatarViewport"
    view.size = Vector2i(maxi(100, int(rect.size.x)), maxi(150, int(rect.size.y - 28)))
    view.transparent_bg = true
    view.own_world_3d = true
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    seat.add_child(view)

    var scene3d := Node3D.new()
    view.add_child(scene3d)
    var camera := Camera3D.new()
    camera.current = true
    camera.fov = 34.0
    camera.position = Vector3(0.0, 1.35, 3.75)
    scene3d.add_child(camera)
    camera.look_at(Vector3(0.0, 1.25, 0.0), Vector3.UP)
    var lamp := DirectionalLight3D.new()
    lamp.rotation_degrees = Vector3(-25, -20, -14)
    lamp.light_energy = 1.8
    scene3d.add_child(lamp)

    var actor = AVATAR_SCRIPT.new()
    actor.name = "R1SeatedVisitor"
    actor.display_name = str(members[id].get("name", "Onbekend"))
    actor.remote_mode = true
    var count: int = AVATAR_SCRIPT.avatar_count()
    if count > 0:
        actor.model_index = posmod(actor.display_name.hash(), count)
        if id == own_id and game != null:
            var cfg: ConfigFile = game.get("profile") as ConfigFile
            if cfg != null:
                var selected: int = int(cfg.get_value("profile", "r1_avatar_index", -1))
                if selected >= 0:
                    actor.model_index = posmod(selected, count)
    scene3d.add_child(actor)
    actor.set_physics_process(false)
    actor.visual.rotation.y = PI
    actor.seated = true
    actor.position.y = -0.27
    actor._play_action("sit")
    if is_instance_valid(actor.label_node):
        actor.label_node.visible = false
    if is_instance_valid(actor.speaking_ring):
        actor.speaking_ring.visible = false

    var portrait := TextureRect.new()
    portrait.name = "LiveR1AvatarPortrait"
    portrait.texture = view.get_texture()
    portrait.position = Vector2(0, 30)
    portrait.size = Vector2(rect.size.x, rect.size.y - 28)
    portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
    seat.add_child(portrait)

    var badge := PanelContainer.new()
    badge.name = "NameBadge"
    badge.position = Vector2(-6, 0)
    badge.size = Vector2(rect.size.x + 12, 37)
    badge.add_theme_stylebox_override("panel", _panel(Color(0, 0.06, 0.07, 0.92), GREEN, 9, 2))
    seat.add_child(badge)
    var label := _label("", 16, Color.WHITE)
    label.name = "RealName"
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.clip_text = true
    badge.add_child(label)
    _update_seat(id)

func _update_seat(id: String) -> void:
    if not seat_nodes.has(id) or not members.has(id):
        return
    var seat: Control = seat_nodes[id] as Control
    if not is_instance_valid(seat):
        return
    var badge: PanelContainer = seat.get_node_or_null("NameBadge") as PanelContainer
    if badge == null:
        return
    var label: Label = badge.get_node_or_null("RealName") as Label
    var nickname: String = str(members[id].get("name", "Onbekend"))
    var active: bool = id == talking_id and Time.get_ticks_msec() < talking_until
    if label != null:
        label.text = ("🎙 " if active else "● ") + nickname
        label.tooltip_text = nickname
        label.add_theme_color_override("font_color", GOLD if active else Color.WHITE)
    badge.add_theme_stylebox_override("panel", _panel(Color(0.005, 0.07, 0.09, 0.93), GOLD if active else GREEN, 9, 2))

func _clear_ui(node: Node) -> void:
    for child in node.get_children():
        node.remove_child(child)
        child.queue_free()

func _refresh_all() -> void:
    _refresh_header()
    _refresh_users()
    _refresh_channels()
    for id in seat_nodes.keys():
        _update_seat(str(id))

func _refresh_header() -> void:
    if is_instance_valid(online_total):
        online_total.text = "● Online gebruikers: " + str(members.size())
    if is_instance_valid(online_header):
        online_header.text = "● Online gebruikers (" + str(members.size()) + ")"
    if is_instance_valid(channel_label):
        var active_name: String = own_channel
        if hud != null and not str(hud.current_channel).strip_edges().is_empty():
            active_name = str(hud.current_channel)
        channel_label.text = "Kanaal: " + (active_name if not active_name.is_empty() else "onbekend")
    if is_instance_valid(connect_button):
        connect_button.text = "● TeamSpeak verbreken" if connected else "🎙 Verbinden met TeamSpeak"

func _refresh_users() -> void:
    if not is_instance_valid(roster_rows):
        return
    _clear_ui(roster_rows)
    if members.is_empty():
        roster_rows.add_child(_label("Geen online gebruikers zichtbaar", 14, Color("adbed1")))
        return
    for id in members.keys():
        var nickname: String = str(members[id].get("name", "Onbekend"))
        var suffix := " (jij)" if id == own_id else ""
        var active: bool = id == talking_id and Time.get_ticks_msec() < talking_until
        var label := _label(("🎙 " if active else "● ") + nickname + suffix, 14, GOLD if active else Color("e8f8ff"))
        label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        roster_rows.add_child(label)
    if members.size() > SEATS.size():
        roster_rows.add_child(_label("Extra leden alleen in de lijst: 8 stoelen in beeld.", 12, GOLD))

func _refresh_channels() -> void:
    if not is_instance_valid(channel_rows):
        return
    _clear_ui(channel_rows)
    if not connected:
        channel_rows.add_child(_label("Verbind eerst met TeamSpeak.", 13, Color("abbcd2")))
        return
    var counts: Dictionary = {}
    for id in members.keys():
        var channel_id: String = str(members[id].get("channel", ""))
        if not channel_id.is_empty():
            counts[channel_id] = int(counts.get(channel_id, 0)) + 1
    if counts.is_empty():
        channel_rows.add_child(_label("Geen kanaalinformatie beschikbaar", 13, Color("abbcd2")))
    else:
        for channel_id in counts.keys():
            var title: String = "Kanaal ID " + str(channel_id)
            if str(channel_id) == own_channel and hud != null and not str(hud.current_channel).is_empty():
                title = str(hud.current_channel)
            channel_rows.add_child(_label("◉ " + title + " (" + str(counts[channel_id]) + ")", 13, Color("dbedff")))
    channel_rows.add_child(_label("Alleen kanalen uit de live gebruikerslijst.", 11, Color("8fa7bd")))

func _on_talking(client_id: String) -> void:
    if client_id.is_empty() or not members.has(client_id):
        return
    talking_id = client_id
    talking_until = Time.get_ticks_msec() + 1250
    for id in seat_nodes.keys():
        _update_seat(str(id))
    _refresh_users()

func _update_clock() -> void:
    if not is_instance_valid(clock_label):
        return
    var stamp: Dictionary = Time.get_datetime_dict_from_system()
    clock_label.text = "%02d:%02d:%02d\n%02d-%02d-%04d" % [
        int(stamp.get("hour", 0)), int(stamp.get("minute", 0)), int(stamp.get("second", 0)),
        int(stamp.get("day", 0)), int(stamp.get("month", 0)), int(stamp.get("year", 0))
    ]

func _process(delta: float) -> void:
    clock_elapsed += delta
    if clock_elapsed >= 1.0:
        clock_elapsed = 0.0
        _update_clock()
    if not talking_id.is_empty() and Time.get_ticks_msec() >= talking_until:
        talking_id = ""
        for id in seat_nodes.keys():
            _update_seat(str(id))
        _refresh_users()
    if is_instance_valid(ptt_button) and voice != null:
        var active: bool = bool(voice.ptt)
        if active != last_ptt:
            last_ptt = active
            ptt_button.text = "🎙 PTT AAN" if active else "🎙 PTT"
            ptt_button.add_theme_stylebox_override("normal", _panel(Color(0.02, 0.22, 0.13) if active else Color(0.005, 0.09, 0.16), GREEN if active else BLUE, 11, 2))

func _handle_action(action: String) -> void:
    match action:
        "connect":
            hud.action_requested.emit("teamspeak")
        "home":
            status_text.text = "● Vergaderkamer: uitsluitend echte TeamSpeak-gebruikers"
        "users":
            sidebar.visible = not sidebar.visible
        "channels":
            _open_native_panel("settings", true)
        "chat":
            _open_native_panel("chat")
        "ptt":
            hud.action_requested.emit("ptt")
        "settings":
            _open_native_panel("settings")
        "worlds":
            _show_world()
        "return":
            _return_from_world()
        "exit":
            get_tree().quit()

func _open_native_panel(panel: String, select_teamspeak: bool = false) -> void:
    if hud == null:
        return
    show_native_settings = false
    show_3d_world = false
    hud.root.visible = true
    hud.show_panel(panel)
    if panel == "settings" and select_teamspeak:
        hud._show_settings_tab("teamspeak")
    show_native_settings = true
    interface_root.visible = false

func _on_native_overlay_changed() -> void:
    if not show_native_settings or hud == null:
        return
    if not hud.overlay.visible:
        show_native_settings = false
        hud.root.visible = false
        interface_root.visible = true
        return_button.visible = false
        _fit_to_screen()

func _show_world() -> void:
    if hud == null:
        return
    show_native_settings = false
    show_3d_world = true
    design.visible = false
    return_button.visible = true
    hud.root.visible = true
    hud.overlay.visible = false

func _return_from_world() -> void:
    show_3d_world = false
    design.visible = true
    return_button.visible = false
    if hud != null:
        hud.root.visible = false
    _fit_to_screen()
