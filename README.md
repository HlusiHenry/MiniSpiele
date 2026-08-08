# MiniSpiele

Sechs schnelle Mini-Spiele gegen Langeweile — im Restaurant, im Auto, überall.

## Spiele

- **Würfelbecher** — 5 Würfel, Kniffel-Style. Schütteln zum Würfeln!
- **Reaktion** — Wie schnell bist du? Tippe wenn's grün wird!
- **WortRaten** — Deutsches Wordle. 5 Buchstaben, 6 Versuche.
- **TorSchießen** — Flick den Ball am Torwart vorbei!
- **Memory** — Klassisches Karten-Memory mit Emojis.
- **Schere Stein Papier** — Gegen den Computer.

## Technik

- SwiftUI
- iOS 18+
- iPhone & iPad
- Dark Mode
- Haptisches Feedback
- Highscores persistent

## Build

```bash
xcodebuild -project MiniSpiele.xcodeproj -scheme MiniSpiele \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO build
```

Oder in Xcode öffnen: `open MiniSpiele.xcodeproj`
