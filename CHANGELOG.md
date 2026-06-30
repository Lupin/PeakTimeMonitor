# PeakTimeMonitor — Changelog

## v1.1.0 (30 juin 2026)

### Added
- Localisation francais/anglais (String Catalog, 40 cles)

## v1.0.12 (30 juin 2026)

### Added
- Fenetre compacte 140x190 avec feu tricolore anime (vert/orange/rouge)
- Icone barre de menu avec 3 cercles monochromes (template)
- Preferences (Cmd+,) : edition des creneaux par jour, par tranches de 15 minutes
- Delai orange parametrable (5 a 60 minutes)
- Mode "Tous les jours" (lun-ven) pour les creneaux recurrents
- Format DMG pour distribution facile
- Build autosuffisant via build.sh (XcodeGen + xcodebuild)
- Code entierement documente (152 commentaires /// DocC)
- Version affichee dans les preferences (lue depuis Info.plist)
- CHANGELOG.md inclus dans le DMG

### Changed
- Architecture AppKit native (NSStatusBar + NSWindow + NSHostingView) remplace MenuBarExtra SwiftUI
- Slots par defaut : 2 creneaux "Tous les jours" au lieu de 10 creneaux jour par jour

### Fixed
- "Afficher" dans le menu barre ne fonctionnait pas (51 commits de debug)
- Preferences inaccessibles hors Xcode (fenetre NSWindow manuelle en fallback)
- GENERATE_INFOPLIST_FILE desactive pour que le Info.plist manuel soit respecte
