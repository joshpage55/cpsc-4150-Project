# Engineering Log — Josh Page

**Course:** CPSC 4150 · M3  
**Repo:** `joshpage55/cpsc-4150-Project`

---

## 2026-07-12 — Clone + team repo

**What:** Cloned inherited readright; set origin to `joshpage55/cpsc-4150-Project`; kept upstream for reference.

**Result:** Done. Fixed GitHub auth (wrong cached account).

---

## 2026-07-12 — Flutter Web (M2 demo)

**What:** `flutter run -d chrome`; removed unused `dart:ffi` import; added `kIsWeb` guards in `main.dart`.

**Result:** Done. Landing and reader selection work on web.

---

## 2026-07-12 — Flutter Android (M2 demo)

**What:** Installed SDK 36; pinned NDK `28.0.12433566`; `flutter clean`; `flutter run -d emulator-5554`.

**Result:** Done. ReadRight runs on Pixel 9 API 36 emulator.

---

## 2026-07-12 — M2 docs + proxy + secrets

**What:** Team plan, PRD draft, proxy function, spike script, `.env.example`, gitignore rules, video script.

**Result:** Done. See `docs/milestone2/`.

---

## 2026-07-12 — Commit and push

**What:** Committed and pushed M2 scaffold to `origin/main` (commit `b8f96fe`).

**Result:** Done.

---

## 2026-07-12 — Team Firebase

**What:** Created `cpsc4150-readright`; ran `flutterfire configure` for Android, iOS, Web; updated `firebase_options.dart` and platform config files.

**Result:** Done. Invite teammates as Editors in Firebase Console.

---

## 2026-07-12 — Deploy generateStorySpike

**What:** Set `OPENAI_API_KEY` Firebase secret; migrated function to v2 `onCall` with `defineSecret`; deployed to `cpsc4150-readright` (`us-central1`).

**Result:** Done. Callable endpoint: `https://us-central1-cpsc4150-readright.cloudfunctions.net/generateStorySpike`.

---

## 2026-07-12 — Proxy spike (deployed function)

**What:** `node scripts/m2_call_story_proxy.mjs` — Dolch words → deployed Cloud Function → `gpt-4o-mini` → story.

**Result:** Done. Evidence in `docs/milestone2/spike/spike_result_via_proxy.json`. Key never left server; not in repo.

---

## 2026-07-12 — Logs

**What:** `prompt_log_joshpage.md` and this engineering log.

**Result:** Done.

---

## 2026-07-12 — Video + PDF (Josh portion)

**What:** Export PDF from `BACKEND_PROXY_ARCHITECTURE.md` for Canvas submission.

**Result:** Script done. Still need to **record** my video segment and **review PDF with team** before Canvas submit.

---

## 2026-07-26 — M3 Story Builder production path

**What:** Added `generateStory` (teacher-only), `approveStory`, draft Firestore `stories` docs, 3/day regen counters, stronger prompts + `contentSafety.js`, token logging + soft spend alerts.

**Result:** Code complete in `functions/`. Needs deploy to `cpsc4150-readright` before live demo.

---

## 2026-07-26 — M3 STT proxy + key removal

**What:** Added `transcribeAudio` Cloud Function; rewrote `DeepgramAssessor` to call the proxy with base64 audio; removed hardcoded Deepgram key from Flutter.

**Result:** Client no longer embeds STT key. Requires Firebase secret `DEEPGRAM_API_KEY` + function deploy.

---

## 2026-07-26 — Scoring + Word Match engine + StoryService

**What:** Level-aware pass thresholds + kid tip on feedback; `WordMatchEngine` for Person 2 UI; Flutter `StoryService` / `StoryRepository` / `StoryModel`.

**Result:** Core logic ready for teammates to skin. Smoke tests in `test/unit/m3_person1_smoke_test.dart`.

---

## 2026-07-26 — Deploy M3 functions

**What:** Deployed `generateStory`, `approveStory`, `transcribeAudio`, updated `generateStorySpike` to `cpsc4150-readright`.

**Result:** Functions live in `us-central1`. Cloud STT still needs `DEEPGRAM_API_KEY` set on the function env/secret before proxy transcription works; practice falls back to Cheetah until then.

