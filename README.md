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
| `lib/core/` | Database, backend client, Sign in with Apple and session, audio, time, shared widgets |
| `lib/app/` | App entry, router, theme, sign-in and account pages |
| `backend/` | Spring Boot: accounts, quotas, and the gateway to Claude (the API key never ships in the app) |
| `ios/` | iOS project, with on-device speech transcription (`AppDelegate.swift`) |

## First run

Requires Flutter (Dart `^3.13.5`) and Xcode.

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev make-migrations   # records schema v1 in drift_schemas/
flutter test
flutter run --dart-define=LEERA_API_URL=http://localhost:8080
```

The app opens on Sign in with Apple, then talks to the backend at
`LEERA_API_URL` (`http://localhost:8080` when not given). Sign in with Apple
needs the capability on the App ID in the Apple Developer account
(`ios/Runner/Runner.entitlements` already asks for it) and a device or
simulator signed in to an Apple ID.

Before the paid Apple Developer account exists, Sign in with Apple cannot
work. Start the backend with `LEERA_DEV_SIGN_IN=true` and use the "Developer
sign-in" button, shown in debug builds only. To install on an iPhone with a
free account, also remove `CODE_SIGN_ENTITLEMENTS` from the Runner target in
Xcode (Signing & Capabilities: remove "Sign in with Apple"), and put it back
once the account is paid.

`lib/core/database/app_database.g.dart` was cut down by hand from NOURISH's
generated file to the three English tables. `build_runner` regenerates it;
commit whatever it produces.

The backend: see [`backend/README.md`](backend/README.md).

## Still to do before the App Store

- Reserve the name Leera in App Store Connect, then set the final bundle
  id (provisionally `dev.penda.leera`).
- Explore and Journal in the tab bar. Every other screen of the Leera
  design is done.
- Selling Leera Plus: the paywall (`lib/app/plus/`) runs on `StoreNotReady`,
  which shows the plans without prices and sells nothing. Implement
  `Purchases` (`lib/core/purchases/purchases.dart`) with RevenueCat once the
  products exist in App Store Connect, and add the RevenueCat webhook on the
  backend to set `plus_until`.
- Terms and Privacy: Apple requires working links on the paywall for a
  subscription. Publish both pages, then link them there.
- "Pick your themes" and "Vocabulary review" are on the paywall marked
  "Soon": build them, or take them off before review.
- Revoke the Sign in with Apple tokens when an account is deleted (see
  `backend/README.md`).
- Onboarding (level, interests), a larger topic bank, streak.
- Optional: bring back the vocabulary journal, which lived in NOURISH's
  Journal page.
