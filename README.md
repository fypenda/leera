# Leera

**Fluency through real topics.**

*Leera*, from the Wolof *leer*: clarity, light.

Speak about any topic in English, then get it corrected.

A topic is drawn at random. You research it yourself, without AI, then
present it, written or spoken, in a format also drawn at random (a voice
note, a TED intro, an email to an expert...). The AI corrects it: grammar,
richer vocabulary, rephrasing, structure, content, and an estimated level.

This app was extracted from the English module of
[NOURISH](https://github.com/fypenda/nourish) (commit `1d0a523`).

## Layout

| Path | What it holds |
| --- | --- |
| `lib/features/english/` | The whole feature: domain, data, application, pages |
| `lib/core/` | Database, AI backend client, audio, time, shared widgets |
| `lib/app/` | App entry, router, theme, AI settings page |
| `backend/` | Spring Boot gateway to Claude (the API key never ships in the app) |
| `ios/` | iOS project, with on-device speech transcription (`AppDelegate.swift`) |

## First run

Requires Flutter (Dart `^3.13.5`) and Xcode.

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev make-migrations   # records schema v1 in drift_schemas/
flutter test
```

`lib/core/database/app_database.g.dart` was cut down by hand from NOURISH's
generated file to the three English tables. `build_runner` regenerates it;
commit whatever it produces.

The backend: see [`backend/README.md`](backend/README.md).

## Still to do before the App Store

- Reserve the name Leera in App Store Connect, then set the final bundle
  id (provisionally `dev.penda.leera`).
- Bring the screens in line with the Leera design canvas (Today with the
  week and streak, Topic, Speak, Write, Feedback, Progress, Leera Plus).
- Replace the AI settings page (backend address and token typed by hand) by a
  built-in backend address and per-user authentication, with quotas.
- Onboarding (level, interests), a larger topic bank, streak, paywall
  (RevenueCat).
- Optional: bring back the vocabulary journal and score charts, which lived in
  NOURISH's Journal and Progress pages.
