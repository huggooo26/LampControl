# Premium et licences

LampControl utilise Lemon Squeezy pour l'activation des licences Premium.
L'application appelle uniquement l'API publique de licences depuis le Mac du
client. Aucun secret API Lemon Squeezy ne doit être ajouté dans l'app.

## Pourquoi Lemon Squeezy

- gestion native des clés de licence ;
- activation par machine avec `instance_id` ;
- validation et désactivation d'une licence ;
- checkout hébergé, donc pas de paiement à gérer dans LampControl.

## Configuration Lemon Squeezy

1. Crée un produit LampControl dans Lemon Squeezy.
2. Active les License Keys sur le produit ou la variante Premium.
3. Définis une limite d'activation par licence, par exemple `1` ou `3`.
4. Copie l'URL du checkout public de la variante Premium.
5. Note les IDs Lemon Squeezy :
   - `store_id`
   - `product_id`
   - `variant_id`

## Configuration dans l'app

Renseigne ces clés dans `Info.plist` avant de publier la version commerciale :

```xml
<key>LCLicenseCheckoutURL</key>
<string>https://lampcontrol.lemonsqueezy.com/checkout/buy/12d32ac2-9a5a-4120-a95e-36a10afb51d9</string>
<key>LCLicenseExpectedStoreID</key>
<integer>356642</integer>
<key>LCLicenseExpectedProductID</key>
<integer>1005308</integer>
<key>LCLicenseExpectedVariantID</key>
<integer>1577348</integer>
```

Ces IDs verrouillent l'activation sur le produit LampControl Premium.

## Parcours utilisateur

1. L'utilisateur achète Premium via Lemon Squeezy.
2. Il colle sa clé de licence dans `Réglages > Premium`.
3. Il peut renseigner son email d'achat pour renforcer la vérification.
4. LampControl active la licence et stocke localement :
   - la clé ;
   - l'`instance_id` ;
   - le nom du Mac ;
   - l'email client renvoyé par Lemon Squeezy.

## À faire avant commercialisation

- Décider si l'Early Access doit rester actif ou si l'état par défaut devient
  `Gratuit`.
- Tester une vraie clé avec activation, validation, relance de l'app, puis
  désactivation.
