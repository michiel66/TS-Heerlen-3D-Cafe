extends SceneTree
## Automatische opstartcontrole in GitHub Actions. Een kapotte startscene stopt de installer-build.

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        _fail("STARTSCENE ontbreekt of is ongeldig")
        return
    var game: Node = packed.instantiate()
    if game == null:
        _fail("Kan de startscene niet instantiëren")
        return
    root.add_child(game)
    await process_frame
    var required: Array[String] = ["CafeWorld", "LocalAvatar", "MainCamera", "CafeHUD"]
    for path in required:
        if game.get_node_or_null(path) == null:
            _fail("Opstartcomponent ontbreekt: " + path)
            return
    var boot: CanvasLayer = game.get_node_or_null("BootScreen") as CanvasLayer
    if boot == null or boot.visible:
        _fail("Opstartscherm blijft zichtbaar: hoofdscript niet volledig geladen")
        return
    var world: Node3D = game.get_node("CafeWorld") as Node3D
    if world.get_child_count() < 10:
        _fail("3D-cafe is niet opgebouwd")
        return
    print("SMOKE_TEST_OK: 3D cafe, speler, camera en HUD actief")
    quit(0)

func _fail(message: String) -> void:
    push_error("SMOKE_TEST_FAIL: " + message)
    quit(2)
