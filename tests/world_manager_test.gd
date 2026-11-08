extends SceneTree
## Optionele Godot-test na --editor --import (zie README).
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
    if packed == null:
        _fail("Main-scene ontbreekt")
        return
    var game: Node3D = packed.instantiate() as Node3D
    if game == null:
        _fail("Main-scene kan niet worden gemaakt")
        return
    root.add_child(game)
    await process_frame
    await process_frame
    var manager = game.get_node_or_null("WorldSwitcher")
    if manager == null or manager.world_picker == null:
        _fail("Wereldbeheer-menu ontbreekt")
        return
    if not manager._activate_world("night_club", true):
        _fail("Night Club GLB kan niet worden geladen")
        return
    if manager.current_world_id != "night_club" or game.get_node("CafeWorld").visible:
        _fail("Nachtclub is niet actief")
        return
    if not manager._activate_world("cafe", true):
        _fail("Terugschakelen naar cafe mislukt")
        return
    if manager.current_world_id != "cafe" or not game.get_node("CafeWorld").visible:
        _fail("Cafe is niet hersteld")
        return
    print("WORLD_MANAGER_TEST_OK: cafe ↔ Night Club, avatars en HUD behouden")
    quit(0)

func _fail(message: String) -> void:
    push_error("WORLD_MANAGER_TEST_FAIL: " + message)
    quit(2)
