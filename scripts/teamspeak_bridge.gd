
extends Node
## TeamSpeak Heerlen 3D Café v0.4.2
## Lokale Node-module via beveiligde WebSocket.
## Iedere start gebruikt een eigen lokale poort.

signal status_updated(connected: bool, text: String)
signal roster_updated(
    users: Array,
    own_client_id: String,
    own_channel: String
)
signal voice_active(client_id: String)

var port: int = 39453
const FRAME := 960

var socket: WebSocketPeer
var secret := ""
var pid := -1
var authenticated := false
var bridge_ready := false
var pending_connect := false
var socket_wait_elapsed := 0.0
var bridge_warning_shown := false
var connected := false
var attempting := false
var retry_elapsed := 0.0

var mic_player: AudioStreamPlayer
var mic_capture: AudioEffectCapture
var speaker: AudioStreamPlayer
var playback: AudioStreamGeneratorPlayback

var incoming: Array[PackedVector2Array] = []
var ptt := false
var nickname := "Bezoeker"
var channel := ""
var last_message := "Spraakmodule starten…"

func _ready() -> void:
    secret = Crypto.new().generate_random_bytes(24).hex_encode()

    var random_port := RandomNumberGenerator.new()
    random_port.randomize()
    port = random_port.randi_range(40000, 59999)

    _setup_audio()
    _launch_bridge()
    _try_socket()

func _setup_audio() -> void:
    # Microfoon op aparte bus om terugkoppeling te voorkomen.
    var bus_index: int = AudioServer.get_bus_count()
    AudioServer.add_bus(bus_index)
    AudioServer.set_bus_name(bus_index, "HeerlenMic")
    AudioServer.set_bus_volume_db(bus_index, -80.0)

    mic_capture = AudioEffectCapture.new()
    mic_capture.buffer_length = 0.4
    AudioServer.add_bus_effect(bus_index, mic_capture)

    mic_player = AudioStreamPlayer.new()
    mic_player.bus = "HeerlenMic"
    mic_player.stream = AudioStreamMicrophone.new()
    add_child(mic_player)
    mic_player.play()

    var output_stream := AudioStreamGenerator.new()
    output_stream.mix_rate = 48000.0
    output_stream.buffer_length = 0.4

    speaker = AudioStreamPlayer.new()
    speaker.stream = output_stream
    add_child(speaker)
    speaker.play()

    playback = speaker.get_stream_playback() as AudioStreamGeneratorPlayback

func _launch_bridge() -> void:
    var exe_path: String = OS.get_executable_path().get_base_dir()
    var node_exe: String = exe_path.path_join(
        "voice-bridge"
    ).path_join("node.exe")

    var source: String = exe_path.path_join(
        "voice-bridge"
    ).path_join("main.cjs")

    if OS.has_feature("editor"):
        node_exe = "node"
        source = ProjectSettings.globalize_path(
            "res://bridge/main.cjs"
        )

    elif not FileAccess.file_exists(node_exe) \
    or not FileAccess.file_exists(source):
        last_message = "Meegeleverde spraakmodule ontbreekt."
        status_updated.emit(false, last_message)
        return

    var data_dir := ProjectSettings.globalize_path(
        "user://ts3voice"
    )
    DirAccess.make_dir_recursive_absolute(data_dir)

    pid = OS.create_process(
        node_exe,
        PackedStringArray([
            source,
            secret,
            data_dir,
            str(port)
        ]),
        false
    )

    if pid <= 0:
        last_message = "Kon lokale spraakmodule niet starten."
        status_updated.emit(false, last_message)

func _try_socket() -> void:
    if pid <= 0:
        return

    socket = WebSocketPeer.new()

    # Godot 4.7.2: geen handshake_timeout gebruiken.
    var err: int = socket.connect_to_url(
        "ws://127.0.0.1:%d" % port
    )

    if err != OK:
        socket = null
        last_message = "Wachten op lokale spraakmodule…"
        return

    attempting = true

func _process(delta: float) -> void:
    if socket != null:
        socket.poll()

        var state: int = socket.get_ready_state()

        if state == WebSocketPeer.STATE_OPEN and not authenticated:
            _send({
                "type": "hello",
                "token": secret
            })
            authenticated = true

        if state == WebSocketPeer.STATE_OPEN:
            var count: int = mini(
                socket.get_available_packet_count(),
                100
            )

            for i in range(count):
                _receive(
                    socket.get_packet().get_string_from_utf8()
                )

        elif state == WebSocketPeer.STATE_CLOSED:
            if connected:
                connected = false
                status_updated.emit(
                    false,
                    "TeamSpeak-module offline"
                )

            socket = null
            authenticated = false
            bridge_ready = false
            attempting = false

    retry_elapsed += delta

    if socket == null and pid > 0 and retry_elapsed > 0.8:
        retry_elapsed = 0.0
        _try_socket()

    if pid > 0 and not bridge_ready:
        socket_wait_elapsed += delta

        if socket_wait_elapsed > 8.0 and not bridge_warning_shown:
            bridge_warning_shown = true
            last_message = (
                "Lokale TeamSpeak-module niet bereikbaar; "
                + "controleer installatie of Windows-beveiliging."
            )
            status_updated.emit(false, last_message)

    _pump_microphone()
    _pump_speaker()

func _send(data: Dictionary) -> void:
    if socket != null \
    and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
        socket.send_text(JSON.stringify(data))

func _receive(raw: String) -> void:
    var parsed: Variant = JSON.parse_string(raw)

    if typeof(parsed) != TYPE_DICTIONARY:
        return

    var message: Dictionary = parsed

    match str(message.get("type", "")):
        "status":
            if str(message.get("message", "")) == "Lokale spraakmodule gereed":
                bridge_ready = true
                bridge_warning_shown = false
                socket_wait_elapsed = 0.0

                if pending_connect:
                    pending_connect = false
                    _send({
                        "type": "connect",
                        "nickname": nickname,
                        "channel": channel
                    })

            connected = bool(
                message.get("connected", false)
            )
            last_message = str(
                message.get("message", "")
            )

            if not connected:
                ptt = false

            status_updated.emit(
                connected,
                last_message
            )

        "error":
            last_message = str(
                message.get("message", "Onbekende fout")
            )
            status_updated.emit(
                connected,
                "TeamSpeak: " + last_message
            )

        "roster":
            var users: Variant = message.get(
                "users", []
            )

            if typeof(users) == TYPE_ARRAY:
                roster_updated.emit(
                    users,
                    str(message.get("ownClientId", "")),
                    str(message.get("ownChannel", ""))
                )

        "audio":
            _queue_pcm(
                str(message.get("pcm", ""))
            )

        "talking":
            voice_active.emit(
                str(message.get("clientId", ""))
            )

func connect_teamspeak(
    name_value: String,
    room: String
) -> void:
    nickname = name_value
    channel = room

    if not bridge_ready:
        pending_connect = true
        status_updated.emit(
            false,
            "Wachten op de lokale spraakmodule; verbinden zodra die klaar is."
        )
        return

    pending_connect = false

    _send({
        "type": "connect",
        "nickname": nickname,
        "channel": channel
    })

func disconnect_teamspeak() -> void:
    pending_connect = false
    set_ptt(false)
    _send({
        "type": "disconnect"
    })

func set_ptt(active: bool) -> void:
    ptt = active and connected

    _send({
        "type": "ptt",
        "active": ptt
    })

func _pump_microphone() -> void:
    if mic_capture == null:
        return

    var loops := 0

    while mic_capture.get_frames_available() >= FRAME \
    and loops < 5:
        loops += 1

        var frames: PackedVector2Array = (
            mic_capture.get_buffer(FRAME)
        )

        if not connected or not ptt or not authenticated:
            continue

        var data := PackedByteArray()
        data.resize(FRAME * 2)

        for i in range(FRAME):
            var s: float = clampf(
                (frames[i].x + frames[i].y) * 0.5,
                -1.0,
                1.0
            )

            var pcm: int = clampi(
                int(round(s * 32767.0)),
                -32768,
                32767
            ) & 0xffff

            data[i * 2] = pcm & 255
            data[i * 2 + 1] = (pcm >> 8) & 255

        _send({
            "type": "pcm",
            "pcm": Marshalls.raw_to_base64(data)
        })

func _queue_pcm(encoded: String) -> void:
    var data: PackedByteArray = (
        Marshalls.base64_to_raw(encoded)
    )

    if data.size() < 2 \
    or data.size() > 5760 \
    or data.size() % 2 != 0:
        return

    var frames := PackedVector2Array()
    frames.resize(int(data.size() / 2))

    for i in range(frames.size()):
        var value: int = (
            int(data[i * 2])
            | (int(data[i * 2 + 1]) << 8)
        )

        if value >= 32768:
            value -= 65536

        var normalized: float = float(value) / 32768.0

        frames[i] = Vector2(
            normalized,
            normalized
        )

    incoming.append(frames)

    if incoming.size() > 15:
        incoming.pop_front()

func _pump_speaker() -> void:
    if playback == null:
        return

    var loops := 0

    while not incoming.is_empty() and loops < 8:
        var samples: PackedVector2Array = incoming[0]

        if playback.get_frames_available() < samples.size():
            break

        incoming.pop_front()
        playback.push_buffer(samples)
        loops += 1

func _exit_tree() -> void:
    disconnect_teamspeak()

    if socket != null:
        socket.close()

    if pid > 0:
        OS.kill(pid)
