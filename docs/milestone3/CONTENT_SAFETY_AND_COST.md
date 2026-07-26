# Content Safety & Cost Instrumentation (CPSC 6150)
## ReadRight — Milestone 3 draft (Person 1 / Josh Page)

**Status:** Draft for Person 3 polish · Team Firebase project `cpsc4150-readright`

---

## 1. What we guard

Story generation is **teacher-initiated only**. A student never calls the LLM directly. Flow:

1. Teacher selects **student**, **reading level**, **interest**, and Dolch words.
2. Flutter `StoryService.generateDraft` calls Cloud Function `generateStory` (no OpenAI key in the app).
3. Proxy builds a Dolch-constrained, age-appropriate prompt (`functions/storyPrompt.js`).
4. Model is **mini-tier only** (`gpt-4o-mini` / allowlisted minis).
5. Automated **content-safety filter** rejects drafts that match a violence / adult blocklist (`functions/contentSafety.js`).
6. Story is stored as **`status: draft`** in Firestore `stories`.
7. Teacher **preview / approve** (`approveStory`) flips status to `approved` — only then can the student see it.
8. Regenerates are capped at **3 per teacher per day** (`story_regen_counters`).

Teacher-in-the-loop is both the content-safety story and the cost-control story.

---

## 2. Automated guardrails (pre-approve)

| Guardrail | Where | Behavior |
|-----------|--------|----------|
| Teacher-only auth | `generateStory` / `approveStory` | Reads `users/{uid}.role == teacher` |
| Interest validation | `validateInterest` | Rejects empty / long / blocked topics |
| Prompt constraints | `buildStoryPrompt` | Ages 5–8, Dolch preference, no violence / romance / drugs |
| Mini-tier lock | `resolveModel` | Rejects non-allowlisted models |
| Output filter | `checkStorySafety` | Fails generation if blocked terms appear |
| Regen limit | `consumeRegenSlot` | Soft product cap: 3 generates/day |

Unsafe output returns `failed-precondition` to the client so the teacher can change interest / words and try again (within the daily cap).

---

## 3. Token / usage logging

Every successful OpenAI call writes:

- **`ai_usage_logs`** — per-call: teacherId, studentId, model, prompt/completion/total tokens, dayKey, feature
- **`ai_usage_daily/{YYYY-MM-DD}`** — running total tokens for the calendar day

Returned to the client on generate: `usage`, `dailyTokens`, `softSpendAlert`.

---

## 4. Soft spend-alert path (not a hard cap)

Course budget is a **soft alert to the instructor**, not a kill switch.

1. Constant `SOFT_DAILY_TOKEN_BUDGET` (default **50,000** tokens/day team-wide) in `contentSafety.js`.
2. When `ai_usage_daily.totalTokens` crosses the budget:
   - Structured `console.warn` with `type: "SOFT_SPEND_ALERT"` (visible in Firebase Functions logs)
   - Document written to **`ai_spend_alerts`**
3. Generation **continues** — teacher can still approve stories; the alert is the signal to email / notify the instructor.

**How to demo in practice**

1. Deploy functions with `OPENAI_API_KEY` set.
2. As a teacher, call `generateStory` a few times (or temporarily lower `SOFT_DAILY_TOKEN_BUDGET` in a local emulator run).
3. Show Firestore `ai_usage_logs` + `ai_usage_daily` growing.
4. Show an `ai_spend_alerts` doc (or Functions log line) after crossing the budget.
5. Confirm the Flutter client receives `softSpendAlert: true` without crashing the flow.

---

## 5. STT key handling (related architecture)

Cloud STT routes through **`transcribeAudio`**. Configure with:

```bash
firebase functions:secrets:set DEEPGRAM_API_KEY
# then bind defineSecret on the function, or set function env DEEPGRAM_API_KEY
```

The hardcoded Deepgram token was removed from `lib/audio/stt/cloud/deepgram_assessor.dart` in M3. Until the server key is set, practice falls back to on-device Cheetah.

---

## 6. Secrets checklist

| Secret | Location | In GitHub? | In Flutter? |
|--------|----------|------------|-------------|
| `OPENAI_API_KEY` | Firebase secret | No | No |
| `DEEPGRAM_API_KEY` | Firebase secret | No | No |
| `.env` | Local only (gitignored) | No | No |

---

## 7. Files to cite in the video / oral defense

- `functions/contentSafety.js`
- `functions/storyPrompt.js`
- `functions/index.js` — `generateStory`, `approveStory`, `transcribeAudio`, `logAiUsage`
- `lib/services/story_service.dart`
- `docs/milestone2/BACKEND_PROXY_ARCHITECTURE.md` (M2 baseline)

_Person 3: polish tone, add screenshots of Firestore logs / alert docs, and attach to Canvas as needed._
