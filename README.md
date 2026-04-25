# LampControl

> A native macOS menu-bar app to control your smart lamps. Lightweight,
> liquid-glass styled, and keychain-secure.
>
> 🇫🇷 [Lire ce README en français](README.fr.md)

[![Latest release](https://img.shields.io/github/v/release/huggooo26/LampControl?label=release)](https://github.com/huggooo26/LampControl/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

LampControl lives in your macOS menu bar. Click the lightbulb icon to toggle
your lamps, change brightness, pick a colour, or apply a group scene without
leaving whatever you're doing.

Phase 1 ships with **Tuya / Smart Life** support. Multi-vendor support for
Philips Hue, LIFX, Yeelight and Govee is on the roadmap.

---

## Features

- 🪶 **Lightweight menu-bar app** — no dock icon, no Electron, ~5 MB.
- 💡 **Toggle, dim and recolour** any compatible Tuya lamp.
- 🎨 **Group scenes** — select multiple RGB lamps and apply one colour.
- 🔁 **Auto-sync** every 60 seconds, silently in the background.
- 🔐 **Keychain-stored Access Secret** — credentials never touch a plain text file.
- 🚀 **Auto-update via Sparkle** — push to `main`, users get notified next launch.
- 🆓 Open source under the MIT licence.

## Install

### Option A — Download the DMG

1. Grab the latest DMG from the
   [Releases page](https://github.com/huggooo26/LampControl/releases/latest).
2. Open `LampControl.dmg`, drag `LampControl.app` to `/Applications`.
3. **First launch only:** right-click → *Open* (the app is signed ad-hoc until
   we ship a notarised build — see [known limitations](#known-limitations)).
4. The lightbulb icon appears in your menu bar.

### Option B — Build from source

```bash
git clone https://github.com/huggooo26/LampControl.git
cd LampControl
./scripts/build_app.sh
open dist/LampControl.app
```

Requires macOS 13+, Xcode 15.4+ command-line tools, and Swift 5.9+.

## Quick start

1. Click the lightbulb in your menu bar.
2. Open the **Réglages / Settings** tab.
3. Paste your Tuya credentials (see the
   [step-by-step guide](docs/CONFIGURATION.md) — it takes ~5 minutes).
4. Click **Enregistrer**. Your lamps appear in the **Lampes** tab.

## Get your Tuya credentials

LampControl talks directly to the Tuya Cloud API. You need:

| Field | Where to find it |
| --- | --- |
| Access ID | Tuya IoT Platform → Cloud → Project → Authorization Key → *Access ID* |
| Access Secret | Same screen → *Access Secret* |
| Region | Pick the region closest to your lamps (Europe, US, China…) |
| UID | Tuya IoT Platform → Cloud → Project → *Linked Devices* → *Link Tuya App Account* → copy the UID |

The full walkthrough lives in
[docs/CONFIGURATION.md](docs/CONFIGURATION.md) (English) and
[docs/CONFIGURATION.fr.md](docs/CONFIGURATION.fr.md) (French).

## Auto-updates

LampControl uses [Sparkle](https://sparkle-project.org/) for in-app updates.

- Open **Réglages → Mises à jour** to check manually or toggle automatic
  checks / installs.
- Updates are signed with an EdDSA key; only releases signed by the project's
  maintainers will install.
- Right-click the menu-bar icon to access **Check for Updates…** without
  opening the popover.

## Roadmap

- **Phase 1 (now):** Tuya support, auto-update, bilingual docs, public release.
- **Phase 2:** Vendor abstraction + Philips Hue, LIFX, Yeelight, Govee.
- **Phase 3:** Freemium licensing — free tier (ON/OFF, 2 lamps), lifetime
  €10 unlock for colour, brightness, multi-vendor and unlimited lamps.
- **Phase 4:** Notarisation, automatic install on launch, onboarding tour.

## Known limitations

- 🔓 **Ad-hoc signature only.** Until a paid Apple Developer ID is enrolled,
  Gatekeeper will warn on first launch. Right-click → *Open* once and macOS
  remembers your choice.
- 🌍 **Tuya only for now.** Other vendors land in Phase 2 — see roadmap.
- 🇫🇷 The in-app UI labels are currently in French; full localisation is on
  the way.

## Contributing

PRs welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening one.

## Licence

[MIT](LICENSE) © 2026 Hugo Informatique.

LampControl bundles [Sparkle](https://sparkle-project.org/), distributed under
the MIT licence.
