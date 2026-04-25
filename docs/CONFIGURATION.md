# Configuration guide — Tuya / Smart Life

> 🇫🇷 [Lire ce guide en français](CONFIGURATION.fr.md)

LampControl needs four pieces of information to talk to the Tuya Cloud:

1. An **Access ID**
2. An **Access Secret**
3. The **region** of your account (Europe, US West, US East, China, India, …)
4. The **UID** of the Tuya / Smart Life account that owns your lamps

This guide walks you through getting all four. It takes about five minutes
the first time, and you only need to do it once.

> Tuya occasionally renames sections of their portal. If a label below has
> changed, look for the closest equivalent — the underlying flow is stable.

---

## 1. Pair your lamps in the mobile app

Before LampControl can talk to your lamps, they have to be paired with the
Tuya ecosystem.

- Install **Smart Life** ([iOS](https://apps.apple.com/app/smart-life-smart-living/id1115101477) /
  [Android](https://play.google.com/store/apps/details?id=com.tuya.smartlife))
  or any Tuya-powered app shipped with your lamp.
- Create an account using your **email** (not phone number — it makes the
  cloud linking easier later).
- Pair your lamps following the manufacturer instructions. Confirm you can
  toggle them from the mobile app.

Make a note of:

- The email/phone you used.
- The **country** you selected at sign-up. This is your **region**.

---

## 2. Create a Tuya IoT Cloud project

1. Go to <https://iot.tuya.com/> and **sign in** (or create an account).
2. In the left sidebar, choose **Cloud → Development**.
3. Click **Create Cloud Project**.
4. Fill in:
   - **Project name:** anything (e.g. `LampControl`).
   - **Industry:** *Smart Home*.
   - **Development Method:** *Custom Development* (or *Smart Home* if Custom
     isn't available).
   - **Data Center:** the one matching your account region:
     - Europe → *Central Europe Data Center*
     - US West → *Western America Data Center*
     - US East → *Eastern America Data Center*
     - China → *China Data Center*
     - India → *India Data Center*
5. Click **Create**.

Tuya prompts you to pick API products. Make sure these are checked:

- **IoT Core**
- **Authorization** (sometimes named *Authorization Token Management*)
- **Smart Home Devices Management**
- **Smart Home Family Management**
- **Smart Home Scene Linkage** (optional, for future scene support)

Click **Authorize**.

---

## 3. Grab your Access ID and Access Secret

1. In your project, open the **Overview** tab.
2. Under **Authorization Key**, copy:
   - **Access ID / Client ID** → this is your **Access ID**.
   - **Access Secret / Client Secret** → this is your **Access Secret**.

> Treat the Access Secret like a password. LampControl stores it in the macOS
> Keychain, never in plain text.

---

## 4. Link your Smart Life account

This step gives the cloud project access to the lamps you paired with the
mobile app.

1. Open the **Devices** tab of your project.
2. Click **Link Tuya App Account → Add App Account**.
3. Open Smart Life on your phone → **Me** tab → tap the QR scanner icon
   (top-right) → scan the QR code displayed on the Tuya IoT website.
4. Confirm in the app.

The page now lists your linked account, including its **UID**. Copy it.

---

## 5. Pick the matching endpoint

LampControl auto-fills the endpoint when you choose a region in
**Réglages**. The mapping is:

| Region | Endpoint |
| --- | --- |
| Europe | `https://openapi.tuyaeu.com` |
| US West | `https://openapi.tuyaus.com` |
| US East | `https://openapi-ueaz.tuyaus.com` |
| China | `https://openapi.tuyacn.com` |
| India | `https://openapi.tuyain.com` |

If your data centre isn't listed, choose **Custom** and paste the URL
provided by Tuya in your project's **Overview** tab.

---

## 6. Enter everything in LampControl

1. Click the lightbulb in your menu bar.
2. Open **Réglages**.
3. Paste:
   - Access ID
   - Access Secret
   - Region (LampControl auto-fills the endpoint)
   - UID
4. Click **Enregistrer**.

The popover switches to the **Lampes** tab and starts syncing. Within a few
seconds you should see your lamps appear with a power toggle and — for
RGB-capable models — a brightness slider and colour picker.

---

## Troubleshooting

### `Identifiants Tuya incomplets`

One of the four fields is empty. Re-open Réglages and check that:

- Access ID and Access Secret are not swapped.
- The endpoint matches the data centre you picked when creating the project.
- The UID has no leading/trailing whitespace.

### `sign invalid` / HTTP 1004

Almost always means your **system clock is out of sync** (Tuya signatures
include a timestamp). Open **System Settings → General → Date & Time**, make
sure *Set time and date automatically* is on.

### `permission deny` / HTTP 1106

The cloud project doesn't have permission to talk to your lamps. Re-open
your project on the Tuya IoT website, go to **Service API → Authorize** and
ensure all the products listed in step 2 are enabled.

### Lamps appear but won't toggle / change colour

Open the lamp in the Smart Life app and confirm it responds there. If yes,
note the lamp model and open an
[issue](https://github.com/huggooo26/LampControl/issues) — some firmwares
expose unusual capability codes that we may not yet handle.

### Token expired errors

LampControl handles token refresh automatically. If you see persistent
expiry errors, click **Enregistrer** again to force-refresh the cached
client.

### `device offline`

The lamp is offline on Tuya's side. Power-cycle the lamp and wait a minute.
LampControl mirrors the cloud's view; we can't reach a lamp the cloud can't
reach.

---

## FAQ

**Does LampControl work without internet?**

Not in Phase 1 — Tuya is a cloud-only API. Phase 2 will add Hue and
Yeelight, both of which work over the local LAN.

**Where is my Access Secret stored?**

In the macOS Keychain under the service `LampControl.Tuya`, account
`tuya-access-secret`. Other settings live in
`~/Library/Application Support/LampControl/settings.json` in plain JSON.

**Can I use multiple Tuya accounts?**

Not yet — Phase 2's vendor abstraction will support multiple accounts and
multiple vendors side by side.

**Will LampControl support Bluetooth-only lamps?**

Only lamps that show up in the Tuya Cloud API are reachable. Bluetooth-only
lamps that never sync to the cloud are out of scope.

**Where do I report a bug?**

[GitHub Issues](https://github.com/huggooo26/LampControl/issues) — please
include macOS version, LampControl version, and the lamp model.
