# Current Backend Compatibility

This Flutter package is aligned with the updated MathWorld ASP.NET Core API.

## Applied compatibility updates

- Uses `/api/problems/search` as the unified search endpoint.
- Sends `engine=meilisearch` by default and supports `SEARCH_ENGINE=postgresql`.
- Sends both `ProblemId` and `IsFavorite` to `/api/users/favorite/toggle`.
- Supports `/api/users/favorite/check/{problemId}`.
- Supports answer responses containing either `CorrectOptionId` or `CorrectOptionText`.
- Locks the answer UI after the first completed attempt.
- Parses flat and wrapped authentication responses.
- Keeps JWT values only in Flutter Secure Storage.
- Parses localized API errors, validation errors, and HTTP 429 responses.
- Sends both `Accept-Language` and `X-Language` headers.
- Supports optional profile picture URLs returned by local or social authentication.

## Search configuration

```env
SEARCH_ENGINE=meilisearch
```

Use the following value to force PostgreSQL search without changing Dart code:

```env
SEARCH_ENGINE=postgresql
```

PostgreSQL remains the source of truth. MeiliSearch is used only as the search index.
