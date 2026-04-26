# LampControl

> Une app macOS native dans la barre de menu pour piloter vos ampoules
> connectées. Légère, en verre liquide, et sécurisée par le Keychain.
>
> 🇬🇧 [Read this README in English](README.md)

[![Dernière release](https://img.shields.io/github/v/release/huggooo26/LampControl?label=release)](https://github.com/huggooo26/LampControl/releases/latest)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)](https://www.apple.com/macos/)
[![Licence MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

LampControl vit dans votre barre de menu macOS. Un clic sur l'icône ampoule
suffit pour allumer vos lampes, changer la luminosité, choisir une couleur ou
appliquer une scène à un groupe — sans interrompre ce que vous êtes en train
de faire.

La Phase 1 supporte **Tuya / Smart Life**. Le support multi-fournisseurs
(Philips Hue, LIFX, Yeelight, Govee) arrive en Phase 2.

---

## Fonctionnalités

- 🪶 **App barre de menu légère** — pas d'icône Dock, pas d'Electron, ~5 Mo.
- 💡 **Allumer, varier, recolorer** n'importe quelle lampe Tuya compatible.
- 🎨 **Scènes groupées** — sélectionnez plusieurs lampes RGB et appliquez une
  même couleur.
- 🔁 **Synchro automatique** toutes les 60 secondes, en silence.
- 🔐 **Access Secret stocké dans le Keychain** — aucun secret en clair.
- 🚀 **Auto-update via Sparkle** — un push sur `main`, les utilisateurs sont
  notifiés au prochain lancement.
- 🆓 Open source, licence MIT.

## Installation

### Option A — Télécharger le DMG

1. Récupérez le dernier DMG sur la
   [page Releases](https://github.com/huggooo26/LampControl/releases/latest).
2. Ouvrez `LampControl.dmg` et glissez `LampControl.app` dans `/Applications`.
3. **Au premier lancement — contourner Gatekeeper** (l'app est signée en
   ad-hoc tant qu'on n'a pas d'Apple Developer ID ; voir
   [limites connues](#limites-connues)). Sur macOS 14+ le simple clic droit
   → Ouvrir ne suffit plus :
   1. Double-cliquez sur `LampControl.app` une première fois. macOS affiche
      *« Apple n'a pas pu confirmer que LampControl ne contenait pas… »*.
      Cliquez sur **Terminé** — **pas** *Placer dans la corbeille*.
   2. Ouvrez **Réglages Système → Confidentialité et sécurité**.
   3. Descendez tout en bas, dans la section **Sécurité**. Vous verrez :
      *« LampControl a été bloquée pour protéger votre Mac. »* avec un
      bouton **Ouvrir quand même**.
   4. Cliquez sur **Ouvrir quand même** et authentifiez-vous (Touch ID
      ou mot de passe).
   5. Un nouveau dialog apparaît avec un bouton **Ouvrir** — cliquez
      dessus. L'app se lance et macOS retient votre choix.
4. L'icône ampoule apparaît dans votre barre de menu. Les mises à jour
   livrées via Sparkle ne re-déclenchent pas ce dialog — seul le tout
   premier lancement le fait.

### Option B — Compiler depuis les sources

```bash
git clone https://github.com/huggooo26/LampControl.git
cd LampControl
./scripts/build_app.sh
open dist/LampControl.app
```

Nécessite macOS 13+, les outils ligne de commande Xcode 15.4+, et Swift 5.9+.

## Démarrage rapide

1. Cliquez sur l'ampoule dans votre barre de menu.
2. Ouvrez l'onglet **Réglages**.
3. Collez vos identifiants Tuya (voir le
   [guide pas-à-pas](docs/CONFIGURATION.fr.md) — environ 5 minutes).
4. Cliquez sur **Enregistrer**. Vos lampes apparaissent dans l'onglet
   **Lampes**.

## Récupérer vos identifiants Tuya

LampControl parle directement à l'API Tuya Cloud. Il vous faut :

| Champ | Où le trouver |
| --- | --- |
| Access ID | Tuya IoT Platform → Cloud → Project → Authorization Key → *Access ID* |
| Access Secret | Même écran → *Access Secret* |
| Région | Choisissez la région la plus proche de vos lampes (Europe, US, Chine…) |
| UID | Tuya IoT Platform → Cloud → Project → *Linked Devices* → *Link Tuya App Account* → copiez l'UID |

Le tutoriel complet avec captures d'écran se trouve dans
[docs/CONFIGURATION.fr.md](docs/CONFIGURATION.fr.md) (français) et
[docs/CONFIGURATION.md](docs/CONFIGURATION.md) (anglais).

## Mises à jour automatiques

LampControl utilise [Sparkle](https://sparkle-project.org/) pour les mises à
jour intégrées.

- Ouvrez **Réglages → Mises à jour** pour vérifier manuellement ou activer
  les vérifications/installations automatiques.
- Les mises à jour sont signées avec une clé EdDSA ; seules les releases
  signées par les mainteneurs s'installeront.
- Clic droit sur l'icône barre de menu pour accéder à **Check for Updates…**
  sans ouvrir le popover.

## Premium

La préparation de l'offre Premium et de l'activation Lemon Squeezy est
documentée dans [docs/PREMIUM.fr.md](docs/PREMIUM.fr.md).

## Roadmap

- **Phase 1 (actuelle)** : support Tuya, auto-update, doc bilingue, release
  publique.
- **Phase 2** : abstraction multi-fournisseurs + Philips Hue, LIFX, Yeelight,
  Govee.
- **Phase 3** : modèle freemium — gratuit (ON/OFF, 2 lampes), licence à vie à
  10 € pour débloquer couleur, luminosité, multi-fournisseurs et lampes
  illimitées.
- **Phase 4** : notarisation Apple, installation automatique au lancement,
  onboarding guidé.

## Limites connues

- 🔓 **Signature ad-hoc uniquement.** Tant qu'aucun Apple Developer ID payant
  n'est en place, Gatekeeper affiche un avertissement au premier lancement.
  Clic droit → *Ouvrir* une fois, macOS retient votre choix.
- 🌍 **Tuya uniquement pour l'instant.** Les autres fournisseurs arrivent en
  Phase 2 — voir la roadmap.
- 🇫🇷 Les libellés in-app sont actuellement en français ; la localisation
  complète est en route.

## Contribuer

Les PR sont les bienvenues. Merci de lire [CONTRIBUTING.md](CONTRIBUTING.md)
avant d'en ouvrir une.

## Licence

[MIT](LICENSE) © 2026 Hugo Informatique.

LampControl embarque [Sparkle](https://sparkle-project.org/), distribué sous
licence MIT.
