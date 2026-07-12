# Engineering Log — Josh Page

**Course:** CPSC 4150 · M2  
**Repo:** `joshpage55/cpsc-4150-Project`

---

## 2026-07-12 — Clone + team repo

**What:** Cloned inherited readright; set origin to `joshpage55/cpsc-4150-Project`; kept upstream for reference.

**Result:** Team owns the repo. Fixed GitHub auth (wrong cached account).

---

## 2026-07-12 — Flutter Web (M2 demo)

**What:** `flutter run -d chrome`; removed unused `dart:ffi` import; added `kIsWeb` guards in `main.dart`.

**Result:** Landing and reader selection work on web. Full auth needs team Firebase web config.

---

## 2026-07-12 — Flutter Android (M2 demo)

**What:** Installed SDK 36; pinned NDK `28.0.12433566`; `flutter clean`; `flutter run -d emulator-5554`.

**Result:** ReadRight runs on Pixel 9 API 36 emulator. Low disk space blocks starting a second emulator instance.

---

## 2026-07-12 — M2 docs + proxy + secrets

**What:** Added `M2_TEAM_PLAN.md`, `PRD_M2_LOCKED.md`, `BACKEND_PROXY_ARCHITECTURE.md`, `generateStorySpike`, `m2_story_spike.mjs`, `.env.example`, `.gitignore` secret rules.

**Result:** Teammates can own PRD, spike, and PDF. Proxy code ready to deploy.

---

## 2026-07-12 — Commit and push

**What:** Stage M2 scaffold, web/android fixes, logs. Verify `.env` not staged. Push to origin main.

**Result:** Pending — run `git add`, `git status`, `git commit`, `git push` before deadline.

---

## 2026-07-12 — Team Firebase + deploy (next)

**What:** Create team Firebase project; `flutterfire configure`; `firebase functions:secrets:set GEMINI_API_KEY`; deploy `generateStorySpike`.

**Result:** Not done yet. Still on inherited `readright-2ad31` for local demo.

---

## 2026-07-12 — Video + PDF

**What:** Export `BACKEND_PROXY_ARCHITECTURE.md` to PDF for Canvas. Record segment: Chrome demo, Android demo, proxy explanation.

**Result:** Draft PDF source in repo. Video with full team still to record on Kaltura.
