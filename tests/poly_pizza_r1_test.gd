extends SceneTree
## Test uitsluitend de lokale R1-catalogus en de compatibiliteit met bestaande avatar-API.
const AVATAR = preload("res://scripts/avatar.gd")
const CATALOG = preload("res://scripts/r1_avatar_catalog.gd")

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var mine = AVATAR.new()
    mine.display_name = "Michiel"
    root.add_child(mine)
    var guest = AVATAR.new()
    guest.display_name = "Gast"
    guest.remote_mode = true
    root.add_child(guest)
    await process_frame
    if mine.visual == null or mine.left_arm == null or mine.label_node == null:
        _fail("Bestaande avatar-API niet intact")
        return
    guest.set_speaking(true)
    if not guest.speaking_ring.visible:
        _fail("TeamSpeak spreekindicator werkt niet")
        return
    guest.set_speaking(false)
    if guest.speaking_ring.visible:
        _fail("Spreekindicator schakelt niet uit")
        return
    if CATALOG.AVATARS.size() < 70:
        _fail("Niet genoeg R1-avatars: downloadstap ontbreekt of mislukt")
        return
    for path in CATALOG.AVATARS:
        if not path.begins_with("res://assets/avatars/100-r1/"):
            _fail("Avatar buiten 100 Avatars R1 collectie: " + path)
            return
        if not ResourceLoader.exists(path):
            _fail("R1 avatar kan niet geladen worden: " + path)
            return
    if mine.avatar_count() > 0:
        if not mine.select_avatar(mine.avatar_count() - 1):
            _fail("Laatste avatar kan niet worden geselecteerd")
            return
        if not mine.select_avatar(0):
            _fail("Eerste avatar kan niet worden geselecteerd")
            return
    print("POLY_PIZZA_R1_TEST_OK: %d avatars, namen en TS3 spreekring" % mine.avatar_count())
    quit(0)

func _fail(message: String) -> void:
    push_error("POLY_PIZZA_R1_TEST_FAIL: " + message)
    quit(2)
