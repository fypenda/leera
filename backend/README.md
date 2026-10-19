# Backend

The AI gateway of the app. It receives an English presentation,
written or spoken then transcribed on the device, asks Claude to correct it, checks the answer and sends it back.
It stores nothing: the app keeps every correction on the device.

It exists so that the Anthropic API key never ships inside the app.

## Run it

Requires Java 21 and Maven (`brew install maven`).

```sh
cd backend
export ANTHROPIC_API_KEY=sk-ant-...        # from console.anthropic.com
export LEERA_APP_TOKEN=$(openssl rand -hex 32)
echo $LEERA_APP_TOKEN                     # enter it in the app's AI settings
mvn spring-boot:run
```

The backend refuses to start without both values. Check it:

```sh
curl localhost:8080/api/v1/health                                  # {"status":"ok"}
curl -H "X-App-Token: $LEERA_APP_TOKEN" localhost:8080/api/v1/ping
```

In the iPad simulator, the app reaches it at `http://localhost:8080`. On a
real device, use the Mac's address on the local network
(`http://<name>.local:8080`) or deploy it (below).

## Test it

```sh
mvn test
```

No test calls Anthropic: the model is replaced by a mock server or a fake.

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `LEERA_APP_TOKEN` | none, required | Secret the app sends in `X-App-Token` |
| `ANTHROPIC_API_KEY` | none, required | Anthropic API key |
| `LEERA_MODEL` | `claude-sonnet-5-5` | Model used for corrections |
| `LEERA_REQUESTS_PER_HOUR` | `60` | Ceiling on authenticated requests |
| `ANTHROPIC_BASE_URL` | `https://api.anthropic.com` | Changed only for tests |
| `PORT` | `8080` | HTTP port |

## API

| Method | Path | Token | Body | Answer |
| --- | --- | --- | --- | --- |
| GET | `/api/v1/health` | no | none | `{"status":"ok"}` |
| GET | `/api/v1/ping` | yes | none | `{"status":"ok"}`, to check the app's settings |
| POST | `/api/v1/english/feedback` | yes | `FeedbackRequest` | `FeedbackResponse` |

Errors are `{"code": "...", "message": "..."}`. Codes: `unauthorized` (401),
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

- The Anthropic key lives in the backend's environment only.
- Every `/api/` path except the health check needs `X-App-Token`, compared in
  constant time.
- At most `LEERA_REQUESTS_PER_HOUR` authenticated requests per hour, so a
  leaked token cannot run up an unlimited bill. Refused requests do not count.
  The counter is in memory and resets on restart.
- Nothing is stored and presentations are not logged.

## Deploy

```sh
docker build -t leera-backend .
docker run -p 8080:8080 \
  -e ANTHROPIC_API_KEY -e LEERA_APP_TOKEN leera-backend
```

Any host that runs a container works (Render, Railway, Fly.io, a small VPS).
Serve it over HTTPS: the app sends the token with every request.
