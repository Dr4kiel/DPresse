# DPresse

**Client mobile pour [Europresse](https://nouveau.europresse.com) via la Bibliotheque nationale de France.**

DPresse permet de consulter la presse en ligne gratuitement en utilisant l'acces Europresse fourni par la BNF. L'application combine des flux RSS de grands titres de la presse francaise avec la recherche et la lecture d'articles complets sur Europresse.

## Fonctionnalites

- **Flux RSS** — Agregation de flux de Liberation, Le Monde, Courrier International, Le Monde Diplomatique, etc.
- **Recherche Europresse** — Recherche en texte integral ou par titre, avec filtres par date
- **Lecture d'articles** — Affichage complet des articles dans un rendu HTML optimise pour mobile
- **Correspondance RSS/Europresse** — Tap sur un article RSS pour retrouver et lire l'article complet via Europresse (matching par similarite de titres)
- **Favoris** — Sauvegarde d'articles pour lecture ulterieure
- **Themes clair & sombre** — Interface Material 3 avec palette encre/papier

## Comment ca marche

1. L'utilisateur se connecte via une WebView au portail BNF (authentification SAML via EZproxy)
2. Les cookies de session sont captures et stockes de maniere securisee
3. L'application utilise ces cookies pour interroger Europresse directement, sans backend intermediaire

## Stack technique

| Composant | Technologie |
|---|---|
| Framework | Flutter 3.38 / Dart 3.10 |
| State management | Riverpod |
| Navigation | GoRouter |
| HTTP | Dio + cookie injection manuelle |
| Auth | WebView + flutter_secure_storage |
| Parsing | html (scraping), xml (RSS), flutter_html (rendu) |
| UI | Material 3, Google Fonts (Inter) |

## Structure du projet

```
lib/
  main.dart              # Point d'entree
  app.dart               # MaterialApp.router + theme
  core/                  # Constantes, theme, router
  models/                # Article, SearchResult, Feed, FeedItem
  services/              # Auth, Europresse, HTTP, HTML parser, RSS
  providers/             # Riverpod providers (auth, search, article, feeds, bookmarks, settings)
  screens/               # Login, Home, Search, Article, Bookmarks, Settings
  widgets/               # ArticleCard, BottomNav, FeedSection, SearchFilters
```

## Build

```bash
# Lancer en mode debug (necessite un appareil Android connecte ou un emulateur)
flutter run

# Generer un APK
flutter build apk

# Analyse statique
flutter analyze
```

## Prerequis

- Flutter 3.38+
- Android SDK (pas de support iOS pour le moment)
- Un compte BNF (inscription gratuite sur [bnf.fr](https://www.bnf.fr))

## Licence

Projet personnel, non affilie a la BNF ni a Europresse.
