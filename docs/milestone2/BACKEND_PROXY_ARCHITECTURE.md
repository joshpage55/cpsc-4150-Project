# Backend Proxy & Secret Handling (M2)

**Team:** _[Names]_  
**Submit as PDF on Canvas**

---

## 1. Problem

The Flutter app must **never** embed LLM or STT API keys. Compiled APK/IPA/Web bundles can be inspected. M2 requires all generative-AI calls to go through a **thin backend proxy** that holds a single team key.

Inherited ReadRight also had a **Deepgram key in Dart** (`deepgram_assessor.dart`) — M3 will move STT behind the same pattern. M2 proves the pattern with the **story spike** only.

---

## 2. Architecture

```
┌─────────────────┐     HTTPS (no key)      ┌──────────────────────────┐
│  Flutter app    │ ───────────────────────▶│  Firebase Cloud Function │
│  (Web/Android)  │   dolchWords, level     │  generateStorySpike      │
└─────────────────┘                         └────────────┬─────────────┘
                                                         │ OPENAI_API_KEY
                                                         │ (secret / env)
                                                         ▼
                                              ┌──────────────────────────┐
                                              │  OpenAI API              │
                                              │  mini-tier (gpt-4o-mini) │
                                              └──────────────────────────┘
```

### Components

| Layer | Responsibility |
|-------|----------------|
| **Flutter** | Sends word list + reading level; displays story text |
| **Cloud Function** | Auth check (optional M3), prompt assembly, rate limit, calls OpenAI |
| **Secret store** | `firebase functions:secrets:set OPENAI_API_KEY` or local `.env` for spike script only |
| **GitHub** | Source code only; `.env` gitignored |

---

## 3. Where the key lives (and why)

| Location | Allowed? | Why |
|----------|----------|-----|
| `functions` runtime secret (`OPENAI_API_KEY`) | **Yes** | Not in repo; injected at deploy |
| Developer laptop `.env` (gitignored) | **Yes (dev only)** | For `scripts/m2_story_spike.mjs` before deploy |
| Canvas private announcement | **Yes** | Distribution to team only |
| `lib/*.dart`, `functions/index.js` committed | **No** | Visible in git history forever |
| GitHub Actions secrets | **Yes (CI)** | If we add automated spike tests later |

We use **Firebase Functions secrets** (or `functions.config()` legacy) so the same workflow works for all three developers without emailing keys in chat.

---

## 4. Prompt design (Dolch constraint)

The proxy builds a system prompt that:

1. Lists allowed Dolch words explicitly  
2. Caps length (80–120 words)  
3. Targets grade 1–2 readability  
4. Forbids markdown / titles (plain story text for TTS later)

See `functions/storyPrompt.js` and spike output in `docs/milestone2/spike/`.

---

## 5. Model guardrail

**Mandated mini-tier only** — configured via `OPENAI_MODEL=gpt-4o-mini` (confirm exact name on Canvas).

The function **rejects** requests if env model is not in the allowlist (`functions/storyPrompt.js`).

---

## 6. GitHub workflow safety

1. `.gitignore` includes `.env`, `.env.*`, `functions/.secret.local`  
2. `.env.example` documents variable **names** only  
3. PR review: grep for `AIza`, `sk-`, `apiKey =` in Dart/JS  
4. If key ever committed: rotate in Google AI Studio + Canvas announcement  

---

## 7. Local spike vs production

| Mode | Command | Key source |
|------|---------|------------|
| Local spike | `node scripts/m2_story_spike.mjs` | `.env` (gitignored) |
| Production | `firebase deploy --only functions:generateStorySpike` | Firebase secret |

Local spike proves the path before Flutter integration in M3.

---

## 8. Threat model (brief)

| Threat | Mitigation |
|--------|------------|
| Key scraped from app | No key in app |
| Key scraped from public repo | gitignore + review |
| Abuse of open endpoint | Firebase Auth + App Check (M3); `maxInstances` cap now |
| Runaway cost | Mini model; log token usage; instructor budget alert |

---

## 9. M3 extensions

- Wire Flutter `StoryService` → callable function  
- Move Deepgram behind `transcribeAudio` proxy  
- Teacher approval queue for generated stories  

---

_Export this file to PDF for Canvas submission._
