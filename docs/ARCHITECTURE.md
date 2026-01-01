## High-level architecture (Flutter + Riverpod)

- **Presentation (UI)**: Widgets, navigation, and styling only. No direct Supabase or storage calls.
- **Application (controllers)**: Riverpod `Notifier` / `@riverpod` providers that coordinate use-cases, loading, and errors.
- **Domain**: Pure Dart models and abstractions (`PostRepository`, `QuizSource`, etc.) with no Flutter or Supabase imports.
- **Data**: Concrete implementations that talk to Supabase, shared_preferences, or other IO (`DataService`, `SupabasePostRepository`, `StaticQuizSource`, etc.).

### Dependency rules

- UI → Application → Domain → Data.
- Only the **data** layer imports Supabase or other backends.
- UI reads state exclusively via Riverpod providers (`feedControllerProvider`, `authStateProvider`, `quizSourceProvider`, etc.).
- Global wiring (which implementation to use) lives in `lib/core/di/app_providers.dart`.

### Current Riverpod usage

- **Auth**:
  - Domain: `AuthRepository` in `lib/core/auth/auth_repository.dart`.
  - DI: `authRepositoryProvider` in `lib/core/di/app_providers.dart`.
  - Controller: `authStateProvider` in `lib/features/auth/application/auth_controller.dart`.
  - UI: `AuthWrapper` in `lib/screens/auth_wrapper.dart` chooses `HomeScreen` vs `LoginScreen` based on `authStateProvider`.

- **Feed / Trending**:
  - Domain: `PostRepository` in `lib/core/feed/post_repository.dart`.
  - Data: `DataService` (local demo) and `SupabasePostRepository` (Supabase) implement `PostRepository`.
  - DI: `postRepositoryProvider` in `lib/core/di/app_providers.dart` selects implementation based on `AppConfig`.
  - Controller: `FeedController` + `feedControllerProvider` in `lib/features/feed/application/feed_controller.dart`.
  - UI: `HomeScreen` and `TrendingScreen` read posts via `feedControllerProvider`.

- **Quizzes (in progress)**:
  - Domain: `QuizSource` in `lib/features/quiz/domain/quiz_source.dart`.
  - Data: `StaticQuizSource` in `lib/features/quiz/data/static_quiz_source.dart` wraps the legacy static `QuizRepository`.
  - Controller/DI: `quizSourceProvider` in `lib/features/quiz/application/quiz_providers.dart`.
  - UI (for now) still uses `QuizRepository` directly; future work will migrate it to `quizSourceProvider`.

As Supabase integrations expand (realtime, quizzes, classes), new data sources should implement the domain interfaces and be exposed via Riverpod providers, without changing UI code.

