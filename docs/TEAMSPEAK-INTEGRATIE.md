# TeamSpeak-integratie: technisch ontwerp na de lokale demo

## Momenteel werkend

De knop `Verbind met TeamSpeak` geeft de URI `ts3server://Heerlen.MIJNTS3.NL` door aan Windows. Daarvoor moet de TeamSpeak 3-client geïnstalleerd zijn én de protocolhandler geregistreerd hebben. De game ontvangt zelf geen spraakdata.

## Voorstel voor een volgende release: geen aparte gameserver

1. Gebruik de officiële **TeamSpeak 3 Client Plugin SDK** voor de DLL. SDK-bronnen: https://github.com/teamspeak/ts3client-pluginsdk en https://teamspeak.com/en/downloads/.
2. Start in de Godot-app optioneel een lokaal IPC-kanaal op `127.0.0.1` (UDP of named pipe). Gebruik nooit een onbeschermd publiek TCP-listeneradres.
3. De TS3-plugin communiceert met deze lokale Godot-app en verzendt *kleine, begrensde* avatarupdates via `ts3Functions.sendPluginCommand` naar andere clients **met dezelfde plugin en in hetzelfde kanaal**.
4. Ontvangers verwerken updates met `ts3plugin_onPluginCommandEvent` en geven posities via IPC door aan hun lokale Godot-café.
5. Iedere client laat de eigen avatar zien en rendert de laatst bekende posities van anderen. Gebruik interpolatie voor vloeiende beweging. Houd pakketten en frequenties laag en voer praktijktesten uit.
6. Voor 3D-geluid zijn `systemset3DListenerAttributes` en `channelset3DAttributes` in de API opgenomen. Test op werkelijke plugin-client-versies; geluid buiten het eigen kanaal is hiermee niet automatisch mogelijk.

**Belangrijk:** pakketfrequentie, beveiliging, foutafhandeling, kanaalpermissies en compatibiliteit moeten apart worden onderzocht. Dat zit niet in versie 0.1. Er is bewust geen fictieve “werkende TeamSpeak DLL” toegevoegd.

## Privacy en veiligheid

- Open poorten of doorgegeven posities alleen voor gebruikers die bewust deelnemen.
- Valideer ID, lengte en schema van plugin-commando's.
- Geen gebruikersnamen/passwords/token naar een extern serverendpoint versturen.
- Gebruik voor nickname/ID geen onbeperkte doorzoekbare profielen.
- Scheid de multiplayer-plugin van de game zodat het café zonder TeamSpeak kan draaien.

## Bronvermeldingen

- TeamSpeak TS3 Client Plugin SDK: https://github.com/teamspeak/ts3client-pluginsdk
- TeamSpeak 3D Sound API: https://teamspeakdocs.github.io/PluginAPI/client_html/ar01s20.html
- Godot Windows export: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_windows.html
