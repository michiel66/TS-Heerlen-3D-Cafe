# TeamSpeak Heerlen – live vergaderkamer (branch `feature/live-meeting-overlay-v1`)

Deze uitbreiding toont een vergaderruimte als foto-overlay over het bestaande Godot-project. **Alleen echte TeamSpeak-gebruikers uit `roster_updated`** krijgen een 3D R1-avatar met hun naam bij een stoel. Offline blijft iedere stoel leeg. De bestaande audio/PTT in `bridge/main.cjs`, `scripts/teamspeak_bridge.gd`, `main.gd`, `hud.gd` en de volledige 3D-wereld blijven ongewijzigd.

## Afbeelding

Voeg de originele lege vergaderruimte uit de eerder aangeleverde ZIP toe op **`assets/meeting/meeting_room.png`**. De overlay start ook zonder deze afbeelding (met een donkere noodachtergrond), maar voor dezelfde uitstraling als de conceptafbeelding is dit PNG-bestand noodzakelijk. De GitHub-koppeling kan deze binaire PNG niet rechtstreeks vanuit de gesprekbijlage uploaden.

Originele ZIP: `TS-Heerlen-VERGADERAPP-LIVE-OVERLAY-v1-GITHUB-UPDATE.zip`, hierin staat `assets/meeting/meeting_room.png`. Open de branch en upload het PNG-bestand met het juiste pad.

## Functies

- Echte onlinegebruikers: maximaal acht R1-avatars in beeld, extra leden in de rechterlijst.
- Geen TeamSpeak-roster: lege stoelen, nooit fictieve bezoekers.
- Naam- en spreekindicator uit de bestaande TeamSpeak-signalen.
- PTT en verbinden/verbreken via `CafeHUD.action_requested`; TeamSpeak-audio blijft intact.
- Profiel, avatarselectie en wereldbeheer via het bestaande menu.
- 3D-werelden zijn bereikbaar via de knop **3D Werelden**.
- Dit is een **2.5D-weergave**; een zithouding is afhankelijk van de aanwezige R1-animatieclips.

## Testen

Na Godot-import:

```
godot --headless --path . --script res://tests/meeting_overlay_test.gd
```

Maak pas een Windows-release als GitHub Actions groen is en de overlay, PTT en gebruikerswisselingen op Windows zijn nagekeken.
