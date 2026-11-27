# LostFound — application Flutter

Application mobile LostFound construite avec Flutter, BLoC et Clean Architecture. Les accès aux données passent par l’API Express sous `/api/v1`.

## Prérequis

- Flutter et Dart (voir `environment` dans `pubspec.yaml`).
- L’API démarrée sur le port 5000 et MongoDB connecté.

## Lancer sur Android

Depuis la racine du dépôt :

```sh
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1
```

`API_BASE_URL` est obligatoire : l’application échoue au démarrage si elle est absente. Les fichiers `dart_defines/dev.json` et `dart_defines/dev_web.json` contiennent les valeurs locales de développement.

```sh
flutter run --dart-define-from-file=dart_defines/dev.json
```

Sur un téléphone physique, l’API locale doit écouter sur une interface joignable depuis le réseau du téléphone ; `127.0.0.1` ne l’est pas. En release, seule une URL HTTPS est acceptée.

## Portail administrateur (web)

Le build web est déployé sur Firebase Hosting (`lostfound-admin-74fa4`). La CI fournit l’URL de production via le secret `API_BASE_URL` ; aucun secret n’est codé dans le dépôt.

```sh
flutter build web --release --dart-define=API_BASE_URL=https://votre-api.example.com/api/v1
```

## Fonctions disponibles

- Inscription, connexion, profil, déconnexion et renouvellement automatique des jetons avec stockage sécurisé et refresh concurrent sûr.
- Liste, recherche temporisée, filtres, détail, publication et clôture optimiste des annonces, avec cache local et états de chargement/vide/erreur.
- Réclamations, acceptation/refus, confirmation de restitution et conversations privées liées à une réclamation.
- Modération des annonces (rôle `admin`) : retrait/rétablissement avec motif.
- Supervision (rôle `admin`) : comptes créés, dates d’inscription, compteurs du jour et journal d’activité filtrable/paginé (`/admin/activity`).
- Photos enregistrées en base64 via l’API (limite serveur : 800 000 caractères).
- Notifications push Firebase : enregistrement de l’installation auprès de l’API.

## Qualité

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Les tests unitaires des BLoC utilisent `bloc_test` et des repositories factices dans `test/fakes/`. La CI exécute ces commandes à chaque pull request.

Le contrat complet de l’API est documenté dans le `README.md` racine et dans `api/requests.http`.
