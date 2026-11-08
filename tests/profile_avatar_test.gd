extends SceneTree
## Verifieert het profielmenu zonder verbinding met de TeamSpeak-server.
const HUD = preload("res://scripts/hud.gd")
const AVATAR = preload("res://scripts/avatar.gd")

func _initialize() -> void:
    call_deferred("_test")

func _test() -> void:
    var actor = AVATAR.new()
    actor.display_name = "Profieltest"
    root.add_child(actor)
    var hud = HUD.new()
    hud.nickname = "Profieltest"
    hud.avatar = actor
    root.add_child(hud)
    await process_frame
    hud.show_panel("settings")
    if not hud.settings_tabs.visible or not hud.profile_form.visible:
        _fail("Instellingen / Profiel verschijnt niet")
        return
    if hud.avatar_selector == null or hud.avatar_detail == null:
        _fail("Avatarkiezer ontbreekt")
        return
    if actor.avatar_count() > 0:
        var selected: Array[int] = []
        hud.avatar_selected.connect(func(index: int) -> void: selected.append(index))
        hud._avatar_option_changed(0)
        if selected.is_empty() or selected[0] != 0:
            _fail("Avatarkeuze veroorzaakt geen signaal")
            return
        hud.set_avatar_selection(actor.avatar_count() - 1)
        if hud.avatar_selector.selected != actor.avatar_count() - 1:
            _fail("Avatarkeuze wordt niet gesynchroniseerd")
            return
    hud._show_settings_tab("teamspeak")
    if not hud.teamspeak_form.visible or hud.profile_form.visible:
        _fail("TeamSpeak-tab schakelt niet")
        return
    print("PROFILE_AVATAR_TEST_OK: profielmenu, avatarkeuze en TeamSpeak-instellingen")
    quit(0)

func _fail(reason: String) -> void:
    push_error("PROFILE_AVATAR_TEST_FAIL: " + reason)
    quit(2)
