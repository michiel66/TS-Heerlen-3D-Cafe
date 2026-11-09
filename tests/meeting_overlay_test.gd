extends SceneTree
## Regressietest: live TeamSpeak-roster vult uitsluitend bezette stoelen.
## Uitvoeren na Godot-editorimport en het downloaden van de 100Avatars R1-modellen.

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        _fail("Hoofdscene ontbreekt")
        return
    var game: Node3D = packed.instantiate() as Node3D
    if game == null:
        _fail("Kan hoofdscene niet maken")
        return
    root.add_child(game)
    await process_frame
    await process_frame
    await process_frame
    var overlay: Variant = game.get_node_or_null("MeetingOverlay")
    if overlay == null or overlay.interface_root == null:
        _fail("Live vergaderinterface ontbreekt")
        return
    if overlay.members.size() != 0 or overlay.seat_nodes.size() != 0:
        _fail("Er zijn fictieve bezoekers terwijl de roster leeg is")
        return
    overlay._on_roster([
        {"id": "11", "name": "Test Jan", "channel": "2"},
        {"id": "12", "name": "Test Eva", "channel": "2"}
    ], "11", "2")
    if overlay.members.size() != 2 or overlay.seat_nodes.size() != 2:
        _fail("Twee bezoekers krijgen niet precies twee stoelen")
        return
    overlay._on_talking("12")
    if overlay.talking_id != "12":
        _fail("Spreekindicator ontvangt client-ID niet")
        return
    overlay._on_roster([{"id": "12", "name": "Test Eva", "channel": "2"}], "", "2")
    if overlay.seat_nodes.size() != 1:
        _fail("Vertrokken bezoeker blijft op een stoel zitten")
        return
    overlay._on_roster([], "", "")
    if overlay.seat_nodes.size() != 0 or overlay.members.size() != 0:
        _fail("Stoelen zijn niet leeg als iedereen vertrekt")
        return
    if game.get_node_or_null("LocalTeamSpeakBridge") == null:
        _fail("Bestaande TeamSpeak-bridge ontbreekt")
        return
    if game.get_node_or_null("WorldSwitcher") == null:
        _fail("Bestaande wereldbeheer ontbreekt")
        return
    print("MEETING_OVERLAY_TEST_OK: online -> stoel bezet, offline -> stoel leeg, TS/PTT intact")
    quit(0)

func _fail(message: String) -> void:
    push_error("MEETING_OVERLAY_TEST_FAIL: " + message)
    quit(2)
