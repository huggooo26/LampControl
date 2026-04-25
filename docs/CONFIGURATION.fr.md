# Guide de configuration — Tuya / Smart Life

> 🇬🇧 [Read this guide in English](CONFIGURATION.md)

LampControl a besoin de quatre informations pour communiquer avec le cloud
Tuya :

1. Un **Access ID**
2. Un **Access Secret**
3. La **région** de votre compte (Europe, US West, US East, Chine, Inde, …)
4. L'**UID** du compte Tuya / Smart Life qui possède vos lampes

Ce guide vous explique comment obtenir les quatre. Comptez environ cinq
minutes la première fois — c'est à faire une seule fois.

> Tuya renomme parfois certaines sections de son portail. Si un libellé a
> changé, cherchez l'équivalent le plus proche — la procédure de fond est
> stable.

---

## 1. Appairer vos lampes dans l'application mobile

Avant que LampControl puisse parler à vos lampes, elles doivent être
appairées dans l'écosystème Tuya.

- Installez **Smart Life** ([iOS](https://apps.apple.com/app/smart-life-smart-living/id1115101477) /
  [Android](https://play.google.com/store/apps/details?id=com.tuya.smartlife))
  ou n'importe quelle app Tuya livrée avec vos lampes.
- Créez un compte avec une **adresse email** (pas un numéro de téléphone —
  ça rend le lien cloud plus simple plus tard).
- Appairez vos lampes en suivant les instructions du fabricant. Confirmez
  qu'elles répondent depuis l'app mobile.

Notez :

- L'email/téléphone utilisé.
- Le **pays** choisi à l'inscription. C'est votre **région**.

---

## 2. Créer un projet Tuya IoT Cloud

1. Allez sur <https://iot.tuya.com/> et **connectez-vous** (ou créez un
   compte).
2. Dans la barre latérale gauche, choisissez **Cloud → Development**.
3. Cliquez sur **Create Cloud Project**.
4. Remplissez :
   - **Project name** : ce que vous voulez (ex. `LampControl`).
   - **Industry** : *Smart Home*.
   - **Development Method** : *Custom Development* (ou *Smart Home* si
     Custom n'est pas dispo).
   - **Data Center** : celui qui correspond à votre région :
     - Europe → *Central Europe Data Center*
     - US West → *Western America Data Center*
     - US East → *Eastern America Data Center*
     - Chine → *China Data Center*
     - Inde → *India Data Center*
5. Cliquez sur **Create**.

Tuya vous demande quels produits API activer. Vérifiez que ceux-ci sont
cochés :

- **IoT Core**
- **Authorization** (parfois nommé *Authorization Token Management*)
- **Smart Home Devices Management**
- **Smart Home Family Management**
- **Smart Home Scene Linkage** (optionnel, pour le support futur des scènes)

Cliquez sur **Authorize**.

---

## 3. Récupérer Access ID et Access Secret

1. Dans votre projet, ouvrez l'onglet **Overview**.
2. Sous **Authorization Key**, copiez :
   - **Access ID / Client ID** → c'est votre **Access ID**.
   - **Access Secret / Client Secret** → c'est votre **Access Secret**.

> Traitez l'Access Secret comme un mot de passe. LampControl le stocke dans
> le Keychain macOS, jamais en clair.

---

## 4. Lier votre compte Smart Life

Cette étape donne au projet cloud accès aux lampes que vous avez appairées
dans l'app mobile.

1. Ouvrez l'onglet **Devices** de votre projet.
2. Cliquez sur **Link Tuya App Account → Add App Account**.
3. Ouvrez Smart Life sur votre téléphone → onglet **Me** (Moi) → touchez
   l'icône de scan QR (en haut à droite) → scannez le QR code affiché sur le
   site Tuya IoT.
4. Confirmez dans l'app.

La page liste maintenant votre compte lié, avec son **UID**. Copiez-le.

---

## 5. Choisir le bon endpoint

LampControl remplit automatiquement le champ endpoint quand vous choisissez
une région dans **Réglages**. La correspondance :

| Région | Endpoint |
| --- | --- |
| Europe | `https://openapi.tuyaeu.com` |
| US West | `https://openapi.tuyaus.com` |
| US East | `https://openapi-ueaz.tuyaus.com` |
| Chine | `https://openapi.tuyacn.com` |
| Inde | `https://openapi.tuyain.com` |

Si votre data center n'est pas dans la liste, choisissez **Custom** et
collez l'URL fournie par Tuya dans l'onglet **Overview** de votre projet.

---

## 6. Saisir tout ça dans LampControl

1. Cliquez sur l'ampoule dans la barre de menu.
2. Ouvrez **Réglages**.
3. Collez :
   - Access ID
   - Access Secret
   - Région (LampControl remplit l'endpoint)
   - UID
4. Cliquez sur **Enregistrer**.

Le popover bascule sur l'onglet **Lampes** et lance la synchro. En quelques
secondes vos lampes apparaissent avec un toggle d'allumage — et pour les
modèles RGB, un slider de luminosité et un sélecteur de couleur.

---

## Dépannage

### `Identifiants Tuya incomplets`

Un des quatre champs est vide. Rouvrez Réglages et vérifiez que :

- Access ID et Access Secret ne sont pas inversés.
- L'endpoint correspond au data center choisi à la création du projet.
- L'UID n'a pas d'espace en début ou en fin.

### `sign invalid` / HTTP 1004

Quasi systématiquement signe que votre **horloge système est désynchronisée**
(les signatures Tuya incluent un timestamp). Ouvrez **Réglages Système →
Général → Date et heure**, vérifiez que *Régler la date et l'heure
automatiquement* est activé.

### `permission deny` / HTTP 1106

Le projet cloud n'a pas la permission de parler à vos lampes. Rouvrez votre
projet sur le site Tuya IoT, allez dans **Service API → Authorize** et
vérifiez que tous les produits listés à l'étape 2 sont bien activés.

### Les lampes apparaissent mais ne répondent pas / ne changent pas de couleur

Ouvrez la lampe dans Smart Life et confirmez qu'elle répond. Si oui, notez
le modèle de la lampe et ouvrez une
[issue](https://github.com/huggooo26/LampControl/issues) — certains
firmwares exposent des codes de capacités inhabituels que nous ne gérons
peut-être pas encore.

### Erreurs `token expired`

LampControl gère le rafraîchissement de token automatiquement. Si l'erreur
persiste, cliquez à nouveau sur **Enregistrer** pour forcer un refresh du
client mis en cache.

### `device offline`

La lampe est hors-ligne côté Tuya. Coupez/rebranchez la lampe et patientez
une minute. LampControl reflète la vue du cloud ; on ne peut pas joindre une
lampe que le cloud ne joint pas.

---

## FAQ

**LampControl fonctionne-t-il sans internet ?**

Pas en Phase 1 — Tuya est une API cloud uniquement. La Phase 2 ajoutera Hue
et Yeelight, qui marchent en LAN local.

**Où est stocké mon Access Secret ?**

Dans le Keychain macOS sous le service `LampControl.Tuya`, compte
`tuya-access-secret`. Les autres réglages vivent dans
`~/Library/Application Support/LampControl/settings.json` en JSON brut.

**Puis-je utiliser plusieurs comptes Tuya ?**

Pas encore — l'abstraction multi-fournisseurs de la Phase 2 supportera
plusieurs comptes et plusieurs fournisseurs côte à côte.

**LampControl supportera-t-il les lampes Bluetooth uniquement ?**

Seules les lampes visibles dans l'API Tuya Cloud sont accessibles. Les
lampes Bluetooth qui ne se synchronisent jamais avec le cloud sont hors
périmètre.

**Où signaler un bug ?**

[GitHub Issues](https://github.com/huggooo26/LampControl/issues) — merci
d'indiquer la version macOS, la version LampControl, et le modèle de la
lampe.
