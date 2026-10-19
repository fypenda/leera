# Backend

The backend of Leera. People sign in with Apple; each correction counts
against their quota; the backend asks Claude to correct the presentation
(written, or spoken then transcribed on the device), checks the answer and
sends it back.

It keeps as little as it can: an account per Apple ID (Apple's opaque user
id, no name, no email, whether it has Leera Plus) and the time of each
correction, to count them. Presentations and corrections stay on the device.

It exists so that the Anthropic API key never ships inside the app.

## Run it

Requires Java 21, Maven (`brew install maven`) and PostgreSQL. Locally, with
Docker:

```sh
docker run -d --name leera-db -p 5432:5432 \
  -e POSTGRES_DB=leera -e POSTGRES_USER=leera -e POSTGRES_PASSWORD=leera postgres:17

cd backend
export ANTHROPIC_API_KEY=sk-ant-...                  # from console.anthropic.com
export LEERA_SESSION_SECRET=$(openssl rand -hex 32)
mvn spring-boot:run
```

The tables are created at start-up (Flyway, `src/main/resources/db/migration`).
The backend refuses to start without the API key or the session secret.

```sh
curl localhost:8080/api/v1/health    # {"status":"ok"}
```

The app reaches it at the address it was built with
(`--dart-define=LEERA_API_URL=...`, `http://localhost:8080` by default, which
works in the simulator). Sign in with Apple needs a real device or a
simulator signed in to an Apple ID.

## Test it

```sh
mvn test
```

No test calls Anthropic or Apple: the model is replaced by a fake, Apple's
keys by a key the tests generate, and PostgreSQL by H2.

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `ANTHROPIC_API_KEY` | none, required | Anthropic API key |
| `LEERA_SESSION_SECRET` | none, required | Signs sessions; 32 characters at least |
| `LEERA_DATABASE_URL` | `jdbc:postgresql://localhost:5432/leera` | PostgreSQL |
| `LEERA_DATABASE_USER` / `LEERA_DATABASE_PASSWORD` | `leera` / `leera` | Its credentials |
| `LEERA_APPLE_AUDIENCES` | `dev.penda.leera` | The app's bundle id(s), comma-separated |
| `LEERA_FREE_PER_WEEK` | `1` | Corrections per week on the free plan |
| `LEERA_PLUS_PER_DAY` | `3` | Corrections per day on Leera Plus |
| `LEERA_MODEL` | `claude-sonnet-5-5` | Model used for corrections |
| `LEERA_REQUESTS_PER_HOUR` | `600` | Ceiling on requests for the whole backend |
| `ANTHROPIC_BASE_URL` | `https://api.anthropic.com` | Changed only for tests |
| `PORT` | `8080` | HTTP port |

## API

Every path except the first two needs `Authorization: Bearer <accessToken>`.

| Method | Path | Body | Answer |
| --- | --- | --- | --- |
| GET | `/api/v1/health` | none | `{"status":"ok"}` |
| POST | `/api/v1/auth/apple` | `{"identityToken", "nonce"}` | `{"accessToken", "expiresAt", "quota"}` |
| GET | `/api/v1/me` | none | `{"quota"}` |
| DELETE | `/api/v1/account` | none | 204: the account and its sessions are gone |
| POST | `/api/v1/english/feedback` | `FeedbackRequest` | `FeedbackResponse` |

`quota` is `{"plan": "free" | "plus", "used", "limit", "resetsAt"}`. The free
week starts on Monday at 00:00 UTC; the Plus day at 00:00 UTC. A correction
that fails (the model is down, refuses, or answers badly) is not counted.

Signing in: the app makes a random `nonce`, gives Sign in with Apple its
SHA-256 (hex), and sends the raw `nonce` here with Apple's `identityToken`.
The backend checks the token against Apple's published keys, its issuer, its
audience (`LEERA_APPLE_AUDIENCES`), its expiry and the nonce, then creates the
account the first time. Sessions last 30 days.

Errors are `{"code": "...", "message": "..."}`. Codes: `unauthorized` (401:
no session, or an expired or forged one, or a deleted account),
`invalid_identity` (401: Apple's token was refused), `quota_exceeded` (429),
`invalid_request` (400), `rate_limited` (429, with `Retry-After`),
`ai_unavailable` (502), `ai_invalid_response` (502), `ai_refused` (422),
`internal_error` (500). Messages never repeat what was sent.

### Feedback request

```json
{
  "topicTitle": "How the Suez Canal changed world trade",
  "topicPrompt": "Find out who built it, why it mattered, ...",
  "formatLabel": "Short essay",
  "formatConstraint": "250 to 350 words",
  "presentation": "The Suez Canal opened in 1869...",
  "recurringMistakes": ["prepositions", "articles"],
  "spoken": false
}
```

`spoken` (optional, false by default) says the presentation is the
transcript of a recording: the model is then told to judge it as speech and
to leave alone punctuation, spelling and words that sound alike, which come
from the transcription. Audio never reaches the backend.

Only what the correction needs is sent: no notes, no identifier, nothing
about the person.

### Feedback response

`promptVersion`, `model`, `createdAt`, `estimatedLevel` (A2 to C2),
`headline`, `summary`, `scores` (grammar, vocabulary, naturalness, structure,
content, each 0 to 10), `corrections` (kind, original, corrected, mistake,
fix, explanation, tag), `vocabulary` (expression, meaning, example),
`followUpQuestions`, `recurringMistakesSeen`. These names are a contract with
the app, which stores responses: change them only by adding fields, or with a
new prompt version.

## How a correction is made

```
EnglishController → FeedbackService → AiClient (interface) → AnthropicAiClient → Messages API
```

- **Prompt and schema are versioned files**:
  `src/main/resources/prompts/english/feedback-v1.md` and
  `feedback-v1.schema.json`. The version goes back with every answer, so
  corrections made with different prompts can be told apart. To change the
  prompt, add `feedback-v2.*` and switch `FeedbackService.PROMPT_VERSION`.
- **Structured outputs**: the schema is sent as `output_config.format`, so the
  model answers with JSON of that shape.
- **Checked anyway**: scores are kept between 0 and 10, lists are shortened,
  corrections that change nothing are dropped, tags are normalised. An answer
  that cannot be used is asked for once more, then the request fails.
- **The presentation is data**: it is placed between tags, and a closing tag
  inside it is defused, so it cannot pass itself off as instructions.
- **`AiClient` is an interface**: another provider can replace Anthropic
  without touching the features.
- **Shared by every feature**: `PromptTemplate` loads a versioned prompt and
  its schema (`prompts/<area>/<version>.*`), `AiCalls.withOneRetry` asks once
  more after an unusable answer, and `AiCalls.enclosed` puts personal text
  between tags.

## Security

- The Anthropic key and the session secret live in the backend's environment
  only.
- Every `/api/` path except the health check and signing in needs a session,
  signed with HMAC-SHA256, unexpired, for an account that still exists.
- Each account has its quota; on top of that, at most
  `LEERA_REQUESTS_PER_HOUR` authenticated requests per hour for the whole
  backend, the last guard on the bill. Refused requests do not count. That
  counter is in memory and resets on restart.
- Presentations and corrections are neither stored nor logged.

## Deploy

Any host that runs a container works (Render, Railway, Fly.io, Cloud Run),
with a managed PostgreSQL (Neon and Supabase have free tiers).

```sh
docker build -t leera-backend .
docker run -p 8080:8080 \
  -e ANTHROPIC_API_KEY -e LEERA_SESSION_SECRET \
  -e LEERA_DATABASE_URL -e LEERA_DATABASE_USER -e LEERA_DATABASE_PASSWORD \
  leera-backend
```

Serve it over HTTPS: the app sends its session with every request.

## Not done yet

- Leera Plus is read from `accounts.plus_until`, but nothing sets it yet: the
  RevenueCat webhook will, once the paywall exists.
- Apple asks that deleting an account also revokes its Sign in with Apple
  tokens (`appleid.apple.com/auth/revoke`). That needs a key from the Apple
  Developer account; until then, deleting removes everything the backend holds.
