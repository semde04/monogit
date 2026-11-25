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
flutter run
```

L’émulateur Android utilise par défaut `http://10.0.2.2:5000/api/v1`. Le navigateur utilise `http://localhost:5000/api/v1`.

Pour une autre adresse (téléphone physique ou API déployée) :

```sh
flutter run --dart-define=API_BASE_URL=https://votre-api.example.com/api/v1
```

Sur un téléphone physique, l’API locale doit écouter sur une interface joignable depuis le réseau du téléphone ; `127.0.0.1` ne l’est pas.

## Fonctions disponibles

- Inscription, connexion, profil, déconnexion et renouvellement automatique des jetons avec stockage sécurisé.
- Liste, recherche temporisée, filtres, détail, publication et clôture optimiste des annonces.
- Réclamations, acceptation/refus et conversations privées liées à une réclamation.
- Cache local des annonces, actualisation et états de chargement, vide et erreur.

## Contrats API actuellement absents

L’API actuelle ne propose pas de stockage/envoi de photos ni de route de modération. L’app ne peut donc pas enregistrer d’images ni modérer des annonces tant que ces contrats ne sont pas ajoutés côté serveur. Le rôle actuellement renvoyé par l’API est `user` ou `admin`.
