# Changelog

All notable changes to LampControl are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Multi-vendor support (Philips Hue, LIFX, Yeelight, Govee).
- Freemium licensing layer (free: ON/OFF + 2 lamps; lifetime: full features).
- Onboarding modal and refreshed settings layout.

## [1.0.2] - 2026-04-25

### Fixed

- Bundle `LampControl.app` now embeds the correct `LC_RPATH` entry
  (`@executable_path/../Frameworks`) so dyld can locate the bundled
  `Sparkle.framework` at launch. Previous builds aborted with
  `Library not loaded: @rpath/Sparkle.framework/...` because SwiftPM
  rpaths point into the build directory and aren't relocatable.

## [1.0.1] - 2026-04-25

### Fixed

- Appcast `<enclosure>` no longer carries a duplicated `length=` attribute.
  The release workflow now uses `sign_update -p` to grab only the EdDSA
  signature and assembles the enclosure tag manually, so Sparkle clients
  receive a clean appcast item.

## [1.0.0] - 2026-04-25

### Added

- Native macOS menu-bar app for Tuya / Smart Life lamps.
- Tuya Cloud API integration (sign-in, device sync, capability detection).
- Power toggle, brightness slider, RGB colour picker, group scene control.
- Auto-sync every 60 seconds when credentials are configured.
- Liquid-glass styled UI compatible with macOS 13+ and enhanced on macOS 26+.
- Keychain storage for the Tuya Access Secret; non-secret settings persisted
  to `~/Library/Application Support/LampControl/settings.json`.
- Sparkle 2 auto-update integration with EdDSA-signed appcast.
- "Check for Updates…" command in the status-bar menu and a dedicated
  "Mises à jour" section in the in-app settings.
- GitHub Actions release workflow that builds, signs, packages a DMG,
  signs the appcast, publishes a GitHub Release, and deploys the appcast
  to GitHub Pages on every `v*.*.*` tag.
- Bilingual documentation (English `README.md`, French `README.fr.md`,
  configuration guides under `docs/`).
- MIT licence and contributing guide.

[Unreleased]: https://github.com/huggooo26/LampControl/compare/v1.0.2...HEAD
[1.0.2]: https://github.com/huggooo26/LampControl/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/huggooo26/LampControl/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/huggooo26/LampControl/releases/tag/v1.0.0
