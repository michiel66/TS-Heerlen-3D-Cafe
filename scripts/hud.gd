extends CanvasLayer
## UI naar de conceptfoto: gebruikerspaneel, minikaart en navigatiebalk.
## De online-lijst is bewust geen verzonnen TeamSpeak-livefeed.

signal action_requested(action: String)
signal nickname_changed(value: String)
signal channel_changed(value: String)
signal avatar_selected(index: int)

const R1_CATALOG = preload("res://scripts/r1_avatar_catalog.gd")

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
var avatar_selector: OptionButton
var avatar_detail: Label
var settings_tabs: HBoxContainer
var profile_form: VBoxContainer
var teamspeak_form: VBoxContainer
var overlay_scroll: ScrollContainer

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
    overlay.offset_top = -260
    overlay.offset_bottom = 260
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
    overlay_scroll = ScrollContainer.new()
    overlay_scroll.custom_minimum_size = Vector2(0, 130)
    overlay_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_child(overlay_scroll)
    overlay_scroll.add_child(overlay_text)

    settings_tabs = HBoxContainer.new()
    settings_tabs.visible = false
    settings_tabs.add_theme_constant_override("separation", 8)
    body.add_child(settings_tabs)
    var profile_tab := Button.new()
    profile_tab.text = "👤 Profiel"
    profile_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    profile_tab.pressed.connect(_show_settings_tab.bind("profile"))
    settings_tabs.add_child(profile_tab)
    var teamspeak_tab := Button.new()
    teamspeak_tab.text = "🎙 TeamSpeak"
    teamspeak_tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    teamspeak_tab.pressed.connect(_show_settings_tab.bind("teamspeak"))
    settings_tabs.add_child(teamspeak_tab)

    profile_form = VBoxContainer.new()
    profile_form.visible = false
    profile_form.add_theme_constant_override("separation", 8)
    body.add_child(profile_form)
    profile_form.add_child(_lbl("Gebruikersnaam", 14, Color("ffbb78")))
    nickname_entry = LineEdit.new()
    nickname_entry.placeholder_text = "Jouw naam"
    nickname_entry.text = nickname
    profile_form.add_child(nickname_entry)
    var save := Button.new()
    save.text = "Profielnaam opslaan"
    save.pressed.connect(_save_nickname)
    profile_form.add_child(save)
    nickname_entry.set_meta("save_button", save)

    profile_form.add_child(HSeparator.new())
    profile_form.add_child(_lbl("Kies jouw 3D-avatar · 100Avatars R1", 15, Color("ffbb78")))
    var avatar_row := HBoxContainer.new()
    avatar_row.add_theme_constant_override("separation", 8)
    profile_form.add_child(avatar_row)
    var prev := Button.new()
    prev.text = "◀"
    prev.tooltip_text = "Vorige avatar"
    prev.pressed.connect(_cycle_profile_avatar.bind(-1))
    avatar_row.add_child(prev)
    avatar_selector = OptionButton.new()
    avatar_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    avatar_selector.item_selected.connect(_avatar_option_changed)
    avatar_row.add_child(avatar_selector)
    var nxt := Button.new()
    nxt.text = "▶"
    nxt.tooltip_text = "Volgende avatar"
    nxt.pressed.connect(_cycle_profile_avatar.bind(1))
    avatar_row.add_child(nxt)
    avatar_detail = _lbl("", 13, Color("a1ffb9"))
    avatar_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    profile_form.add_child(avatar_detail)
    var avatar_hint := _lbl("Keuze direct zichtbaar in het café en automatisch bewaard op deze pc.", 12, Color("d5d0cb"))
    avatar_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    profile_form.add_child(avatar_hint)
    _populate_avatar_selector()

    teamspeak_form = VBoxContainer.new()
    teamspeak_form.visible = false
    teamspeak_form.add_theme_constant_override("separation", 9)
    body.add_child(teamspeak_form)
    teamspeak_form.add_child(_lbl("TeamSpeak-kanaal", 15, Color("ffbb78")))
    channel_entry = LineEdit.new()
    channel_entry.placeholder_text = "TeamSpeak-kanaal (leeg = standaardkanaal)"
    channel_entry.text = current_channel
    teamspeak_form.add_child(channel_entry)
    var save_channel := Button.new()
    save_channel.text = "TeamSpeak-kanaal opslaan"
    save_channel.pressed.connect(_save_channel)
    teamspeak_form.add_child(save_channel)
    var channel_hint := _lbl("Kanaalwijzigingen gelden na opnieuw verbinden.", 13, Color("d5d0cb"))
    teamspeak_form.add_child(channel_hint)

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
    set_status("Naam ingesteld: " + fresh)
    overlay.visible = false

func _save_channel() -> void:
    current_channel = channel_entry.text.strip_edges().substr(0, 120)
    channel_changed.emit(current_channel)
    set_status("TeamSpeak-kanaal opgeslagen. Verbind opnieuw om te wisselen.")
    overlay.visible = false

func _avatar_name(index: int) -> String:
    if index < 0 or index >= R1_CATALOG.AVATARS.size():
        return "Onbekend"
    var raw: String = R1_CATALOG.AVATARS[index].get_file().get_basename()
    var parts: PackedStringArray = raw.split("_")
    if parts.size() > 2:
        return " ".join(parts.slice(2))
    return raw.replace("_", " ")

func _populate_avatar_selector() -> void:
    avatar_selector.clear()
    for index in range(R1_CATALOG.AVATARS.size()):
        avatar_selector.add_item("%03d  ·  %s" % [index + 1, _avatar_name(index)], index)
    if avatar_selector.item_count == 0:
        avatar_selector.add_item("Geen R1-modellen gevonden", -1)
        avatar_selector.disabled = true
        avatar_detail.text = "De R1-collectie is nog niet geimporteerd."
        return
    avatar_selector.disabled = false
    if is_instance_valid(avatar) and avatar.has_method("avatar_count"):
        set_avatar_selection(int(avatar.model_index))
    else:
        set_avatar_selection(0)

func set_avatar_selection(index: int) -> void:
    if not is_instance_valid(avatar_selector) or avatar_selector.disabled:
        return
    var total: int = R1_CATALOG.AVATARS.size()
    if total == 0:
        return
    var selected: int = posmod(index, total)
    avatar_selector.select(selected)
    avatar_detail.text = "Avatar %d van %d — %s" % [selected + 1, total, _avatar_name(selected)]

func _avatar_option_changed(index: int) -> void:
    var selected: int = avatar_selector.get_item_id(index)
    if selected >= 0:
        set_avatar_selection(selected)
        avatar_selected.emit(selected)

func _cycle_profile_avatar(direction: int) -> void:
    if not is_instance_valid(avatar_selector) or avatar_selector.disabled:
        set_status("Geen R1-avatars beschikbaar.")
        return
    var next_index: int = posmod(avatar_selector.selected + direction, R1_CATALOG.AVATARS.size())
    _avatar_option_changed(next_index)

func _show_settings_tab(tab: String) -> void:
    var is_profile := tab == "profile"
    overlay_title.text = "Instellingen · Profiel" if is_profile else "Instellingen · TeamSpeak"
    overlay_scroll.custom_minimum_size = Vector2(0, 50)
    overlay_text.custom_minimum_size = Vector2(0, 42)
    profile_form.visible = is_profile
    teamspeak_form.visible = not is_profile
    overlay_text.text = (
        "Kies je eigen R1-avatar en wijzig je gebruikersnaam." if is_profile else
        "Stel hier het TeamSpeak-kanaal in. De bestaande audio/PTT blijft hetzelfde."
    )
    if is_profile and is_instance_valid(avatar):
        set_avatar_selection(int(avatar.model_index))

func _chat_submitted(text: String) -> void:
    var message := text.strip_edges()
    if not message.is_empty():
        set_status("Lokale notitie: " + message.substr(0, 80))
        overlay_text.text = "Lokale notitie opgeslagen in de statusregel.\nDit bericht wordt niet naar andere gebruikers verstuurd."
    chat_entry.clear()

func show_panel(action: String) -> void:
    overlay.visible = true
    chat_entry.visible = false
    settings_tabs.visible = false
    profile_form.visible = false
    teamspeak_form.visible = false
    overlay_scroll.custom_minimum_size = Vector2(0, 130)
    overlay_text.custom_minimum_size = Vector2(0, 120)
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
            settings_tabs.visible = true
            _show_settings_tab("profile")
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
