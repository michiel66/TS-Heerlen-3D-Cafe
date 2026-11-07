extends Node3D
## TeamSpeak Heerlen 3D Café – Windows prototype v0.2.1 — herstel leeg scherm
## 3D werkt lokaal. TeamSpeak wordt extern geopend met ts3server://.

const WORLD_SCRIPT = preload("res://scripts/world.gd")
const AVATAR_SCRIPT = preload("res://scripts/avatar.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")
const BRIDGE_SCRIPT = preload("res://scripts/teamspeak_bridge.gd")

var player
var camera: Camera3D
var hud
var yaw := -0.30
var pitch := 0.22
var zoom := 5.2
var mouse_turning := false
var profile := ConfigFile.new()
var voice
var current_channel := ""

func _ready() -> void:
    var nick := "Bezoeker"
    if profile.load("user://cafe_profiel.cfg") == OK:
        nick = str(profile.get_value("profile", "nickname", nick))
    current_channel = str(profile.get_value("profile", "channel", ""))
    var cafe = WORLD_SCRIPT.new()
    cafe.name = "CafeWorld"
    add_child(cafe)
    player = AVATAR_SCRIPT.new()
    player.display_name = nick
    player.name = "LocalAvatar"
    add_child(player)
    player.global_position = Vector3(2.3, 0.15, 5.8)
    camera = Camera3D.new()
    camera.name = "MainCamera"
    camera.current = true
    camera.fov = 65.0
    add_child(camera)
    _update_camera(1.0)
    hud = HUD_SCRIPT.new()
    hud.name = "CafeHUD"
    hud.avatar = player
    hud.nickname = nick
    hud.current_channel = current_channel
    add_child(hud)
    voice = BRIDGE_SCRIPT.new()
    voice.name = "LocalTeamSpeakBridge"
    add_child(voice)
    voice.status_updated.connect(_voice_status)
    voice.roster_updated.connect(_voice_roster)
    voice.voice_active.connect(_voice_talking)
    hud.action_requested.connect(_ui_action)
    hud.nickname_changed.connect(_update_nickname)
    hud.channel_changed.connect(_update_channel)
    # Verberg het fout-/startscherm pas nadat camera, wereld en HUD zijn aangemaakt.
    var boot: CanvasLayer = get_node_or_null("BootScreen") as CanvasLayer
    if boot != null:
        boot.visible = false
    print("TS HEERLEN START OK: 3D wereld, camera, speler, HUD aanwezig")

func _process(delta: float) -> void:
    if is_instance_valid(player):
        player.camera_heading = yaw
        _update_camera(delta)

func _update_camera(delta: float) -> void:
    var target: Vector3 = player.global_position + Vector3(0.0, 1.36, 0.0)
    var horizontal := Vector3(sin(yaw), 0.0, cos(yaw)) * zoom
    var desired := target + horizontal + Vector3(0.0, 1.48 + pitch * 3.5, 0.0)
    camera.global_position = camera.global_position.lerp(desired, clampf(delta * 8.0, 0.0, 1.0))
    camera.look_at(target, Vector3.UP)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_RIGHT:
            mouse_turning = event.pressed
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
            zoom = maxf(2.8, zoom - 0.4)
        elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
            zoom = minf(9.0, zoom + 0.4)
    elif event is InputEventMouseMotion and mouse_turning:
        yaw -= event.relative.x * 0.005
        pitch = clampf(pitch + event.relative.y * 0.004, -0.5, 0.55)
    if event is InputEventKey and not event.echo and event.physical_keycode == KEY_V:
        voice.set_ptt(event.pressed)
        hud.set_ptt_state(voice.ptt)
    if event.is_action_pressed("interact") and not event.is_echo():
        _interact()
    elif event.is_action_pressed("emote") and not event.is_echo():
        var active: bool = player.toggle_dance()
        hud.set_status("Je danst!" if active else "Je bent gestopt met dansen.")
    elif event.is_action_pressed("reset_position") and not event.is_echo():
        player.seated = false
        player.dancing = false
        player.global_position = Vector3(2.3, 0.15, 5.8)
        hud.set_status("Terug bij de ingang.")
    elif event.is_action_pressed("chat") and not event.is_echo():
        hud.show_panel("chat")

func _interact() -> void:
    if player.seated:
        player.stand_up()
        hud.set_status("Je bent opgestaan.")
        return
    var closest: Node3D
    var best := 1.65
    for node in get_tree().get_nodes_in_group("cafe_seats"):
        var seat: Node3D = node
        var d: float = player.global_position.distance_to(seat.global_position)
        if d < best:
            best = d
            closest = seat
    if closest != null:
        player.sit_at(closest)
        hud.set_status("Je zit aan een tafeltje. Druk E om op te staan.")
    else:
        hud.set_status("Loop dichter naar een stoel en druk E.")

func _ui_action(action: String) -> void:
    match action:
        "teamspeak":
            if voice.connected:
                voice.disconnect_teamspeak()
                hud.set_status("TeamSpeak-verbinding wordt verbroken.")
            else:
                voice.connect_teamspeak(hud.nickname, hud.current_channel)
        "ptt":
            voice.set_ptt(not voice.ptt)
            hud.set_ptt_state(voice.ptt)
        "cafe":
            _teleport(Vector3(2.3, 0.15, 5.8), "Welkom terug in het café.")
        "dance":
            _teleport(Vector3(-0.8, 0.15, -6.7), "Je bent op de dansvloer. Druk F om te dansen.")
        "radio":
            _teleport(Vector3(9.5, 0.15, -6.9), "Radiohoek: 27MC, Zello en TeamSpeak.")

func _teleport(pos: Vector3, text: String) -> void:
    if player.seated:
        player.stand_up()
    player.dancing = false
    player.velocity = Vector3.ZERO
    player.global_position = pos
    hud.set_status(text)

func _update_nickname(new_name: String) -> void:
    player.display_name = new_name
    for node in player.get_children():
        if node is Label3D:
            (node as Label3D).text = new_name
    profile.set_value("profile", "nickname", new_name)
    profile.save("user://cafe_profiel.cfg")

func _voice_status(is_connected: bool, message: String) -> void:
    hud.set_ts_status(is_connected, message)
    hud.set_status(message)
    if not is_connected:
        hud.set_ptt_state(false)

func _voice_roster(users: Array) -> void:
    hud.set_live_roster(users)

func _voice_talking(id: String) -> void:
    hud.set_live_talker(id)

func _update_channel(name_value: String) -> void:
    current_channel = name_value
    profile.set_value("profile", "channel", current_channel)
    profile.save("user://cafe_profiel.cfg")
    hud.set_status("Kanaal opgeslagen. Verbreek en verbind opnieuw om te wisselen.")
