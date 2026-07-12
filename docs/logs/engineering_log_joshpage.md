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

**What:** Created Firebase project `cpsc4150-readright`; updated `.firebaserc`; wrote `FIREBASE_TEAM_SETUP.md`.

**Result:** Project created. Teammates need Editor invites. Flutter client still uses inherited config until `flutterfire configure`.

---

## 2026-07-12 — Deploy generateStorySpike

**What:** `firebase deploy --only functions` to `cpsc4150-readright`.

**Result:** Blocked — project must upgrade to **Blaze** plan. After upgrade: set `OPENAI_API_KEY` secret and redeploy. Teammate with Canvas key runs local spike.

---

## 2026-07-12 — Logs

**What:** Finished `prompt_log_joshpage.md` and this engineering log.

**Result:** Done.

---

## 2026-07-12 — Video + PDF

**What:** `VIDEO_SCRIPT_JOSH.md` for my segment. PDF from `BACKEND_PROXY_ARCHITECTURE.md`.

**Result:** Script done. PDF in `docs/milestone2/` if generated. Full team Kaltura video and team PDF review still needed.
