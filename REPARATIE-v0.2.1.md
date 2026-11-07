# Reparatie v0.2.1 - grijs startvenster

## Wat er fout ging
In `scripts/main.gd` stond `var target := player.global_position + ...` en `var d := player.global_position.distance_to(...)`.
De GDScript-compiler kan het type niet automatisch afleiden als `player` dynamisch is (`var player` zonder type).
Omdat het hoofdscript niet startte, waren **de camera, het café en het menu onzichtbaar**.

## Wat is gerepareerd?
- Expliciete `Vector3` en `float` types voor de twee variabelen.
- Onderdelen krijgen vaste namen `CafeWorld`, `LocalAvatar`, `MainCamera`, `CafeHUD`.
- Fallback-startscherm in `scenes/main.tscn` bij een volgende opstartfout.
- Een echte Godot-opstarttest die vóór het bouwen van een installer controleert of de 3D-wereld, avatar, camera en HUD bestaan.
- Installer v0.2.1, zodat je ziet dat de nieuwe build is geïnstalleerd.

## Upload naar GitHub
Upload alle inhoud van deze ZIP (dus **niet de bovenliggende map**) naar de repository-root, inclusief `.github/workflows/windows.yml`.
Gebruik je de PATCH, vervang dan precies deze bestanden:
- `scripts/main.gd`
- `scenes/main.tscn`
- `tests/smoke_test.gd`
- `.github/workflows/windows.yml`
- `installer.iss`

Ga daarna naar GitHub > Actions > TeamSpeak Heerlen - Windows Setup. Klik op de geslaagde run en download `TS-Heerlen-3D-Cafe-Setup-v0.2.1`.
Pak de artifact-ZIP uit en start `TS-Heerlen-3D-Cafe-Setup-v0.2.1.exe`.

**Let op:** deze broncode is statisch nagekeken, maar een lokale Godot 4.7.2-runtime is hier niet beschikbaar om de app te testen. Daarom voert GitHub Actions de echte opstarttest uit en stopt de build als die niet slaagt.
