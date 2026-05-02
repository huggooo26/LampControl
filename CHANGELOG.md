# Changelog

All notable changes to LampControl are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned

- Apple notarization and Developer ID signature.
- HomeKit bridge and automation triggers.
- Full English UI localization.

## [1.0.10] - 2026-05-02

### Fixed

- Tuya: "Lampe inconnue" error after sync — the internal device cache was
  keyed by the full prefixed ID (`tuya:XXXXX`) but control actions passed the
  native ID. Cache is now keyed by `nativeID`, matching what AppState sends.
- Sparkle update feed URL corrected from the old GitHub username
  (`huggooo26.github.io`) to `hugoinformatique.github.io`; update checks now
  resolve correctly.
- App icon now displayed in Finder/Applications folder; `AppIcon.icns` is
  embedded in the bundle via `build_app.sh` and referenced in `Info.plist`.

## [1.0.9] - 2026-05-02

### Fixed

- Tuya: commands (power, brightness, temperature, color) were sent to the wrong
  API endpoint because the full prefixed device ID (`tuya:XXXXX`) was used
  instead of the native device ID. Sync worked correctly; only control actions
  were affected.

## [1.0.8] - 2026-04-28

### Added

- LIFX Cloud provider with personal-token authentication, lamp sync, and full
  power/brightness/temperature/color controls.
- Govee Cloud provider with API key authentication, device state retrieval,
  and full controls (HSV → RGB conversion handled client-side).
- Yeelight LAN provider over JSON-RPC port 55443 using `Network.framework`,
  with manual IP entry, per-bulb persistence, and graceful offline detection.
- Dedicated provider settings pages for Govee and Yeelight (add/remove bulbs,
  Keychain-stored API keys).
- Bilingual configuration guide updated with end-to-end setup instructions
  and troubleshooting for all five providers.

### Changed

- The provider overview now treats every brand as implemented; the "Bientôt"
  placeholder is gone.
- README and CONFIGURATION docs restructured around the five-provider matrix.

## [1.0.7] - 2026-04-26

### Added

- Started the multi-provider architecture with a generic light provider layer,
  a Tuya provider adapter, and a provider settings overview ready for Philips
  Hue, LIFX, Yeelight, and Govee.
- Added the first Philips Hue integration with bridge discovery, local pairing,
  secure keychain storage, lamp sync, and light controls.
- Quick RGB scene presets can now apply Focus, Relax, Neon, or Night ambiance
  to the selected lamps, or to every online RGB lamp when nothing is selected.
- Custom RGB scenes can now be created, edited, deleted, persisted locally,
  and applied with the same selected-or-all RGB targeting behavior.
- Added the first Premium/Early Access licensing foundation with local
  entitlements, a Premium settings panel, and feature gates ready for server
  validation.
- Added the Lemon Squeezy activation flow with license activation, validation,
  deactivation, and configurable product checks.

## [1.0.6] - 2026-04-25

### Added

- Settings now use an Apple Settings-inspired menu/submenu layout with
  dedicated Tuya, devices, updates, and about panels.
- First-run onboarding now guides new users through the Tuya setup flow with
  direct actions for Settings and the configuration guide.

### Changed

- The app now follows the Mac's current light or dark appearance instead of
  forcing the light theme.
- Static glass surfaces now use a calmer fallback rendering to avoid visible
  wave/refraction artifacts in dense dark-mode lists.
- Popover rendering now favors lightweight surfaces and disables resize/open
  animations so sliders and buttons remain responsive.

### Fixed

- RGB color changes preserve the current color brightness value instead of
  unexpectedly dimming compatible LED strips.
- Tuya `colour_data` scaling now follows the device specification when
  available, avoiding 0...255 scaling on LED strips that expect 0...1000 HSV.

## [1.0.5] - 2026-04-25

### Added

- Guided Tuya setup checklist in Settings with completion state and a direct
  configuration guide shortcut.
- "Save and test" Settings action that stores credentials and immediately
  runs a lamp sync.
- Warm/cool white temperature controls for Tuya lamps that expose
  `temp_value` or `temp_value_v2`.

### Fixed

- Tuya ON/OFF commands now use the switch code reported by each device
  instead of assuming every lamp supports `switch_led`.
- Warm/cool white updates no longer force `work_mode = white`, which some
  white-only E27 bulbs reject with Tuya error 2008.
- RGB+CCT bulbs now use their dedicated `bright_value` capability for
  brightness instead of incorrectly changing the HSV color value.
- Legacy Tuya `colour_data` colors are now scaled to the older 0...255
  saturation/value range instead of the v2 0...1000 range.
- Color and white-temperature updates retry without `work_mode` when a device
  rejects the batched mode switch.
- Tuya command failures now include the command codes that were attempted,
  making device-specific compatibility bugs easier to diagnose.
- Popover resizing is now debounced and the global size animation removed so
  sliders feel more responsive.
- Liquid Glass fallbacks are lighter, less shadow-heavy, and button surfaces
  stay visible on macOS versions without native glass button styles.

## [1.0.4] - 2026-04-25

### Fixed

- Release builds now set `CFBundleVersion` to the same value advertised in
  the appcast so Sparkle does not keep offering the same update.

## [1.0.3] - 2026-04-25

### Fixed

- Release packaging now strips extended attributes before signing Sparkle
  bundles and stages the DMG from a clean temporary directory, avoiding
  codesign failures caused by Finder metadata on nested Sparkle helpers.

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

[Unreleased]: https://github.com/huggooo26/LampControl/compare/v1.0.6...HEAD
[1.0.6]: https://github.com/huggooo26/LampControl/compare/v1.0.5...v1.0.6
[1.0.5]: https://github.com/huggooo26/LampControl/compare/v1.0.4...v1.0.5
[1.0.4]: https://github.com/huggooo26/LampControl/compare/v1.0.3...v1.0.4
[1.0.3]: https://github.com/huggooo26/LampControl/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/huggooo26/LampControl/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/huggooo26/LampControl/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/huggooo26/LampControl/releases/tag/v1.0.0
