# TeamSpeak Heerlen 3D Café – LOOK v0.7

**Visuele upgrade, TeamSpeak-audio ongewijzigd.**

Nieuw: vriendelijkere, afgeronde 3D-personages met verschillende kapsels,
kleurtinten, kledingdetails en een lichtgevende spreekring bij online audio.
De bestaande naamlabels, wandelen, zitten, dansen en live online roster blijven werken.

Inrichting: warmere bar met fijn servies en verlichte espressomachine,
zachtere loungezitplaatsen, bankkussens, kunst aan de muur, houten wandpanelen,
nieuwe hanglampen en een herkenbare LOOK v0.7 bovenin.

## Installeren op GitHub

Download de **GITHUB-UPDATE-v0.7.zip**. Pak uit en upload de bestanden naar
https://github.com/michiel66/TS-Heerlen-3D-Cafe via Add file > Upload files,
met dezelfde mapstructuur. Bestaande bestanden overschrijven.
Klik Commit changes en kijk bij Actions > Maak Windows Setup.exe. Download het
artifact `TS-Heerlen-3D-Cafe-Setup-v0.7` als de workflow groen is.

De workflow compileert `TS-Heerlen-3D-Cafe-Setup-v0.7.exe` en controleert
zelf de startscene, de avatar-/spreekindicatiefuncties en de Node-tests.

## Wat NIET verandert

De bestanden `scripts/teamspeak_bridge.gd`, `bridge/main.cjs`,
`bridge/protocol.cjs`, `bridge/package.json`, `scripts/main.gd` en
`scripts/online_avatars.gd` zijn functioneel gelijk aan v0.6.
De nieuwe avatar ziet niet automatisch uit als de echte TeamSpeak-gebruiker:
er worden gestileerde, procedurele figuren gegenereerd op basis van gebruikersnaam.

### Als de build rood wordt
Open de rode stap bij GitHub Actions en stuur de foutmelding; de
Windows-versie kan hier niet worden gebouwd zonder Godot 4.7.2.
