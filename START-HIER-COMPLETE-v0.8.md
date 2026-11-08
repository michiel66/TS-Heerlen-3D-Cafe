# TEAMSpeak HEERLEN 3D CAFE — VOLLEDIG v0.8 PROJECT

## EENMAAL UPLOADEN NAAR GITHUB

Dit is geen losse update, maar een **volledig project** met Godot-scripts,
3D-cafe, texturen, TeamSpeak-brug, Node-tests, Windows-installer en Actions.

1. Pak DEZE ZIP volledig uit op je computer.
2. Open https://github.com/michiel66/TS-Heerlen-3D-Cafe
3. Kies **Add file > Upload files**.
4. Sleep alle INHOUD uit de uitgepakte projectmap tegelijk naar GitHub.
   Let op dat `project.godot`, `installer.iss`, `scripts/`, `bridge/`,
   `assets/`, `tests/`, `tools/` en `.github/workflows/` in de repositoryroot staan.
   Sleep niet de buitenste map als extra maplaag en upload de ZIP niet als
   enkel ZIP-bestand: GitHub pakt een ZIP in de repository niet automatisch uit.
5. Kies **Commit changes**.
6. Ga naar **Actions** en bekijk **TeamSpeak Heerlen - Windows Setup**.
7. Na een groene build: open **Artifacts** en download
   `TS-Heerlen-3D-Cafe-Setup-v0.8`.

## DE ECHTE 3D-AVATARS: 100Avatars R1 VAN POLYGONAL MIND

**Geen losse GLTF-bundel en geen handmatige `START-IMPORT-R1.cmd` meer nodig.**
De workflow downloadt zelfstandig de originele R1 `.fbx`-modellen en
bijbehorende `.png`-texturen van de officiele repository van Polygonal Mind,
genereert `scripts/r1_avatar_catalog.gd` en neemt de geimporteerde modellen
mee in de Windows-export. Zie `tools/HAAL-R1-AVATARS-AUTOMATISCH.ps1`.

- Poly Pizza, dezelfde serie, toont 73 modellen:
  https://poly.pizza/bundle/100-Avatars-R1-amJ23JjkKG
- Polygonal Mind heeft de volledige originele R1-reeks van 100 avatars:
  https://github.com/PolygonalMind/100Avatars
- R1 is CC0/Public Domain: https://creativecommons.org/publicdomain/zero/1.0/
- We gebruiken **alleen R1**, geen andere avatarcollecties.
- De download komt **TIJDENS GitHub Actions** tot stand. De 3D-modellen
  zitten dus NIET als binaire bestanden in deze 4MB broncode-ZIP.
  Ze zitten bij een geslaagde build wel in de Windows-app.
- De modellen zijn gestileerde low-poly, niet fotorealistisch.

## BEHOUD VAN WERKENDE TEAMSPEAK-FUNCTIES

Voor de werkende TS3-audio, PTT en HUD gebruikt de build automatisch de
laatste bevestigde bronbestanden uit je eigen GitHub-commit
`60ac95fd3c3dba53634349953fff6e1c77d38766`.
Zie `tools/HERSTEL-LAATSTE-TEAMSPEAK.ps1` voor de controle op SHA.
Dit voorkomt dat een oudere back-up van de TeamSpeak-code in deze ZIP de
werkende verbinding in het gebouwde programma vervangt. Je bestaande
gebruikersprofiel/configuratie op Windows wordt niet geraakt.

**Let op:** de bronbestanden in het gedownloade archief komen uit de vorige
projectback-up. De automatische herstelstap past ze alleen in de buildomgeving
aan. Maak voor de zekerheid eerst een GitHub-back-up als je er recent zelf
nieuwe TeamSpeak-functies bij hebt gemaakt.

## BESTURING EN BEPERKINGEN

- WASD lopen, E zitten, F dansen, V push-to-talk, F7 andere R1-avatar,
  Shift+F7 vorige R1-avatar.
- TeamSpeak-gebruikers krijgen een avatar met naamlabel en spreekring.
- Losse skeletanimaties zitten niet automatisch in alle R1-bronmodellen;
  loop-, zit- en dansbesturing is aanwezig, maar clips kunnen ontbreken.
- Dit bestand is een volledig BRONCODEPROJECT en geen kant-en-klare Setup.exe.
  Windows Godot/Inno Setup-build is hier niet uitvoerbaar getest. GitHub Actions
  test Godot/import, avatars, voice-tests en installer-build.

## ALS GITHUB ROOD WORDT

Open de rode stap in Actions en kopieer de eigenlijke foutmelding.
De stap `Download alle originele 100Avatars R1 3D-modellen` moet
`100 selecteerbare avatars` melden.

Versie: LOOK v0.8 - Polygonal Mind R1
