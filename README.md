# iOS-Simulator am PC

iPhone und iPad am Windows-PC bedienen, mit **echtem iOS** (aktuell iOS 27) und deiner eigenen App, z. B. FreeNotes.

> © zazafnr – alle Rechte vorbehalten. Der Code ist zum Ansehen öffentlich, aber nicht freigegeben: ohne Lizenz darf ihn niemand kopieren, verändern oder weitergeben.

## Wie es funktioniert

iOS läuft nur auf Apple-Hardware. Die PC-App startet deshalb über GitHub Actions in **diesem öffentlichen Repo** einen Mac in der Cloud. In öffentlichen Repos sind die Mac-Minuten kostenlos. Auf dem Mac laufen Apples offizielle iPhone- und iPad-Simulatoren, und die PC-App zeigt sie in Gerätefenstern:

```
Windows-PC (PC-App)  ⇄  Cloudflare-Tunnel  ⇄  Cloud-Mac (GitHub Actions in IOSforPC)
  Gerätefenster                               iOS-Simulator iPhone + iPad
  Maus = Finger, Tastatur                     Steuer-Server (server/)
                                                 ↑ holt die App aus dem privaten Repo (notes)
```

**Dein App-Code bleibt privat:**

- Die App liegt im privaten Repo `zazafnr/notes`. Der Mac liest sie nur über das Secret `APP_REPO_TOKEN` (Lesezugriff).
- Der Code liegt nur auf dem Mac, solange die Sitzung läuft, und wird danach mit dem Mac gelöscht.
- Build-Ausgaben und Inhalte der App erscheinen **nicht** in den öffentlichen Protokollen. Das Build-Protokoll siehst du nur in der PC-App.
- Die Verbindung zum Mac ist mit einem Schlüssel geschützt, den nur deine PC-App kennt.

## Einrichten (einmalig)

1. **PC-App laden:** Unter **[Releases → latest](https://github.com/zazafnr/IOSforPC/releases/tag/latest)** gibt es `iOS-Simulator-Setup-….exe` (Installer) und `…-portable.exe` (ohne Installation).
   - Windows warnt beim ersten Start, weil die App nicht signiert ist: **Weitere Informationen → Trotzdem ausführen**.
2. **GitHub-Token anlegen:** <https://github.com/settings/personal-access-tokens/new>
   - *Repository access*: »Only select repositories« → **IOSforPC** und **notes**
   - *Repository permissions*: **Actions** = Read and write, **Secrets** = Read and write, **Contents** = Read-only, **Commit statuses** = Read-only
3. Token in der PC-App einfügen und auf **Prüfen & speichern** klicken. Die PC-App legt dann im Repo IOSforPC das Secret `APP_REPO_TOKEN` an, mit dem der Mac deine App lesen darf.
   - Klappt das nicht, legst du es selbst an: IOSforPC → Settings → Secrets and variables → Actions → *New repository secret*, Name `APP_REPO_TOKEN`, Wert: ein Token mit Lesezugriff (Contents) auf `notes`.

## FreeNotes am iPhone und iPad öffnen

1. PC-App starten.
2. **iPhone** und **iPad** anhaken.
3. Bei **App zum Testen** steht schon `claude/chat-ios-notizbuch-ki-yx5ny3`, der Branch mit FreeNotes.
4. **▶︎ Starten**. Nach etwa 5–8 Minuten gehen zwei Fenster auf, ein iPhone und ein iPad.
5. FreeNotes ist **schon installiert und geöffnet**. Später öffnest du es wie auf dem echten Gerät:
   - Mit **▶** oben in der Leiste rechts öffnest du deine App direkt.
   - Oder du gehst mit **⌂** (Strg+H) zum Home-Bildschirm und tippst dort auf das Symbol **FreeNotes**.
6. In FreeNotes unter Einstellungen **»Mit dem Finger zeichnen«** einschalten. Der Simulator hat keinen Apple Pencil, so schreibt die Maus wie ein Stift.
7. Code geändert und gepusht? Dann klickst du auf **⚒ App neu bauen**. Nach 1–2 Minuten läuft der neue Stand.
8. Fertig: **■ Beenden** in der PC-App. Das Schließen der PC-App beendet die Sitzung ebenfalls.

## Bedienung

| Am PC | Am Gerät |
|---|---|
| Linksklick / Ziehen | Tippen / Wischen, Zeichnen |
| Maustaste gedrückt halten oder Rechtsklick | Langes Drücken |
| Mausrad | Scrollen |
| Alt gedrückt halten + ziehen | Zwei Finger (gespiegelt um die Bildschirmmitte) |
| Strg + Mausrad | Zoom-Geste |
| Vom unteren Bildschirmrand nach oben ziehen | Home-Geste |
| Tastatur (auch ä, ö, ü, ß, @, €) | Tastatur |
| Strg+H / Strg+Umschalt+H | Home / App-Umschalter |
| Strg+L | Sperren |
| Strg+← / Strg+→ | Drehen |
| Strg+S | Bildschirmfoto (in *Bilder\iOS-Simulator*) |
| Strg+V / Strg+C | Einsetzen / Kopieren, abgeglichen mit dem PC |

Außerdem in der Leiste: eigene App öffnen, Siri, Schütteln, Hell/Dunkel, Fotos hinzufügen, Link öffnen, App neu bauen, App-Daten sichern/laden, App-Protokoll, Bildqualität, »Immer im Vordergrund«.

## Profile: »wie mein iPhone«

Ein Profil übernimmt:
- deine **Fotos & Videos** aus einem Ordner
- **Kontakte** (`.vcf`)
- **Sprache & Region**, **Hell/Dunkel**, **Standort** und das **Gerätemodell**

Mit **App-Daten behalten** werden die Daten deiner App (z. B. Hefte in FreeNotes) am Ende gesichert und beim nächsten Start wieder eingespielt.

**Nicht übertragbar** sind Apps aus dem App Store, iCloud- oder iTunes-Backups und Apple-ID-Daten. Apple bindet sie an echte Geräte.

## Was der Simulator nicht kann

- Kamera und Dokumentenscanner
- Apple Pencil (Druck und Neigung)
- Face ID (nur simuliert)
- Telefonie und Push-Benachrichtigungen von Apple

Das Bild kommt mit etwa 10–20 Bildern pro Sekunde und etwas Verzögerung an, weil der Mac in den USA steht.

## Mac-Minuten

In diesem **öffentlichen** Repo zahlst du für die Standard-Macs von GitHub Actions nichts. Ein Lauf darf bis zu 6 Stunden dauern, und GitHub erlaubt bei Free-Konten bis zu 5 Macs gleichzeitig. Die Sitzung endet nach der gewählten Dauer von selbst, außerdem nach 15 Minuten ohne verbundenes Fenster.

## Technik

| Ordner | Inhalt |
|---|---|
| `.github/workflows/ios-simulator.yml` | Cloud-Mac: Xcode wählen, App holen und bauen, Simulatoren starten, Tunnel öffnen |
| `.github/workflows/simulator-desktop.yml` | baut die Windows-App und legt sie als Release `latest` ab |
| `runner/` | Skripte auf dem Mac, dazu `simhelper.swift` (Video aus dem Bildspeicher, Drehen, zwei Finger) |
| `server/` | Steuer-Server (Node): Video, Live-Touch über den HID-Broker von [AXe](https://github.com/cameroncooke/AXe), `simctl` |
| `desktop/` | PC-App (Electron): Startfenster, Profile, Gerätefenster |
| `test/` | Tests mit nachgebautem Mac und GitHub, Selbsttest auf dem echten Mac (`live-check.js`) |

Lokal testen (ohne Mac):

```bash
cd server && npm ci && cd ..
node test/server.test.js
node test/github.test.js
```
