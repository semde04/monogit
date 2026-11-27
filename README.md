# LostFound

Projet universitaire « Advanced Mobile Development » : API Express/TypeScript, application Flutter et portail d’administration web hébergé sur Firebase Hosting.

## Structure

- `api/` — API REST sous `/api/v1` (Express 5, TypeScript, Mongoose, JWT).
- `app/` — application Flutter (BLoC, Clean Architecture) et build web du portail admin.
- `docs/` — maquettes et livrables.
- `.github/workflows/ci.yml` — typecheck/tests API, format/analyze/tests Flutter, build web et déploiement hosting.

## Architecture applicative

- `app/lib/core/` — configuration `API_BASE_URL`, client Dio, intercepteur de refresh, stockage de tokens, router GoRouter et notifications push.
- `app/lib/features/` — structure feature-first : `domain` (entities, repositories, usecases), `data` (models, datasources, repositories) et `presentation` (BLoC, pages).
- Les écrans principaux sont `discover`, `items/:id`, `items/new`, `claims`, `chat/:claimId`, `profile` et `admin`.
- Le portail web réutilise les mêmes couches domaine/données/présentation que l’application mobile, avec un build Flutter dédié.

## Qualité

- API : `npm run typecheck` puis `npm test` dans `api/` — 21 tests d’intégration avec MongoDB de test.
- Flutter : `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, `flutter test` dans `app/` — 30 tests.
- Dernier run CI vert sur `main` : `46067765719` (API, Flutter, build web et déploiement Firebase Hosting).
- Aucun secret de production n’est versionné : `API_BASE_URL` et `FIREBASE_SERVICE_ACCOUNT` sont fournis par GitHub Actions.

## Démarrage

API :

```sh
cd api
cp .env.example .env      # renseigner les secrets localement
npm install
npm run typecheck
npm test                  # utilise .env.test.example et MongoDB local
npm run dev
```

Flutter (émulateur Android) :

```sh
cd app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000/api/v1
```

Portail web (production) :

```sh
cd app
flutter build web --release --dart-define=API_BASE_URL=https://votre-api.example.com/api/v1
```

`API_BASE_URL` est obligatoire : aucun fallback n’est codé dans l’application. En dehors du mode debug, seule une URL HTTPS est acceptée. Les secrets et les valeurs de production ne sont pas versionnés ; en CI ils sont fournis par `API_BASE_URL` et `FIREBASE_SERVICE_ACCOUNT`.

## Endpoints

Base : `/api/v1`. `🔒` = access token Bearer requis, `👑` = rôle `admin` requis.

| Méthode | Chemin | Accès | Description |
| --- | --- | --- | --- |
| GET | `/health` | public | État de l’API |
| POST | `/auth/register` | public | Inscription (name, email, matricule, password) |
| POST | `/auth/login` | public | Connexion, access + refresh tokens |
| POST | `/auth/refresh` | public | Rotation du refresh token (réutilisation = révocation) |
| POST | `/auth/logout` | public | Révocation du refresh token |
| GET | `/auth/me` | 🔒 | Profil courant |
| PUT | `/auth/device-installation` | 🔒 | Enregistrement du device pour les notifications |
| DELETE | `/auth/device-installation` | 🔒 | Retrait du device |
| GET | `/items` | public | Liste paginée, filtres `search`, `category`, `type` |
| GET | `/items/:id` | public | Détail (sans question de preuve ni motifs de modération) |
| POST | `/items` | 🔒 | Publication (photo base64 facultative) |
| PATCH | `/items/:id` | 🔒 | Modification par le propriétaire |
| PATCH | `/items/:id/close` | 🔒 | Clôture par le propriétaire |
| DELETE | `/items/:id` | 🔒 | Suppression par le propriétaire |
| GET | `/claims` | 🔒 | Réclamations paginées de l’utilisateur |
| POST | `/claims` | 🔒 | Réclamer un objet avec réponse à la preuve |
| PATCH | `/claims/:claimId/status` | 🔒 | Accepter/refuser (propriétaire ou demandeur selon le statut) |
| POST | `/claims/:claimId/confirm-return` | 🔒 | Confirmation de restitution par les deux parties |
| GET | `/messages/claims/:claimId` | 🔒 | Historique paginé d’une conversation |
| POST | `/messages` | 🔒 | Envoyer un message dans une réclamation |
| GET | `/admin/overview` | 👑 | Statistiques (dont comptes/actions du jour) et listes paginées |
| GET | `/admin/activity` | 👑 | Journal paginé des activités (`?type=auth.register`...) |
| PATCH | `/admin/items/:itemId/moderation` | 👑 | Retrait/rétablissement d’une annonce |
| GET | `/admin/items` | 👑 | Toutes les publications, filtres `search`, `type`, `isClosed`, `isRemoved`, `isReturned` |
| PATCH | `/admin/users/:userId/suspension` | 👑 | Suspension réversible d’un compte (`isSuspended`, motif obligatoire pour suspendre) |

Un compte suspendu peut encore appeler `/auth/me` et `/auth/refresh`, mais les routes métier répondent `403 ACCOUNT_SUSPENDED`. La self-suspension et la suspension d’un compte admin sont refusées.

Pagination : `?page=1&limit=20` sur toutes les listes ; `page` ≥ 1, `limit` entre 1 et 50. Les réponses de liste contiennent `{ "data": [...], "meta": { "page", "limit", "total", "totalPages" } }`. Les erreurs suivent `{ "error": "CODE", "message": "...", "details": ... }` (422 pour une validation échouée).

Exemples de requêtes : `api/requests.http`.

## Comptes

Créer un compte normal via `/auth/register`. Pour un compte administrateur, définir `ADMIN_NAME`, `ADMIN_EMAIL` et `ADMIN_PASSWORD` dans `.env` puis lancer :

```sh
cd api
npm run create-admin
```

Le mot de passe est haché en Argon2id. Aucun compte ni secret de production n’est versionné.

## Équipe et rôles

- Nitiema Eddy Martial — App lead : architecture Flutter, navigation, BLoC et portail admin.
- Zongo Juste Landry — API lead : modèles, endpoints, JWT et autorisations.
- Semde Aicha — Product / UX lead : parcours, wireframes, captures et design document.
- Kagambega Geraldine — Quality lead : CI, tests, lints et builds de release.
- Ouedraogo Corneille — Team lead : planification, intégration finale et documentation.

Les PR principales de chaque membre sont liées dans `docs/report.pdf`, section 8.

## Liens de déploiement

- API : `https://lostfound-api-4kaz.onrender.com/api/v1`
- Portail admin : `https://lostfound-admin-74fa4.web.app`
- Dépôt : `https://github.com/semde04/monogit`
- Release `v1.0.0` et APK : `[à compléter avant soutenance]`
- Vidéo de démo (≤ 3 min) : `[à compléter avant soutenance]`
- Issue board : `[à compléter avant soutenance]`

## Comptes de test par rôle

- Étudiant : `[email] / [mot de passe]` — rôle `user`, sans annonce.
- Propriétaire : `[email] / [mot de passe]` — rôle `user`, avec au moins une annonce.
- Administrateur : `[email] / [mot de passe]` — rôle `admin`.

Ces identifiants doivent être renseignés avant la soutenance ; aucun secret de production n’est versionné.

## Limites connues

- Les photos sont stockées en base en base64 (limite 800 000 caractères) ; aucun stockage objet n’est configuré.
- Les notifications push nécessitent les identifiants Firebase fournis localement (`google-services.json` et `firebase_options.dart`, déjà présents dans le dépôt pour le projet de démonstration).
- Le refresh token est révoqué en cas de réutilisation : toutes les sessions du même utilisateur sont alors invalidées.
