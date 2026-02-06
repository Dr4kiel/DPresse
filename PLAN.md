# DPresse - Plan de portage Flutter

## Contexte
Portage de l'application [Gazette](https://github.com/ebanDev/Gazette) (Nuxt 3/Vue) vers Flutter.
Gazette est un client mobile pour Europresse permettant de lire des journaux via un abonnement institutionnel.

## Choix techniques validés
- **Flutter** (installation via `brew install flutter`)
- **Android uniquement** pour commencer
- **Riverpod** pour le state management
- **WebView intégrée** pour l'authentification BNF (capture de cookies)
- **Pas de backend** : l'app parle directement à Europresse via les cookies capturés

---

## Architecture Gazette (référence)

### Écosystème original (3 repos séparés)
1. **ent-cookies** : authentification ENT (Toutatice, ScPoBx) → obtient cookies Europresse
2. **europresse-lib** : scraping HTML d'Europresse (recherche, articles, sources)
3. **europresse-api** : serveur Deno/Oak qui expose ent-cookies + europresse-lib en REST
4. **Gazette** : frontend Nuxt 3 qui consomme l'API

### Flux d'authentification original
Le client envoie username/password au backend → le backend fait une chaîne SAML complexe via l'ENT → obtient des cookies Europresse → les sérialise en JSON → les renvoie au client → le client les renvoie à chaque requête.

### Pour DPresse (BNF)
On utilise une **WebView** pour que l'utilisateur se connecte sur le portail BNF → la WebView navigue jusqu'à Europresse → on **capture les cookies** directement depuis la WebView → on les utilise pour les requêtes HTTP natives.

URL de départ BNF : `https://bnf.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=BNF_1`

---

## Endpoints Europresse (scraping HTML)

Tous les chemins sont relatifs au domaine Europresse (ex: `nouveau.europresse.com`).

### Recherche
1. **GET** `/Search/Reading` → récupérer le `__RequestVerificationToken` (CSRF)
2. **POST** `/Search/AdvancedMobile` avec body URL-encoded :
   ```
   Keywords={fullTextQuery}
   CriteriaKeys[0].Operator=&
   CriteriaKeys[0].Key=TIT_HEAD
   CriteriaKeys[0].Text={titleQuery}
   CriteriaKeys[1].Operator=&
   CriteriaKeys[1].Key=LEAD
   CriteriaKeys[1].Text=
   CriteriaKeys[2].Operator=&
   CriteriaKeys[2].Key=AUT_BY
   CriteriaKeys[2].Text=
   DateFilter.DateRange={3|4|7|9}
   DateFilter.DateStart={YYYY-MM-DD}
   DateFilter.DateStop={YYYY-MM-DD}
   SourcesForm={1|2}
   __RequestVerificationToken={token}
   ```
   - DateRange: 3=semaine, 4=mois, 7=année, 9=tout
3. **GET** `/Search/GetPage?pageNo={n}&docPerPage=50` → résultats paginés (HTML)
   - Sélecteurs CSS : `.docListItem`, `.docList-links` (titre), `.source-name`, `.details` (date avant "•"), `.kwicResult.clearfix` (description), `input#doc-name` value (id)

### Article
- **GET** `/Document/ViewMobile?docKey={id}&fromBasket=false&viewEvent=1&invoiceCode=`
  - Extraire `.docOcurrContainer` innerHTML
  - Titre dans `.titreArticleVisu`
  - Supprimer les balises `<mark>` (highlight de recherche)

### Sources
- **GET** `/Criteria/SourcesFilterMobile?term={query}`
  - Parser les `div` avec `.plainTxt` et `input[criteriaId]`
  - Reformater les titres ("Monde, Le" → "Le Monde")

---

## Structure du projet Flutter

```
dpresse/
├── android/
├── lib/
│   ├── main.dart
│   ├── app.dart                          # MaterialApp + routeur
│   ├── core/
│   │   ├── constants.dart                # URLs, durées, clés
│   │   ├── theme.dart                    # Thème Material 3
│   │   └── router.dart                   # GoRouter config
│   ├── models/
│   │   ├── article.dart                  # id, title, source, date, description, html
│   │   ├── search_result.dart            # id, title, source, date, description
│   │   ├── feed.dart                     # id, name, url, enabled
│   │   ├── feed_item.dart                # title, link, description, source, pubDate
│   │   └── source_filter.dart            # title, id (criteriaId)
│   ├── services/
│   │   ├── auth_service.dart             # WebView cookie capture + validation
│   │   ├── europresse_service.dart       # Recherche, article, sources (scraping)
│   │   ├── http_client.dart              # Dio/http avec injection de cookies
│   │   ├── rss_service.dart              # Parser RSS (package xml ou webfeed)
│   │   └── html_parser.dart              # Parsing HTML (package html)
│   ├── providers/
│   │   ├── auth_provider.dart            # État auth (cookies, domain, isLoggedIn)
│   │   ├── search_provider.dart          # Query, résultats, filtres, loading
│   │   ├── article_provider.dart         # Article courant, loading
│   │   ├── bookmarks_provider.dart       # Liste bookmarks (persisté)
│   │   ├── feeds_provider.dart           # Liste feeds RSS (persisté)
│   │   └── settings_provider.dart        # Préférences (persisté)
│   ├── screens/
│   │   ├── login_screen.dart             # WebView BNF login
│   │   ├── home_screen.dart              # Flux RSS + navigation
│   │   ├── search_screen.dart            # Recherche Europresse
│   │   ├── article_screen.dart           # Lecture article (HTML)
│   │   ├── bookmarks_screen.dart         # Articles sauvegardés
│   │   └── settings_screen.dart          # Paramètres + déconnexion
│   └── widgets/
│       ├── article_card.dart             # Carte résultat recherche / feed
│       ├── search_filters.dart           # Filtres (date, type recherche)
│       ├── feed_section.dart             # Section feed RSS sur home
│       ├── source_picker.dart            # Sélecteur de sources
│       └── bottom_nav.dart               # Barre de navigation
├── pubspec.yaml
└── analysis_options.yaml
```

---

## Packages Flutter nécessaires

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0

  # Navigation
  go_router: ^14.0.0

  # Réseau
  dio: ^5.4.0
  cookie_jar: ^4.0.0
  dio_cookie_manager: ^3.1.0

  # WebView (auth BNF)
  webview_flutter: ^4.7.0

  # Stockage local
  shared_preferences: ^2.2.0        # Pour persistance Riverpod
  flutter_secure_storage: ^9.0.0    # Pour cookies sensibles

  # Parsing
  html: ^0.15.4                     # Parser HTML (équivalent node-html-parser)
  xml: ^6.5.0                       # Parser RSS/XML
  # OU webfeed: ^0.9.0              # Parser RSS dédié

  # Rendu HTML article
  flutter_html: ^3.0.0              # Rendu HTML natif Flutter

  # UI
  google_fonts: ^6.1.0              # Inter + Source Serif 4
  shimmer: ^3.0.0                   # Skeleton loading

  # Utilitaires
  intl: ^0.19.0                     # Formatage dates
  string_similarity: ^2.0.0         # Équivalent js-levenshtein

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.0
  riverpod_lint: ^2.3.0
```

---

## Modèles de données

### Article
```dart
class Article {
  final String id;          // Clé document Europresse
  final String title;
  final String source;      // Nom du journal
  final String date;        // Date formatée
  final String description; // Extrait/chapô
  final String html;        // Contenu HTML complet
}
```

### SearchResult
```dart
class SearchResult {
  final String id;
  final String title;
  final String source;
  final String date;
  final String description;
}
```

### Feed
```dart
class Feed {
  final String id;
  final String name;
  final String url;
  final bool enabled;
}
```

---

## Flux d'authentification BNF (WebView)

1. Ouvrir WebView sur `https://bnf.idm.oclc.org/login?url=https://nouveau.europresse.com/access/ip/default.aspx?un=BNF_1`
2. L'utilisateur saisit ses identifiants BNF dans la WebView
3. Après authentification, la WebView est redirigée vers Europresse
4. Détecter quand l'URL contient `europresse.com` (via `NavigationDelegate`)
5. Extraire tous les cookies de la WebView via `WebViewCookieManager`
6. Extraire le domaine Europresse de l'URL finale
7. Stocker les cookies dans `flutter_secure_storage`
8. Fermer la WebView et naviguer vers l'écran principal

### Validation des cookies
- Stocker le timestamp de capture
- Revalider après 30 minutes (comme Gazette)
- Si expiré → rouvrir la WebView login

---

## Flux RSS (écran d'accueil)

### Feeds par défaut
| Source | URL RSS |
|---|---|
| Libération | `https://www.liberation.fr/arc/outboundfeeds/rss-all/collection/accueil-une/?outputType=xml` |
| Le Monde - International | `https://www.lemonde.fr/international/rss_full.xml` |
| Le Monde - France | `https://www.lemonde.fr/politique/rss_full.xml` |
| Le Monde - Économie | `https://www.lemonde.fr/economie/rss_full.xml` |
| Le Monde - Culture | `https://www.lemonde.fr/culture/rss_full.xml` |
| Le Monde - Sport | `https://www.lemonde.fr/sport/rss_full.xml` |
| Le Monde Diplomatique | `https://www.monde-diplomatique.fr/recents.xml` |
| Courrier International | `https://www.courrierinternational.com/feed/all/rss.xml` |

### Logique
1. Charger les feeds RSS activés
2. Afficher les 5 derniers articles de chaque feed
3. Au tap sur un article RSS → recherche par titre dans Europresse (searchIn=title, dateRange=lastWeek)
4. Trier les résultats par distance de Levenshtein (titre le plus proche en premier)
5. Ouvrir le premier résultat ou afficher la liste si ambiguïté

---

## Étapes d'implémentation

### Phase 1 : Setup
1. Installer Flutter via Homebrew : `brew install flutter`
2. Créer le projet : `flutter create --org com.dpresse --project-name dpresse .`
3. Configurer `pubspec.yaml` avec les dépendances
4. Configurer le thème Material 3 et les polices
5. Mettre en place GoRouter + Riverpod

### Phase 2 : Authentification
1. Créer `LoginScreen` avec WebView
2. Implémenter la capture de cookies post-login BNF
3. Créer `AuthProvider` (état auth, cookies, validation)
4. Stocker cookies dans flutter_secure_storage
5. Implémenter la revalidation automatique (30 min)

### Phase 3 : Services Europresse
1. Créer `HttpClient` avec injection de cookies (Dio + CookieJar)
2. Implémenter `EuropresseService.search()` (scraping HTML)
3. Implémenter `EuropresseService.getArticle()` (scraping HTML)
4. Implémenter `EuropresseService.searchSources()` (scraping HTML)
5. Tests unitaires du parsing HTML

### Phase 4 : Écrans principaux
1. `HomeScreen` avec flux RSS (parser XML, afficher par sections)
2. `SearchScreen` avec filtres (date, type, sources)
3. `ArticleScreen` avec rendu HTML (flutter_html)
4. `BookmarksScreen` avec persistance locale
5. `SettingsScreen` (déconnexion, gestion feeds)

### Phase 5 : Fonctionnalités avancées
1. Bookmarks persistés (shared_preferences ou Hive)
2. Gestion des feeds (ajouter, supprimer, réordonner, activer/désactiver)
3. Export PDF/HTML (printing package Flutter)
4. Pull-to-refresh sur les feeds
5. Mode hors-ligne pour les articles bookmarkés

---

## Commandes utiles

```bash
# Installation
brew install flutter
flutter doctor

# Création projet
cd /Users/drakiel/Documents/Projets/DPresse
flutter create --org com.dpresse --project-name dpresse .

# Développement
flutter run                    # Lancer sur émulateur/device
flutter pub get                # Installer dépendances
dart run build_runner build    # Générer code Riverpod

# Build
flutter build apk              # APK debug
flutter build appbundle         # AAB pour Play Store
```
