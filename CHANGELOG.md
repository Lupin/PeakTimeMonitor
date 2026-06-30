# PeakTimeMonitor — Changelog

## v1.2.4 (30 June 2026)

### Fixed
- Time format toggle now instantly refreshes all views (edit + read mode)

## v1.2.3 (30 June 2026)

### Fixed
- Time columns widened to 72px so AM/PM fits on one line

## v1.2.2 (30 June 2026)

### Fixed
- Time pickers now respect 12h (AM/PM) format both in edit and read mode

## v1.2.1 (30 June 2026)

### Fixed
- Time picker dropdown adapted to selected format (12h or 24h)

## v1.2.0 (30 June 2026)

### Added
- Customizable label above traffic light (default "DeepSeek", editable in preferences)
- Time format toggle: 24h or 12h (AM/PM) in preferences

## v1.1.1 (30 June 2026)

### Added
- 6 new languages: Japanese, Simplified Chinese, Korean, Russian, Spanish, German

## v1.1.0 (30 June 2026)

### Added
- French/English localization (String Catalog, 40 keys)

## v1.0.12 (30 June 2026)

### Added
- Compact 140x190 window with animated traffic light (green/orange/red)
- Menu bar icon with 3 monochrome dots (template)
- Preferences (Cmd+,): slot editing per day, 15-minute increments
- Configurable orange delay (5 to 60 minutes)
- Auto-refresh timer every 30 seconds
- "All days" mode (Mon-Fri) for recurring slots
- DMG format for easy distribution
- Self-contained build via build.sh (XcodeGen + xcodebuild)
- Fully documented code (152 /// DocC comments)
- Version displayed in preferences (read from Info.plist)
- CHANGELOG.md included in DMG

### Changed
- Native AppKit architecture (NSStatusBar + NSWindow + NSHostingView) replaces SwiftUI MenuBarExtra
- Default slots: 2 "All days" slots instead of 10 per-day slots

### Fixed
- "Show" in menu bar not working (51 debug commits)
- Preferences inaccessible outside Xcode (manual NSWindow fallback)
- GENERATE_INFOPLIST_FILE disabled so manual Info.plist is respected
