# Mobile architecture

This is an independent Flutter application. Run Flutter commands from this directory.
The workspace migration plan is `../ARCHITECTURE_MIGRATION.md`.

## Ownership and flow

`app/` owns startup and the root widget. `routes/` owns this app's routes.
`core/` owns configuration, errors, networking, storage, theme, icons and controls.
`data/` holds only cross-feature contracts. Feature-specific models, repository
interfaces, implementations, providers, viewmodels, views and widgets belong in
`features/<feature>/`. CRM's existing `roles/` and `shared/` remain supported.

Views watch providers and send intents to viewmodels. Viewmodels own validation,
state and orchestration; repositories coordinate services; services own HTTP and
storage. Do not call Dio or write credentials from a screen.

## Riverpod patterns

* `Provider`: dependency injection for services and repositories.
* `FutureProvider`: cached, read-only resources such as dashboard metadata.
* `StreamProvider`: external event subscriptions (`sessionEventsProvider` in new apps).
* `NotifierProvider`: synchronous immutable UI state such as dashboard search.
* `AsyncNotifierProvider`: asynchronous commands and paginated resources.

Use `AsyncValue.when` for loading/error/data. Empty collections are successful
empty states. Prefer feature-scoped auto-disposed providers for screen resources.
Use `ref.onDispose` for subscriptions, CancelTokens, Dio and controllers; watch a
provider instead of starting requests inside `build()`.

Subclass `core/utils/paginated_viewmodel.dart` inside a feature; implement
`fetchPage(cursor, cancelToken)` by delegating to its repository, and expose it
with `AsyncNotifierProvider.autoDispose`. `loadMore` deduplicates requests, keeps
existing results on failure and exposes a retryable `moreError`. `refresh` cancels
old requests and ignores stale completions. The first page uses AsyncValue for
loading/error/empty handling. The caller must supply stable server cursors.

Small immutable models use explicit JSON validation. Introduce Freezed and
json_serializable for more complex contracts when useful, with generated files
committed and generators pinned compatibly; they are not required for the small
session/catalog contracts in this setup.

## Design system

Use `core/theme/app_colors.dart`, `AppTypography`, bundled Inter 400/500/600/700,
and `core/icons/remix_icon.dart`. The font license is under `assets/fonts/OFL.txt`.
Typography works offline. Import controls from `core/widgets/app_<name>.dart`;
implementations live in `app_widgets.dart` so they cannot drift within the app.
Legacy CRM widgets stay in place to preserve existing constructor behavior.

Use RemixIcon/AppIcon for new UI and explicit labels for icon-only controls.
LegacyRemixIcons maps existing glyph names to Remix constants. Use LayoutBuilder,
SafeArea and scrollable forms; do not fix card heights around user text. Dashboard
layout is tested at 320px and 1024px width with 2x text scale.

## Configuration and validation

```
flutter pub get
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=https://your-api.example/api/v1
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --debug
```

APP_ENV accepts development, staging and production. API_BASE_URL must be an
absolute HTTP(S) URL without credentials, query or fragment. Staging, production
and all release builds require HTTPS. Do not embed API keys or secrets in Dart
defines. Each app has its own lockfile and native bundle identifiers.

Android release manifests include INTERNET. New apps disable automatic backups;
iOS uses per-app keychain entitlements. OS domain app/universal links require a
real owned domain and association files; GoRouter already resolves internal paths.
Native release signing and device-level authentication/keychain verification are
separate from debug/simulator build validation.

## CRM compatibility decisions

`main.dart` exports MyApp and the Firebase background entry point while bootstrap
and root widget live in `app/`. Preferences are passed into MyApp, eliminating the
startup global. The existing auth provider, secure-storage compatibility behavior,
API refresh coordination, notification navigator keys and role routes remain the
source of truth. `routes/app_router.dart` centralizes existing Navigator routes;
GoRouter is deferred because notification and role navigation need a coordinated
migration. No parallel session provider was introduced.

Active and legacy theme import paths resolve to the same palette/theme. All
application-owned explicit glyph references use Remix. The Material font remains
bundled because the existing YouTube player dependency requires its framework
controls; replacing third-party controls is outside this architecture migration.
Legacy auth preference fallbacks and older feature state patterns remain for a
separate, tested feature migration. New credential persistence must use secure
storage exclusively. New code must follow feature-scoped MVVM conventions.
