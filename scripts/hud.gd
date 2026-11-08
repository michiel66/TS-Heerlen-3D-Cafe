extends CanvasLayer
## UI naar de conceptfoto: gebruikerspaneel, minikaart en navigatiebalk.
## De online-lijst is bewust geen verzonnen TeamSpeak-livefeed.

signal action_requested(action: String)
signal nickname_changed(value: String)
signal channel_changed(value: String)

const MINIMAP_SCRIPT = preload("res://scripts/minimap.gd")
var avatar: Node3D
var nickname: String = "Bezoeker"
var current_channel: String = ""
var ts_connected := false
var live_users: Array = []
var avatar_count := 0
var avatars_line: Label
var talker_id := ""
var talker_deadline := 0
var connect_button: Button
var users_preview: Label
var channel_entry: LineEdit
var root: Control
var online_label: Label
var status_label: Label
var overlay: PanelContainer
var overlay_title: Label
var overlay_text: Label
var chat_entry: LineEdit
var nickname_entry: LineEdit

func _ready() -> void:
    root = Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    root.mouse_filter = Control.MOUSE_FILTER_PASS
    add_child(root)
    _top_left()
    _top_right()
    _bottom_bar()
    _status_area()
    _overlay()

func _panel(color: Color, radius: int = 14, border: Color = Color(0.30,0.26,0.23,0.8)) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.border_color = border
    style.content_margin_left = 12
    style.content_margin_right = 12
    style.content_margin_top = 10
    style.content_margin_bottom = 10
    return style

func _lbl(text: String, size: int, color: Color = Color("ffffff")) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", size)
    l.add_theme_color_override("font_color", color)
    return l

func _top_left() -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel(Color(0.035,0.044,0.052,0.88)))
    panel.position = Vector2(18, 18)
    panel.custom_minimum_size = Vector2(245, 0)
    root.add_child(panel)
    var vertical := VBoxContainer.new()
    vertical.add_theme_constant_override("separation", 8)
    panel.add_child(vertical)
    online_label = _lbl("●  TEAMSPEAK OFFLINE", 17, Color("ffb577"))
    vertical.add_child(online_label)
    vertical.add_child(HSeparator.new())
    vertical.add_child(_lbl("•  " + nickname + " (jij)", 16, Color("f3f1ef")))
    avatars_line = _lbl("3D avatars: nog niet verbonden", 12, Color("a1ffb9"))
    vertical.add_child(avatars_line)
    users_preview = _lbl("Nog geen live TS3-gebruikers", 13, Color("eeeeee"))
    users_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    vertical.add_child(users_preview)
    connect_button = Button.new()
    connect_button.text = "🎙 VERBIND MET TEAMSPEAK"
    connect_button.add_theme_font_size_override("font_size", 13)
    connect_button.pressed.connect(func() -> void: action_requested.emit("teamspeak"))
    vertical.add_child(connect_button)

func _top_right() -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel(Color(0.035,0.044,0.052,0.91), 120))
    panel.anchor_left = 1.0
    panel.anchor_right = 1.0
    panel.offset_left = -240
    panel.offset_right = -20
    panel.offset_top = 18
    panel.offset_bottom = 238
    root.add_child(panel)
    var m = MINIMAP_SCRIPT.new()
    m.avatar = avatar
    m.custom_minimum_size = Vector2(194, 194)
    panel.add_child(m)

func _bottom_bar() -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel(Color(0.035,0.042,0.047,0.93), 19, Color(0.73,0.72,0.70,0.9)))
    panel.anchor_left = 0.0
    panel.anchor_right = 1.0
    panel.anchor_top = 1.0
    panel.anchor_bottom = 1.0
    panel.offset_left = 8
    panel.offset_right = -8
    panel.offset_top = -75
    panel.offset_bottom = -8
    root.add_child(panel)
    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 4)
    panel.add_child(row)
    var entries := [
        ["💬 Chat (F2)", "chat"], ["🎙 Praten (PTT)", "ptt"],
        ["👥 Gebruikers", "users"], ["▣ Locaties", "locations"],
        ["⌂ Café", "cafe"], ["♫ Dansvloer", "dance"],
        ["📻 Radio", "radio"], ["ⓘ Info", "info"], ["⚙ Instellingen", "settings"]
    ]
    for entry in entries:
        var btn := Button.new()
        btn.text = entry[0]
        btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        btn.focus_mode = Control.FOCUS_NONE
        btn.add_theme_font_size_override("font_size", 13)
        if entry[1] == "cafe":
            btn.add_theme_color_override("font_color", Color("ffb46d"))
        btn.pressed.connect(_button_action.bind(entry[1]))
        row.add_child(btn)
    var server := _lbl("● Heerlen.MIJNTS3.NL", 14, Color("93efbd"))
    server.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    row.add_child(server)

func _status_area() -> void:
    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel(Color(0.035, 0.04, 0.048, 0.78)))
    panel.anchor_left = 0.0
    panel.anchor_right = 0.0
    panel.anchor_top = 1.0
    panel.anchor_bottom = 1.0
    panel.offset_left = 18
    panel.offset_right = 405
    panel.offset_top = -163
    panel.offset_bottom = -82
    root.add_child(panel)
    var box := VBoxContainer.new()
    panel.add_child(box)
    box.add_child(_lbl("WASD bewegen  |  Rechtsklik + muis draaien", 13, Color("eeeeee")))
    box.add_child(_lbl("E zitten  |  F dansen  |  R terug naar start", 12, Color("d5d0cb")))
    status_label = _lbl("Welkom bij TeamSpeak Heerlen 3D Café", 13, Color("ffc186"))
    box.add_child(status_label)

func _overlay() -> void:
    overlay = PanelContainer.new()
    overlay.add_theme_stylebox_override("panel", _panel(Color(0.075, 0.085, 0.10, 0.97), 17))
    overlay.anchor_left = 0.5
    overlay.anchor_right = 0.5
    overlay.anchor_top = 0.5
    overlay.anchor_bottom = 0.5
    overlay.offset_left = -290
    overlay.offset_right = 290
    overlay.offset_top = -190
    overlay.offset_bottom = 160
    overlay.visible = false
    root.add_child(overlay)
    var body := VBoxContainer.new()
    body.add_theme_constant_override("separation", 14)
    overlay.add_child(body)
    var header := HBoxContainer.new()
    body.add_child(header)
    overlay_title = _lbl("Info", 23, Color("ffbb78"))
    overlay_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(overlay_title)
    var close := Button.new()
    close.text = "✕"
    close.pressed.connect(func() -> void: overlay.visible = false)
    header.add_child(close)
    overlay_text = _lbl("", 17, Color("e9e6e4"))
    overlay_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    overlay_text.custom_minimum_size = Vector2(0, 120)
    overlay_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    var roster_scroll := ScrollContainer.new()
    roster_scroll.custom_minimum_size = Vector2(0, 130)
    roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(roster_scroll)
    roster_scroll.add_child(overlay_text)
    nickname_entry = LineEdit.new()
    nickname_entry.placeholder_text = "Jouw naam"
    nickname_entry.text = nickname
    nickname_entry.visible = false
    body.add_child(nickname_entry)
    var save := Button.new()
    save.text = "Naam opslaan"
    save.visible = false
    save.pressed.connect(_save_nickname)
    body.add_child(save)
    nickname_entry.set_meta("save_button", save)
    channel_entry = LineEdit.new()
    channel_entry.placeholder_text = "TeamSpeak-kanaal (leeg = standaardkanaal)"
    channel_entry.text = current_channel
    channel_entry.visible = false
    body.add_child(channel_entry)
    chat_entry = LineEdit.new()
    chat_entry.placeholder_text = "Lokale notitie typen (geen chatbericht naar anderen)"
    chat_entry.visible = false
    chat_entry.text_submitted.connect(_chat_submitted)
    body.add_child(chat_entry)

func _button_action(action: String) -> void:
    if action in ["cafe", "dance", "radio", "teamspeak", "ptt"]:
        overlay.visible = false
        action_requested.emit(action)
        return
    show_panel(action)

func _save_nickname() -> void:
    var fresh := nickname_entry.text.strip_edges().substr(0, 24)
    if fresh.is_empty():
        set_status("Typ eerst een gebruikersnaam.")
        return
    nickname = fresh
    nickname_changed.emit(fresh)
    current_channel = channel_entry.text.strip_edges().substr(0, 120)
    channel_changed.emit(current_channel)
    set_status("Naam ingesteld: " + fresh)
    overlay.visible = false

func _chat_submitted(text: String) -> void:
    var message := text.strip_edges()
    if not message.is_empty():
        set_status("Lokale notitie: " + message.substr(0, 80))
        overlay_text.text = "Lokale notitie opgeslagen in de statusregel.\nDit bericht wordt niet naar andere gebruikers verstuurd."
    chat_entry.clear()

func show_panel(action: String) -> void:
    overlay.visible = true
    chat_entry.visible = false
    nickname_entry.visible = false
    channel_entry.visible = false
    (nickname_entry.get_meta("save_button") as Button).visible = false
    match action:
        "chat":
            overlay_title.text = "Lokale chat / notities"
            overlay_text.text = "In deze eerste versie is er nog geen gedeelde tekstchat.\nGebruik het tekstvak voor een lokale notitie.\nSpraak loopt via de ingebouwde TeamSpeak-module."
            chat_entry.visible = true
            chat_entry.grab_focus()
        "ptt":
            overlay_title.text = "Push-to-talk"
            overlay_text.text = "Houd V ingedrukt om te praten als je verbonden bent.\nDe PTT-knop in de onderbalk schakelt de microfoon aan/uit.\nGebruik een headset om terugkoppeling te voorkomen."
        "users":
            overlay_title.text = "Live TeamSpeak-gebruikers"
            overlay_text.text = _roster_text()
        "locations":
            overlay_title.text = "Locaties"
            overlay_text.text = "Café: koffiebar en zitplaatsen.\nDansvloer: verlichte danshoek achterin.\nRadiohoek: 27MC en TeamSpeak-presentatie.\n\nKlik de knoppen onderaan om te lopen naar een andere plek."
        "settings":
            overlay_title.text = "TeamSpeak-instellingen"
            overlay_text.text = "Stel je gebruikersnaam en optioneel een TS3-kanaalnaam in. Wijzigingen gelden na opnieuw verbinden."
            nickname_entry.visible = true
            channel_entry.visible = true
            (nickname_entry.get_meta("save_button") as Button).visible = true
        _:
            overlay_title.text = "TeamSpeak Heerlen 3D Café"
            overlay_text.text = "Godot 3D-café met een ingebouwde, lokale TeamSpeak-client via PTT-Crosslink-techniek.\nLive TeamSpeak-leden krijgen nu hun eigen avatar in het café.\nDe posities zijn vaste weergaveplekken: lopen van andere gebruikers wordt nog niet gesynchroniseerd."

func set_status(text: String) -> void:
    if is_instance_valid(status_label):
        status_label.text = text

func set_nickname(name_value: String) -> void:
    nickname = name_value
    if is_instance_valid(nickname_entry):
        nickname_entry.text = name_value
    if is_instance_valid(online_label):
        online_label.text = "●  AANWEZIG: 1 LOKAAL"

func set_ts_status(is_online: bool, message: String) -> void:
    ts_connected = is_online
    if is_instance_valid(connect_button):
        connect_button.text = "● VERBREEK TEAMSPEAK" if is_online else "🎙 VERBIND MET TEAMSPEAK"
    if is_instance_valid(online_label):
        online_label.text = ("● TS3 ONLINE" if is_online else "● TS3 OFFLINE") + " · " + str(live_users.size()) + " gebruikers"
        online_label.add_theme_color_override("font_color", Color("7ff4a4") if is_online else Color("ffb577"))
    set_status(message)
    set_avatar_count(avatar_count if is_online else 0)

func set_avatar_count(count: int) -> void:
    avatar_count = count
    if is_instance_valid(avatars_line):
        avatars_line.text = "3D-bezoekers: " + str(count) + " (+ jijzelf)" if ts_connected else "3D avatars: niet verbonden"
    if is_instance_valid(overlay) and overlay.visible and overlay_title.text == "Live TeamSpeak-gebruikers":
        overlay_text.text = _roster_text()

func set_live_roster(users: Array) -> void:
    live_users = users
    if is_instance_valid(online_label):
        online_label.text = ("● TS3 ONLINE" if ts_connected else "● TS3 OFFLINE") + " · " + str(users.size()) + " gebruikers"
    if is_instance_valid(users_preview):
        var names: Array[String] = []
        for u in users.slice(0, 10):
            if typeof(u) == TYPE_DICTIONARY:
                names.append("● " + str(u.get("name", "Onbekend")))
        if users.size() > 10:
            names.append("+ " + str(users.size() - 10) + " andere gebruikers (klik Gebruikers)")
        users_preview.text = "\n".join(names) if not names.is_empty() else "Geen gebruikerslijst beschikbaar"
    if is_instance_valid(overlay) and overlay.visible and overlay_title.text == "Live TeamSpeak-gebruikers":
        overlay_text.text = _roster_text()

func _roster_text() -> String:
    var names: Array[String] = []
    for u in live_users:
        if typeof(u) == TYPE_DICTIONARY:
            var marker := "🎙 " if str(u.get("id","")) == talker_id else "• "
            names.append(marker + str(u.get("name", "Onbekend")))
    if names.is_empty():
        return "Nog geen serverleden beschikbaar. Verbind eerst met TeamSpeak Heerlen."
    return "TeamSpeak-server: Heerlen.MIJNTS3.NL\nOnline: " + str(live_users.size()) + " · Zichtbare 3D-bezoekers: " + str(avatar_count) + "\n\n" + "\n".join(names)

func set_live_talker(id: String) -> void:
    talker_id = id
    talker_deadline = Time.get_ticks_msec() + 1100
    if is_instance_valid(overlay) and overlay.visible and overlay_title.text == "Live TeamSpeak-gebruikers":
        overlay_text.text = _roster_text()

func set_ptt_state(active: bool) -> void:
    if active:
        set_status("🎙 PTT AAN – je microfoon wordt uitgezonden")
    elif ts_connected:
        set_status("PTT UIT – druk V om te praten, of gebruik de PTT-knop")

func _process(_delta: float) -> void:
    if not talker_id.is_empty() and Time.get_ticks_msec() > talker_deadline:
        talker_id = ""
        if is_instance_valid(overlay) and overlay.visible and overlay_title.text == "Live TeamSpeak-gebruikers":
            overlay_text.text = _roster_text()
