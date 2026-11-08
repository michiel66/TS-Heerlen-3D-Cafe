# TeamSpeak Heerlen 3D Café v0.4 — Live online bezoekers als avatars

**Nieuw:** zodra je met `Heerlen.MIJNTS3.NL` verbindt, worden de door TeamSpeak zichtbare online gebruikers als echte 3D-personages in het café geplaatst met hun eigen TeamSpeak-naam. Dit gebeurt via de al werkende v0.3 spraakmodule, zonder aanvullende TeamSpeak-plugin of 3D-server.

- Gebruikers krijgen een eigen avatar en shirtkleur; je eigen account wordt niet dubbel getoond.
- Avatars verschijnen, verdwijnen en krijgen bijgewerkte namen op basis van de ontvangen TS3-gebruikerslijst.
- Een spreker krijgt een zichtbaar ▶-symbool boven zijn avatar.
- De zes oude demo-avatars zijn verborgen wanneer TeamSpeak verbonden is.
- Onder **Gebruikers** kun je de hele ontvangen ledenlijst doorbladeren; linksboven staat de eerste tien plus de resttelling.
- De ingestelde posities zijn **lokale weergaveplekken**. Andere bezoekers lopen nog niet live met je mee; dat zou extra positiedata-uitwisseling tussen apps vragen.
- Welke gebruikers de client kan zien hangt af van kanaalabonnementen en TeamSpeak-permissies; de app kan verborgen leden niet inventariseren. Ook TeamSpeak ServerQuery meldt deze beperking.
- De werkende microfoon, PTT (V), Opus-audio en ingebouwde lokale bridge zijn behouden.

**Installeren:** upload de inhoud van de ZIP naar de root van `michiel66/TS-Heerlen-3D-Cafe`, inclusief verborgen `.github/workflows/windows.yml`. GitHub Actions bouwt `TS-Heerlen-3D-Cafe-Setup-v0.4.exe`.

**Tests:** Node.js bridge-tests via `npm test` in `bridge`, Godot `tests/smoke_test.gd` en `tests/online_avatars_test.gd`. Deze tests bevestigen geen echte TS3-verbinding; controleer na installatie met twee Windows-computers.

---

# TeamSpeak Heerlen 3D Café v0.3 – Direct TeamSpeak proefversie

**Een Windows-setup, geen TeamSpeak 3-plugin en geen losse 3D-server.**

De huidige Godot-caféwereld (bar, tafels, avatar, dansvloer, minimap en knoppen) blijft behouden. De setup bevat nu ook een lokale Node.js-sidecar die rechtstreeks met `Heerlen.MIJNTS3.NL` kan verbinden via de open-source `@honeybbq/teamspeak-client` bibliotheek, net als de PTT-Crosslink-software.

## Wat nieuw is

- TeamSpeak-verbinden en verbreken in het café zelf (zonder gewone TeamSpeak-client of plugin)
- TeamSpeak-naam en optionele kanaalnaam via **Instellingen**
- Live server-gebruikerslijst via `listClients`, en actualiseren bij binnenkomen, verplaatsen en vertrekken
- Sprekerindicator in het live-gebruikerspaneel (tijdens ontvangen audiopakketten)
- **V ingedrukt houden** om te praten; onderbalkknop schakelt PTT handmatig aan/uit
- Microfoon-capture in Godot, PCM/Opus-transcodering in lokale Node-module, ontvangen spraak via Godot-speakergenerator
- Eenmalige beveiligingstoken voor de lokale websocket op `127.0.0.1:39453`
- TeamSpeak-identiteit wordt op de eigen pc lokaal opgeslagen; geen wachtwoord wordt meegeleverd
- GitHub Actions bouwt zelfstandige Windows-exe met ingebouwde spraakmodule en Inno Setup-installer

## Voor bezoekers

1. Installeer de nieuwe `TS-Heerlen-3D-Cafe-Setup-v0.3.exe` uit GitHub Actions.
2. Start **TeamSpeak Heerlen 3D Café** (zonder losse Godot/Node/TS3-plugin).
3. Open **Instellingen** om je gebruikersnaam en eventueel TeamSpeak-kanaal in te vullen. Klik **Naam opslaan**.
4. Klik **VERBIND MET TEAMSPEAK**. Het paneel links vult de actuele gebruikerslijst.
5. Gebruik **V** ingedrukt om te spreken, of klik **Praten (PTT)** voor aan/uit. Gebruik bij voorkeur een headset.

**TeamSpeak-privacy:** de app maakt een eigen directe TeamSpeak-clientverbinding. Op dezelfde pc kan daarnaast nog de gewone TeamSpeak-client draaien, maar gebruik die niet tegelijk in hetzelfde kanaal met open microfoon om echo te voorkomen.

## Voor ontwikkelaars / GitHub

Upload de **inhoud** van deze projectmap naar de repository-root `michiel66/TS-Heerlen-3D-Cafe`, met de verborgen map `.github`. De build gebruikt Godot 4.7.2, Node.js 22 en Inno Setup 6. In GitHub **Actions → TeamSpeak Heerlen - Windows Setup** kan de nieuwe Windows-installer worden opgehaald.

Tests in dit pakket: `node --test bridge/tests/*.test.cjs` slaagt in deze omgeving. De Godot-runtime en echte TeamSpeak-server konden hier **niet live worden getest**; werkende bidirectionele spraak en online deelnemers moeten daarom na de GitHub-build op twee Windows-computers worden gevalideerd. De build voert een Godot-starttest uit.

## Bekende beperkingen

- Er is **geen server voor avatarpositie-synchronisatie**. Zes personages in het café blijven decoratieve demo-avatars, niet gekoppeld aan echte TeamSpeak-gebruikers. Alleen de gebruikerslijst is live.
- Bij gelijktijdige sprekers wordt voorlopig slechts één ontvangststream kort achter elkaar weergegeven om onbegrijpelijke audio te vermijden. Multispeaker-mixen is een volgende stap.
- TeamSpeak-kanaal wordt bij verbinden gekozen. Kanaal wisselen: verbreek de verbinding, wijzig kanaalnaam en verbind opnieuw.
- Specifieke server- en kanaalwachtwoorden worden nog niet ondersteund in deze proefversie.
- Spraakvertraging, audio-onderbrekingen, Windows-microfoonrechten en Opus codec 5 moeten in echte tests worden gecontroleerd.
- Ongetekende setup kan een Windows SmartScreen-waarschuwing geven. Publiceer alleen via je eigen gecontroleerde GitHub-repository.
- Ontwerpafbeelding `docs/voorbeeld-layout.png` blijft een **doelbeeld**, geen exacte screenshot van de realtime 3D-caféwereld.

### Techniek en licenties

De nieuwe bridge gebruikt `@honeybbq/teamspeak-client` 0.3.3 (MIT), `opusscript` 0.1.1 (MIT), `ws` 8.18.3 (MIT). De software is geen officiële TeamSpeak-client. De afhankelijkheden en hun licentiegegevens worden met de Windows-setup meegeleverd vanuit `node_modules`. Alleen voor de build moet GitHub npm kunnen bereiken.
