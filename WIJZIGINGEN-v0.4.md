# Online TeamSpeak-gebruikers in het 3D Café — v0.4

Wijzigingen:
- scripts/online_avatars.gd (nieuw): maakt/verwijdert gasten per TS3-client-ID en markeert sprekers.
- scripts/avatar.gd: extra stand voor remote bezoeker zonder eigen besturing of botsing.
- scripts/main.gd: koppelt de TS3-roster aan online avatars.
- scripts/teamspeak_bridge.gd: ontvangt eigen client-ID uit de sidecar.
- bridge/main.cjs: stuurt eigen client-ID samen met de roster; audio ongewijzigd.
- scripts/world.gd: oude demo-avatars verbergen wanneer verbonden.
- scripts/hud.gd: alle namen scrollbaar en 3D-avatar-aantal zichtbaar.
- tests/online_avatars_test.gd: regressietest voor verschijnen/verdwijnen/sprekers.
- tests/smoke_test.gd: test ook OnlineVisitors.
- installer.iss en .github/workflows/windows.yml: build v0.4 met alle tests.

Let op: er is nog geen echte realtime avatar-positie-synchronisatie tussen computers.
