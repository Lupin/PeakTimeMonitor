# PeakTimeMonitor — Changelog

## v1.0.12 (30 juin 2026)

### Premiere release publique

- Fenetre compacte 140x190 avec feu tricolore anime (vert/orange/rouge)
- Icone barre de menu avec 3 cercles monochromes (template)
- Preferences (Cmd+,) : edition des creneaux par jour, par tranches de 15 minutes
- Delai orange parametrable (5 a 60 minutes)
- Timer de rafraichissement automatique toutes les 30 secondes
- Mode "Tous les jours" (lun-ven) pour les creneaux recurrents
- Architecture AppKit native (NSStatusBar + NSWindow + NSHostingView)
- Support theme clair/sombre/monochrome natif
- Format DMG pour distribution facile
- Build autosuffisant via build.sh (XcodeGen + xcodebuild)
- Code entierement documente (152 commentaires /// DocC)
- Version affichee dans les preferences (lue depuis Info.plist)
