extends SceneTree
## Verifieert LOOK v0.7 en lokale / online avatars zonder een TS-server.
const AVATAR = preload("res://scripts/avatar.gd")
const LOOK = preload("res://scripts/cafe_look.gd")

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var mine = AVATAR.new()
    mine.display_name = "Lokaal"
    root.add_child(mine)
    var guest = AVATAR.new()
    guest.display_name = "Bezoeker"
    guest.remote_mode = true
    root.add_child(guest)
    await process_frame
    if mine.visual == null or mine.left_arm == null or mine.label_node == null:
        _fail("Lokale avatar mist modellen of naam")
        return
    guest.set_speaking(true)
    if not guest.remote_speaking or guest.speaking_ring == null or not guest.speaking_ring.visible:
        _fail("3D-spreekindicator werkt niet")
        return
    guest.set_speaking(false)
    if guest.speaking_ring.visible:
        _fail("3D-spreekindicator blijft aan")
        return
    var look = LOOK.new()
    if look == null:
        _fail("LOOK v0.7 kan niet laden")
        return
    print("VISUAL_V07_TEST_OK: avatar, namen, spreekring en LOOK geladen")
    quit(0)

func _fail(reason: String) -> void:
    push_error("VISUAL_V07_TEST_FAIL: " + reason)
    quit(2)
