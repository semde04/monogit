# LostFound

Projet universitaire « Advanced Mobile Development » : API Express/TypeScript, application Flutter et portail d’administration web hébergé sur Firebase Hosting.

## Structure

- `api/` — API REST sous `/api/v1` (Express 5, TypeScript, Mongoose, JWT).
- `app/` — application Flutter (BLoC, Clean Architecture) et build web du portail admin.
- `docs/` — maquettes et livrables.
- `.github/workflows/ci.yml` — typecheck/tests API, format/analyze/tests Flutter, build web et déploiement hosting.

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
| GET | `/admin/overview` | 👑 | Statistiques et listes paginées |
| PATCH | `/admin/items/:itemId/moderation` | 👑 | Retrait/rétablissement d’une annonce |

Pagination : `?page=1&limit=20` sur toutes les listes ; `page` ≥ 1, `limit` entre 1 et 50. Les réponses de liste contiennent `{ "data": [...], "meta": { "page", "limit", "total", "totalPages" } }`. Les erreurs suivent `{ "error": "CODE", "message": "...", "details": ... }` (422 pour une validation échouée).

Exemples de requêtes : `api/requests.http`.

## Comptes

Créer un compte normal via `/auth/register`. Pour un compte administrateur, définir `ADMIN_NAME`, `ADMIN_EMAIL` et `ADMIN_PASSWORD` dans `.env` puis lancer :

```sh
cd api
npm run create-admin
```

Le mot de passe est haché en Argon2id. Aucun compte ni secret de production n’est versionné.

## Limites connues

- Les photos sont stockées en base en base64 (limite 800 000 caractères) ; aucun stockage objet n’est configuré.
- Les notifications push nécessitent les identifiants Firebase fournis localement (`google-services.json` et `firebase_options.dart`, déjà présents dans le dépôt pour le projet de démonstration).
- Le refresh token est révoqué en cas de réutilisation : toutes les sessions du même utilisateur sont alors invalidées.
