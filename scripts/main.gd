extends Node3D
## TeamSpeak Heerlen 3D Café – Windows prototype v0.1
## 3D werkt lokaal. TeamSpeak wordt extern geopend met ts3server://.

const WORLD_SCRIPT = preload("res://scripts/world.gd")
const AVATAR_SCRIPT = preload("res://scripts/avatar.gd")
const HUD_SCRIPT = preload("res://scripts/hud.gd")
const SERVER_URI := "ts3server://Heerlen.MIJNTS3.NL"

var player
var camera: Camera3D
var hud
var yaw := -0.30
var pitch := 0.22
var zoom := 5.2
var mouse_turning := false
var profile := ConfigFile.new()

func _ready() -> void:
    var nick := "Bezoeker"
    if profile.load("user://cafe_profiel.cfg") == OK:
        nick = str(profile.get_value("profile", "nickname", nick))
    var cafe = WORLD_SCRIPT.new()
    add_child(cafe)
    player = AVATAR_SCRIPT.new()
    player.display_name = nick
    add_child(player)
    player.global_position = Vector3(2.3, 0.15, 5.8)
    camera = Camera3D.new()
    camera.current = true
    camera.fov = 65.0
    add_child(camera)
    _update_camera(1.0)
    hud = HUD_SCRIPT.new()
    hud.avatar = player
    hud.nickname = nick
    add_child(hud)
    hud.action_requested.connect(_ui_action)
    hud.nickname_changed.connect(_update_nickname)

func _process(delta: float) -> void:
    if is_instance_valid(player):
        player.camera_heading = yaw
        _update_camera(delta)

func _update_camera(delta: float) -> void:
    var target := player.global_position + Vector3(0.0, 1.36, 0.0)
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
        var d := player.global_position.distance_to(seat.global_position)
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
            var result := OS.shell_open(SERVER_URI)
            if result == OK:
                hud.set_status("TeamSpeak-link geopend. TeamSpeak 3 moet geïnstalleerd zijn.")
            else:
                hud.set_status("Geen TeamSpeak-linkhandler gevonden. Open TeamSpeak handmatig: Heerlen.MIJNTS3.NL")
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
