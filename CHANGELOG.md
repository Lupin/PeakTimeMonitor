# PeakTimeMonitor — Changelog

## v1.0.12 (30 juin 2026)

### Première release publique

- 🚦 Fenêtre compacte 140×190 avec feu tricolore animé (vert/orange/rouge)
- 📌 Icône barre de menu avec 3 cercles monochromes (template)
- ⚙️ Préférences (Cmd+,) : édition des créneaux par jour, par tranches de 15 minutes
- 🕐 Délai orange paramétrable (5 à 60 minutes)
- 🔄 Timer de rafraîchissement automatique toutes les 30 secondes
- 📦 Mode "Tous les jours" (lun-ven) pour les créneaux récurrents
- 🍎 Architecture AppKit native (NSStatusBar + NSWindow + NSHostingView)
- 🖤 Support thème clair/sombre/monochrome natif
- 📱 Format DMG pour distribution facile
- 🔧 Build autosuffisant via `build.sh` (XcodeGen + xcodebuild)
- 📝 Code entièrement documenté (152 commentaires /// DocC)
- 🪪 Version affichée dans les préférences (lue depuis Info.plist)
