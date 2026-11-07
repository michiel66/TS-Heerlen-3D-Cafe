extends SceneTree
## Offline Godot integratietest: de TS3-gebruikerslijst bepaalt de 3D avatars.
const ONLINE = preload("res://scripts/online_avatars.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var room = ONLINE.new()
    root.add_child(room)
    await process_frame
    var visitors: Array = [
        {"id": "1", "name": "Eigen Gebruiker"},
        {"id": "2", "name": "Jan"},
        {"id": "3", "name": "Mieke"}
    ]
    room.update_roster(visitors, "1", "Eigen Gebruiker")
    if room.online_avatar_count() != 2:
        _fail("Verwacht 2 gasten en geen dubbele lokale avatar")
        return
    if not room.avatars.has("2"):
        _fail("Jan ontbreekt in de wereld")
        return
    room.mark_talking("2")
    if not room.avatars["2"].remote_speaking:
        _fail("Spreekindicator niet actief")
        return
    room.update_roster([{"id":"1","name":"Eigen Gebruiker"},{"id":"3","name":"Mieke"}], "1", "Eigen Gebruiker")
    if room.online_avatar_count() != 1 or room.avatars.has("2"):
        _fail("Vertrokken bezoeker is niet verwijderd")
        return
    print("ONLINE_AVATARS_TEST_OK: toevoegen, verwijderen, spreken en lokale gebruiker overslaan")
    quit(0)

func _fail(message: String) -> void:
    push_error("ONLINE_AVATARS_TEST_FAIL: " + message)
    quit(2)
