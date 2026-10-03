> **Neu: [VOID DICE](VoidDice/README.md)** – das RNG-/Collection-Spiel liegt als eigenes Rojo-Projekt im Ordner `VoidDice/`.
> Der Gleiter-Prototyp unten ist unverändert.

# Gleiter-Prototyp (Roblox)

Erster lokaler Test-Prototyp: Der Spieler hängt unter einem Hängegleiter und
fliegt automatisch durch eine Teststrecke von ca. 75 Sekunden. Der Prototyp soll
nur eine Frage beantworten: **Macht das Fliegen Spaß?**

Es wird nichts veröffentlicht oder hochgeladen. Alles läuft lokal in Roblox Studio.

---

## 1. Schnellstart (empfohlen)

1. Am PC dieses Repo herunterladen (GitHub → *Code* → *Download ZIP*) und entpacken.
2. Die Datei **`build/GliderPrototype.rbxlx`** doppelklicken. Alternativ:
   Roblox Studio → *File* → *Open from File…*
3. In Studio auf **Play** (F5) drücken.

Das war's. Die Map baut sich beim Start automatisch auf. Im Bearbeitungsmodus
ist die Welt deshalb leer, das ist so gewollt.

> Die `.rbxlx`-Datei wird mit Rojo aus dem Ordner `src/` gebaut. Wer Scripts
> ändert, kann sie mit `rojo build default.project.json -o build/GliderPrototype.rbxlx`
> neu bauen oder direkt in Studio weiterarbeiten.

---

## 2. Explorer-Struktur

```
ReplicatedStorage
└── GliderShared                (Folder)
    └── Config                  (ModuleScript)   ← alle Tuning-Werte

ServerScriptService
└── GliderServer                (Script)
    ├── MapBuilder              (ModuleScript)   ← Baukasten für die Map
    ├── TrackLayout             (ModuleScript)   ← die Teststrecke selbst
    └── GliderRig               (ModuleScript)   ← Gleiter-Modell am Charakter

StarterPlayer
└── StarterPlayerScripts
    └── GliderClient            (LocalScript)
        ├── RunManager          (ModuleScript)   ← Ablauf: Countdown, Run, Crash, Ziel
        ├── FlightController    (ModuleScript)   ← Flugphysik (Arcade)
        ├── CameraController    (ModuleScript)   ← Verfolgerkamera + FOV
        ├── InputController     (ModuleScript)   ← Tastatur / Controller / später Mobile
        ├── CheckpointSystem    (ModuleScript)   ← Checkpoints + Ziel erkennen
        ├── CrashSystem         (ModuleScript)   ← Kollision + Crash-Effekt
        ├── HUD                 (ModuleScript)   ← Test-UI
        └── SpeedEffects        (ModuleScript)   ← Wind-Partikel
```

Zur Laufzeit entstehen zusätzlich:

- `Workspace > GliderMap` mit den Ordnern `Solid` (Kollision) und `Decor` (nur Optik)
- `ReplicatedStorage > GliderTrackData` (Positionen von Start, Checkpoints und Ziel)
- `Character > Glider` (das Gleiter-Modell)
- `PlayerGui > GliderHUD`

## 3. Manuell einfügen (ohne .rbxlx-Datei)

Falls du die Scripts lieber selbst in ein bestehendes Place einfügst:

1. **ReplicatedStorage**: Ordner `GliderShared` anlegen, darin ein **ModuleScript**
   `Config` erstellen und den Inhalt von `src/shared/Config.luau` hineinkopieren.
2. **ServerScriptService**: ein **Script** `GliderServer` mit dem Inhalt von
   `src/server/GliderServer/init.server.luau`. Darunter, also als Kinder des
   Scripts, drei **ModuleScripts**: `MapBuilder`, `TrackLayout` und `GliderRig`,
   jeweils aus der gleichnamigen `.luau`-Datei.
3. **StarterPlayer > StarterPlayerScripts**: ein **LocalScript** `GliderClient`
   mit dem Inhalt von `src/client/GliderClient/init.client.luau`. Darunter acht
   **ModuleScripts** mit den gleichnamigen Dateien aus `src/client/GliderClient/`.
4. Empfohlen: `Workspace` → Eigenschaft **StreamingEnabled** ausschalten. Die
   Map ist zwar als „Persistent“ markiert, ohne Streaming ist es aber am sichersten.
5. Play drücken.

Die Namen müssen exakt stimmen, weil die Scripts sich über `script.Parent.<Name>`
und `WaitForChild("<Name>")` finden.

---

## 4. Steuerung

| Aktion             | PC             | Controller         |
|--------------------|----------------|--------------------|
| Links / Rechts     | A / D (oder ← →) | linker Stick       |
| Hoch / Runter      | W / S (oder ↑ ↓) | linker Stick       |
| Neuer Run          | R oder Reset-Button | Y / Select      |

Der Gleiter fliegt automatisch nach vorne. Laufen gibt es nicht.

---

## 5. Wie die Flugsteuerung funktioniert

Das ist bewusst keine echte Flugsimulation, sondern ein Arcade-Modell mit
weich geglätteten Werten (`FlightController.luau`):

1. **Eingabe glätten:** Die Tastenwerte (-1…1) werden nicht direkt benutzt.
   Sie nähern sich dem Ziel bildratenunabhängig an. Dadurch reagiert die
   Steuerung direkt, aber ohne Ruckeln.
2. **Lenken (A/D):** Ändert den Kurs mit einer maximalen Drehrate. Gleichzeitig
   neigt sich der Gleiter sichtbar zur Seite, bis `MaxBankAngle`.
3. **Hoch/Runter (W/S):** Stellt einen Nick-Winkel ein. Lässt man los, richtet
   sich der Gleiter automatisch wieder waagerecht aus.
4. **Tempo:** Im Sturzflug wird man schneller (bis `MaxSpeed`), beim Steigen
   langsamer. Das sorgt für Geschwindigkeitsgefühl und eine Risiko-Abwägung.
5. **Trägheit:** Die tatsächliche Geschwindigkeit folgt der Blickrichtung
   leicht verzögert (`VelocityResponse`). Dadurch „trägt“ der Gleiter etwas aus der Kurve.
6. **Umsetzung:** Pro Frame werden nur die Zielwerte von zwei Constraints am
   HumanoidRootPart gesetzt: `LinearVelocity` für die Bewegung und
   `AlignOrientation` für die Neigung. Der Humanoid steht auf `PlatformStand`.

**Kollision:** Der Spieler kollidiert physikalisch nicht mit der Map (eigene
Kollisionsgruppe). Stattdessen schiebt `CrashSystem` pro Frame eine Box in
Gleitergröße per `Blockcast` entlang der Bewegung, mit etwas Vorausschau.
Trifft sie ein Teil aus `GliderMap/Solid`, ist das ein Crash. Das ist eine
einzige Abfrage pro Frame, auch bei hohem Tempo gibt es kein Durchtunneln, und
der Gleiter stoppt vor der Wand.

**Kamera:** Die Position folgt dem Gleiter exakt, die Ausrichtung leicht
verzögert. In Kurven schwingt die Kamera so weich mit, ohne zu wackeln. Die
Kamera rollt nur zu 30 % mit, damit einem nicht schlecht wird. Bei hohem Tempo
wird das FOV etwas größer und der Abstand etwas weiter.

**Ablauf (RunManager):** `Countdown → Flying → Crashed → Respawning → Flying … → Finished`.
Ein Crash kann nur im Zustand `Flying` ausgelöst werden, deshalb gibt es
keine Mehrfach-Crashes. Ein Reset macht alte, verzögerte Aufrufe ungültig.
Die Zeit läuft während Crash und Respawn weiter, das ist die Zeitstrafe.

---

## 6. Werte zum Feintuning (`Config.luau`)

Alle Werte stehen in **ReplicatedStorage > GliderShared > Config**. Ändern,
Play drücken, testen.

**Geschwindigkeit** (`Config.Flight`)

| Wert                | Standard | Wirkung |
|---------------------|----------|---------|
| `BaseSpeed`         | 95       | Grundtempo im Geradeausflug |
| `DiveSpeedBonus`    | 40       | Zusätzliches Tempo im vollen Sturzflug |
| `ClimbSpeedPenalty` | 20       | Tempoverlust beim vollen Steigen |
| `MinSpeed` / `MaxSpeed` | 60 / 140 | Grenzen |
| `SinkRate`          | 2        | Leichtes Absinken (0 = aus) |

**Lenkstärke**

| Wert            | Standard | Wirkung |
|-----------------|----------|---------|
| `MaxYawRate`    | 62       | Wie scharf man Kurven fliegen kann (Grad/s) |
| `MaxPitchAngle` | 32       | Wie steil man steigen/sinken kann |
| `MaxBankAngle`  | 42       | Sichtbare Schräglage beim Lenken |
| `VisualPitchFactor` | 0.7  | Wie stark der Gleiter sichtbar nickt |

**Trägheit / Weichheit** (höher = direkter, niedriger = träger)

| Wert                  | Standard | Wirkung |
|-----------------------|----------|---------|
| `SteerResponse`       | 4.5      | Wie schnell Links/Rechts anspricht |
| `PitchResponse`       | 4.0      | Wie schnell Hoch/Runter anspricht |
| `BankResponse`        | 5.0      | Wie schnell sich der Gleiter seitlich neigt |
| `VelocityResponse`    | 7.0      | Wie schnell die Flugbahn der Nase folgt (Trägheit) |
| `SpeedResponse`       | 1.6      | Wie schnell sich das Tempo ändert |

**Kamera** (`Config.Camera`): `Distance`, `Height`, `LookAhead`,
`RotationResponse` (Verzögerung), `RollFactor`, `BaseFOV`, `MaxFOVBoost`.

**Crash** (`Config.Crash`): `BoxSize` (Kollisionsbox, kleiner = fairer),
`RespawnDelay`, `FreezeAfterRespawn`, `MaxAltitude`.

Die Strecke selbst änderst du in **`TrackLayout`**. Jeder Abschnitt ist
kommentiert, und Tore, Säulen und Blöcke sind einzelne Zeilen mit Distanz, Position und Größe.

---

## 7. Teststrecke

| # | Abschnitt              | Was getestet wird |
|---|------------------------|-------------------|
| 1 | Breiter Startbereich   | Startklippe, Felstürme, großes Einstiegstor |
| 2 | Große Felswände        | Slalom um Wandblöcke, Rechtskurve, Überhang |
| 3 | Tore                   | 5 Wände mit Öffnungen in verschiedenen Höhen/Seiten |
| 4 | Schlucht               | Schmal (100), Links- und Rechtskurve, Felsvorsprünge, Felsbrücke |
| 5 | Enge Passagen          | 50 breite Engstelle, Säulen-Slalom, versetzte Passagen links/rechts |
| 6 | Tunnel                 | 320 lang, innen 50×40, mit Hindernis oben und unten |
| 7 | Hoch und Runter        | 6 Wände mit waagerechten Schlitzen in wechselnder Höhe |
| 8 | Finale                 | Kleine Tore, Säulen, Linkskurve, sehr enge letzte Tore |
| 9 | Ziel                   | Zieltor mit Schachbrettboden, Ausrollbereich |

8 Checkpoints plus Ziel, Streckenlänge ca. 7300 Studs, also etwa 75 Sekunden.
Wer über die Wände steigt (über `MaxAltitude` = 165), crasht ebenfalls.

---

## 8. Testen: Checkliste

- [ ] Nach dem Countdown 3-2-1 fliegt der Gleiter automatisch los
- [ ] A/D lenkt weich, der Gleiter neigt sich zur Lenkseite
- [ ] W/S steigt/sinkt, beim Loslassen richtet er sich wieder aus
- [ ] Im Sturzflug steigt das Tempo (Anzeige oben links), das FOV wird größer
- [ ] Gegen eine Wand fliegen: roter Blitz, „CRASH!“, Explosion, nach ca. 1 s zurück zum letzten Checkpoint
- [ ] Checkpoints färben sich beim Durchfliegen grün, die Anzeige zählt hoch
- [ ] Im Ziel wird die Zeit angezeigt, die Bestzeit wird gemerkt (nur für die Sitzung)
- [ ] R oder der Reset-Button startet einen neuen Run

In der **Output**-Konsole erscheint beim Start z. B.
`[GliderServer] Teststrecke gebaut: 853 Parts, Länge 7460 Studs`.

---

## 9. Später erweitern

- **Mobile:** In `InputController` gibt es `SetExternalInput(Vector2)`. Ein
  Touch-Joystick muss nur diese Funktion aufrufen. Am Flugcode muss nichts geändert werden.
- **Controller:** Der linke Stick funktioniert bereits.
- **Neue Strecken:** Weitere Layouts nach dem Muster von `TrackLayout` bauen.
- **Multiplayer:** Der Gleiter wird schon jetzt vom Server angebaut, und die
  Bewegung repliziert automatisch. Crash- und Checkpoint-Logik laufen aktuell
  auf dem Client und müssten für echte Rennen auf dem Server geprüft werden.

## Bekannte Vereinfachungen

- Der Charakter hängt aufrecht unter dem Gleiter (nicht liegend). Bei
  R15-Avataren gehen die Arme nach oben zum Steuerbügel, bei R6 nicht.
- Die Kollisionsbox ist etwas kleiner als das sichtbare Segel, damit es fair
  bleibt. Wenn die Flügelspitzen eine Wand streifen, gibt es deshalb noch keinen Crash.
- Die Bestzeit wird nicht gespeichert.
