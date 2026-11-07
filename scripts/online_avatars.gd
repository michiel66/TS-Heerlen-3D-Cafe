
extends Node3D
## TeamSpeak Heerlen 3D Café v0.4
## Zet online TeamSpeak-gebruikers als 3D-avatars in het café.
## Bewegingen van andere computers worden nog niet gesynchroniseerd.

const AVATAR_SCRIPT = preload("res://scripts/avatar.gd")

var avatars: Dictionary = {}
var slots: Dictionary = {}
var talker_expiry: Dictionary = {}
var current_speaker := ""
var slot_positions: Array[Vector3] = []

func _ready() -> void:
    _create_positions()

func _create_positions() -> void:
    for x in [-10.2, -8.7, -7.2, -5.7, -4.2, -2.7]:
        slot_positions.append(Vector3(x, 0.15, 2.1))
        slot_positions.append(Vector3(x, 0.15, 4.7))

    for x in [-2.2, -0.7, 0.8, 2.3]:
        slot_positions.append(Vector3(x, 0.15, 0.4))
        slot_positions.append(Vector3(x, 0.15, 3.2))
        slot_positions.append(Vector3(x, 0.15, 6.3))

    for x in [-2.0, -0.5, 1.0]:
        slot_positions.append(Vector3(x, 0.15, -6.0))
        slot_positions.append(Vector3(x, 0.15, -8.0))

    for x in [5.8, 7.5, 9.2]:
        slot_positions.append(Vector3(x, 0.15, -6.5))
        slot_positions.append(Vector3(x, 0.15, -1.8))
        slot_positions.append(Vector3(x, 0.15, 3.4))
        slot_positions.append(Vector3(x, 0.15, 7.3))

func _position_for_slot(slot_index: int) -> Vector3:
    if slot_index < slot_positions.size():
        return slot_positions[slot_index]

    var n: int = slot_index - slot_positions.size()
    var columns: int = 16
    var row_number: int = n / columns
    var x: float = -10.8 + float(n % columns) * 1.37
    var z: float = -6.4 + float(row_number % 11) * 1.32

    return Vector3(
        x,
        0.15 + float(row_number / 11) * 0.015,
        z
    )

func _free_slot() -> int:
    var candidate := 0

    while slots.values().has(candidate):
        candidate += 1

    return candidate

func _shirt_color(id: String) -> Color:
    var hue: float = float(absi(id.hash()) % 1000) / 1000.0
    return Color.from_hsv(hue, 0.48, 0.72)

func update_roster(
    users: Array,
    own_client_id: String,
    own_nickname: String
) -> void:

    var present: Dictionary = {}
    var local_fallback_used := false

    for entry in users:
        if typeof(entry) != TYPE_DICTIONARY:
            continue

        var id: String = str(
            entry.get("id", "")
        ).strip_edges()

        var visitor_name: String = str(
            entry.get("name", "Onbekend")
        ).strip_edges().substr(0, 60)

        if id.is_empty() or present.has(id):
            continue

        if not own_client_id.is_empty() and id == own_client_id:
            continue

        if own_client_id.is_empty() \
        and not local_fallback_used \
        and visitor_name.to_lower() == own_nickname.to_lower():
            local_fallback_used = true
            continue

        if visitor_name.is_empty():
            visitor_name = "Onbekend"

        present[id] = true

        if not avatars.has(id):
            var guest = AVATAR_SCRIPT.new()

            guest.remote_mode = true
            guest.display_name = visitor_name
            guest.shirt_color = _shirt_color(id)
            guest.name = "Online_" + id.replace("-", "_")

            add_child(guest)

            avatars[id] = guest
            slots[id] = _free_slot()

            guest.global_position = _position_for_slot(
                int(slots[id])
            )

            guest.rotation.y = float(
                int(slots[id]) % 6
            ) * 0.5
        else:
            var actor = avatars[id]

            if is_instance_valid(actor) \
            and actor.display_name != visitor_name:
                actor.update_display_name(visitor_name)

    for id in avatars.keys():
        if not present.has(id):
            var old = avatars[id]

            if is_instance_valid(old):
                old.queue_free()

            avatars.erase(id)
            slots.erase(id)
            talker_expiry.erase(id)

    if not avatars.has(current_speaker):
        current_speaker = ""

func mark_talking(id: String) -> void:
    if id.is_empty() or not avatars.has(id):
        return

    if current_speaker != id \
    and avatars.has(current_speaker):
        avatars[current_speaker].set_speaking(false)

    current_speaker = id
    talker_expiry[id] = Time.get_ticks_msec() + 1100
    avatars[id].set_speaking(true)

func _process(_delta: float) -> void:
    if current_speaker.is_empty():
        return

    if Time.get_ticks_msec() > int(
        talker_expiry.get(current_speaker, 0)
    ):
        if avatars.has(current_speaker):
            avatars[current_speaker].set_speaking(false)

        current_speaker = ""

func clear() -> void:
    update_roster([], "", "")

func online_avatar_count() -> int:
    return avatars.size()
