# TeamSpeak Heerlen 3D Café — uiterlijk v0.6

Dit pakket vervangt **uitsluitend het uiterlijk en de versienaam van de Windows-installer**. De TeamSpeak-client, Node-sidecar, PTT, Opus-audio, microfoon en avatars worden **niet aangepast**.

## Visuele wijzigingen

- Negen nieuwe handgemaakte oppervlaktetexturen voor eiken vloer, baksteen, walnoothout, stenen toonbank, stoffering, wandpleister en tapijt.
- Grote koffie-menukaart, TEAM SPEAK HEERLEN-achterwand, bronzen baraccenten en herkenbare lichtlijnen.
- Aangepaste barista-uitrusting, hanglampen, loungezitplaatsen, keramische koffiekopjes, planten, plafondbalken, wandsierlijsten en dansvloer.
- Donkerblauw-bronzen bedieningspanelen met oranje focus/hover-accenten.
- Herkenbaar label `LOOK v0.6` in het spel, zodat je de juiste build kunt herkennen.

## Installatie

1. Pak de ZIP uit en upload **de mapinhoud** naar de hoofdmap van je bestaande GitHub-repository.
2. Behoud alle submappen (`assets/textures`, `scripts`, `scenes`, `.github/workflows`).
3. Vervang bestaande `scripts/cafe_look.gd`, `scenes/main.tscn`, `installer.iss` en `.github/workflows/windows.yml`.
4. Start/controleer de GitHub Action. Download bij groen de nieuwste installer `TS-Heerlen-3D-Cafe-Setup-v0.6.exe`.
5. Sluit het oude café en het bijbehorende Node-proces voordat je installeert. Bewaar je data in `user://ts3voice`.

## Ontwerp en compatibiliteit

`scenes/main.tscn` bevat `CafeLookUpgrade` dat na het aanmaken van het café `scripts/cafe_look.gd` aanroept. Dit script verandert materialen van bestaande meubels en voegt alleen **visuele** `MeshInstance3D`, `OmniLight3D` en Control-nodes toe. Het voegt geen botsingen of TeamSpeak-commandos toe.

De Godot-projectinstellingen blijven op **Godot 4.7.2** met **Compatibility**-renderer. Er zijn geen extra Blender-bestanden of plugins nodig. Dit is een visueel rijkere procedurele 3D-wereld; fotorealistische scans of kant-en-klare high-poly-modellen zijn niet aanwezig.

## Teststatus

- Node-protocol-/roster-tests: 6 tests geslaagd in de lokale projectkopie.
- Statische asset- en verwijzingscontrole: geslaagd.
- Godot-bouw en zichtbare weergave op Windows: **nog niet in deze omgeving getest**; de GitHub Action voert de Godot-import, smoke-test, export en installer-build uit.
