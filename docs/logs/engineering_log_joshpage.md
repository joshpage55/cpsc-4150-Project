# Engineering Log — Josh Page

**Course:** CPSC 4150 · M2  
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

**What:** `VIDEO_SCRIPT_JOSH.md` written. Export PDF from `BACKEND_PROXY_ARCHITECTURE.html` (Chrome → Print → Save as PDF).

**Result:** Script done. Still need to **record** my video segment and **review PDF with team** before Canvas submit.
