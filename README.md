# ☕ TeamSpeak Heerlen – 3D Café

![Visueel doelbeeld van het café](docs/voorbeeld-layout.png)

Een **Godot 4.7.2**-prototype van een virtueel 3D-koffiehuis voor Windows. De afbeelding hierboven is de **referentie/look**, geen screenshot van de huidige 3D-app. De ruimte in het project is opgebouwd uit echte 3D-objecten, zodat je er kunt rondlopen.

**TeamSpeak-server:** `Heerlen.MIJNTS3.NL`

> **Versie 0.2: lokaal prototype met Windows-installatie.** Je kunt rondlopen, de camera draaien, een stoel gebruiken, dansen, naar de radiohoek gaan en TeamSpeak openen. Multiplayer, daadwerkelijke TeamSpeak-spraak in het spel, een live gebruikerslijst en automatisch 3D-positieaudio zijn **nog niet gebouwd**. De 6 aanwezige demo-avatars zijn **geen online gebruikers**.

## ✅ Wat zit er al in?

- Zelf opgebouwd 3D-koffiehuis met houten vloer, bakstenen wand, grote ramen en sfeerverlichting.
- Koffiebar met koffiezetapparaten, barkrukken en schappen.
- Tafels, stoelen, zithoek, kamerplanten en decoratieve verlichting.
- Dansvloer met gekleurde vloertegels en decoratieve avatars.
- Radiohoek met 27MC-thema.
- Bestuurbare third-person avatar, rondkijken en zit/interactieknop.
- Nederlandstalige HUD: minikaart, navigatie, gebruikersinfo, instellingen.
- Eigen gebruikersnaam lokaal bewaren in `user://cafe_profiel.cfg`.
- TeamSpeak-knop opent de normale TeamSpeak-client via `ts3server://Heerlen.MIJNTS3.NL` (indien ondersteund door Windows/TeamSpeak).
- GitHub Actions-workflow om automatisch een volledige Windows Setup.exe te bouwen.

## 🕹 Besturing

| Toets | Actie |
|---|---|
| `W A S D` | Lopen |
| Rechtermuisknop ingedrukt + muis | Camera draaien |
| Muiswiel | Zoom |
| `E` | Gaan zitten / opstaan bij een stoel |
| `F` | Dansbeweging aan/uit |
| `R` | Naar de ingang |
| `F2` | Lokale notities (nog geen echte chat) |
| Knop `Café`, `Dansvloer`, `Radio` | Verplaatsen binnen het café |
| `Verbind met TeamSpeak` | TeamSpeak 3 openen |

## 💻 Voor bezoekers: alleen Setup.exe installeren

**Geen Godot downloaden en geen projectbestanden openen.** Download de openbare setup (na publicatie op GitHub Releases), dubbelklik op `TS-Heerlen-3D-Cafe-Setup-v0.2.exe` en doorloop de installatie. De app krijgt een vermelding in het Windows Startmenu en desgewenst een bureaubladsnelkoppeling. Verwijderen kan via Windows > Geïnstalleerde apps.

- De Godot 4.7.2 **runtime is onderdeel van de geëxporteerde 3D-app**. De editor is alleen nodig tijdens het bouwen, niet voor bezoekers.
- Voor spraak via `Heerlen.MIJNTS3.NL` moet de bezoeker vooralsnog apart **TeamSpeak 3** installeren en instellen. De knop in het 3D-café opent de TeamSpeak-client als `ts3server://` correct is gekoppeld.
- Versie 0.2 bouwt voort op het **lokale 3D-prototype**. Er is nog geen live synchronisatie van avatars, ingebouwde spraak, of 3D-positional audio.
- De installer is voorlopig **niet code-ondertekend**; Windows SmartScreen kan een waarschuwing geven. Deel de setup uitsluitend via de eigen GitHub-repository en controleer herkomst.

## 📦 Setup.exe automatisch maken op GitHub

1. Upload **alle bestanden en mappen** van deze projectmap naar de root van `michiel66/TS-Heerlen-3D-Cafe`. Let op de verborgen map `.github/workflows/windows.yml`.
2. Open **Actions > TeamSpeak Heerlen - Windows Setup > Run workflow**. De workflow gebruikt GitHub's Windows-runner en installeert Godot 4.7.2 + de officiële exporttemplates **alleen op de buildmachine**.
3. Godot exporteert het café als `TS-Heerlen-3D-Cafe.exe`. Daarna bouwt Inno Setup er een installeerbare `TS-Heerlen-3D-Cafe-Setup-v0.2.exe` van.
4. Download onder de workflow-run het artifact `TS-Heerlen-3D-Cafe-Setup-v0.2`. Pak de artifact-ZIP uit; daarin zit de setup die je kunt delen.
5. **Optioneel publiek maken:** maak een Git-tag `v0.2.0` en push die. De workflow plaatst de setup dan automatisch onder **Releases**, mits GitHub Actions schrijfrechten heeft op repository-inhoud.

De volledige installer kan niet uit alleen deze GitHub-broncode worden gedownload voordat een build succesvol is uitgevoerd. De Windows-setup is nog niet praktisch getest op een Windows-pc.

## 🛠 Voor ontwikkelaars (optioneel)

Als je zelf de 3D-wereld wilt bewerken, download dan [Godot 4.7.2](https://godotengine.org/download/windows/) en open `project.godot`. Gewone bezoekers hoeven dat niet te doen.

## 🧩 Projectindeling

```text
TS-Heerlen-3D-Cafe/
├── project.godot                  Godot hoofdproject
├── export_presets.cfg            Windows exportinstellingen
├── scenes/main.tscn              Hoofdscène
├── scripts/
│   ├── main.gd                   Camera, acties, TeamSpeak-startknop
│   ├── world.gd                  Café, bar, stoelen, dansvloer, verlichting
│   ├── avatar.gd                 Avatar, bewegen, zitten, dansen
│   ├── hud.gd                    Gebruikersinterface
│   └── minimap.gd                Minikaart
├── assets/textures/             Lokale, nieuw gemaakte texturen
├── docs/voorbeeld-layout.png    Door gebruiker gekozen ontwerpbeeld
├── installer.iss                  Inno Setup installer
├── assets/installer.ico          Installericoon
└── .github/workflows/windows.yml  Windows Setup build
```

## 🎤 Hoe zit het met TeamSpeak en multiplayer?

TeamSpeak 3 transporteert **spraak**, maar verstuurt niet vanzelf 3D-posities naar Godot. Dit prototype start de normale TeamSpeak 3-client, maar bevat nog **geen** `.dll`-plugin en toont geen live TeamSpeak-data.

Als we daarna **zonder een aparte 3D-server** willen bouwen, kunnen we experimenteel de TeamSpeak 3 Client Plugin SDK gebruiken voor kleine avatarpositie-berichten tussen plugin-gebruikers in hetzelfde TeamSpeak-kanaal. Dat moet getest worden met twee Windows-computers en de server-floodlimieten; het is niet gegarandeerd voldoende voor vloeiend multiplayer. Zie [TEAM SPEAK INTEGRATIE](docs/TEAMSPEAK-INTEGRATIE.md).

## 📜 Licenties

De projectcode en de gegenereerde textures vallen onder MIT (`LICENSE`). De illustratie in `docs/voorbeeld-layout.png` is als door de gebruiker aangeleverde ontwerp-referentie opgenomen. De afbeelding is **geen vrij te hergebruiken 3D-model**. De TeamSpeak-naam en -merken zijn van hun respectievelijke rechthebbenden. Dit communityproject is niet officieel aangesloten bij TeamSpeak Systems.

## 🧪 Status

Het project is als broncode geleverd. Het is in deze omgeving **niet met de Godot-editor opgestart of op Windows getest**; voer de eerste import en build uit in Godot of via de GitHub Actions-workflow. Problemen kunnen worden gemeld via GitHub Issues.
