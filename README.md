# PeakTimeMonitor 🚦

Mini app macOS native qui affiche un feu tricolore pour les heures de pointe DeepSeek (tarif ×2).

**Fenêtre compacte** + **icône barre de menu** avec indicateur visuel. Préférences pour personnaliser les créneaux.

## Fonctionnalités

- 🟢🟠🔴 Feu tricolore : vert (off-peak), orange (peak dans <N min), rouge (peak actif)
- 📌 Icône barre de menu : 3 cercles monochromes, toujours visible
- ⏱ Timer 30s + rafraîchissement automatique
- ⚙️ Préférences (Cmd+,) : créneaux par jour, par 15 minutes, délai orange paramétrable
- 🌓 Support dark/light/monochrome natif

## Build & Lancer

### Prérequis
- macOS 14+
- Xcode 16+ (ou Command Line Tools)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build rapide (sans Xcode)

```bash
git clone https://github.com/Lupin/PeakTimeMonitor.git
cd PeakTimeMonitor
./build.sh          # Build + lance l'app
```

### Build manuel

```bash
xcodegen generate
xcodebuild -project PeakTimeMonitor.xcodeproj -scheme PeakTimeMonitor -configuration Debug -derivedDataPath .build/xcode build
open .build/xcode/Build/Products/Debug/PeakTimeMonitor.app
```

### Ouvrir dans Xcode

```bash
xcodegen generate
open PeakTimeMonitor.xcodeproj
# Puis Cmd+R
```

## Architecture

```
PeakTimeMonitorApp/
├── PeakTimeMonitorApp.swift   # @main : WindowGroup + MenuBarExtra + Settings
├── AppDelegate.swift          # NSApplicationDelegate (empêche quitter à la fermeture)
├── PeakTimeSlot.swift         # Modèle + logique currentState() + UserDefaults
├── FeuTricoloreView.swift     # Vue fenêtre + FeuViewModel + timer
├── SettingsView.swift         # Préférences (édition créneaux, délai orange)
├── Info.plist
├── PeakTimeMonitor.entitlements
└── Assets.xcassets/           # Icône app
```

## Licence

MIT
