# Milestone 2 — Team Plan & Work Split

**Course:** Team Project · Milestone 2  
**Repo:** `cpsc-4150-Project`  
**Due:** See Canvas (M2 checkpoint)

## What M2 requires (checklist)

| # | Deliverable | Where it lives | Done? |
|---|-------------|----------------|-------|
| 1 | Inherited app runs on **Flutter Web + mobile** (live in video) | App + video | ☐ |
| 2 | **Locked PRD** (3 pillars + DMMT UX critique) | `docs/milestone2/PRD_M2_LOCKED.md` | ☐ |
| 3 | **AI story de-risk spike** (proxy → mini model → Dolch prompt → story) | `functions/`, `docs/milestone2/spike/` | ☐ |
| 4 | **Prompt logs** (six prompts, one per student) | `docs/logs/prompt_log_*.md` | ☐ |
| 5 | **Engineering logs** (individual) | `docs/logs/engineering_log_*.md` | ☐ |
| 6 | **Milestone video** (~4–5 min, all members speak, Kaltura) | Canvas link | ☐ |
| 7 | **Proxy & secret-handling writeup (PDF)** | `docs/milestone2/BACKEND_PROXY_ARCHITECTURE.md` → export PDF | ☐ |
| 8 | GitHub access for `edwoost@clemson.edu`, `niswar@clemson.edu` | GitHub repo settings | ☐ |

## Suggested split (team of 3)

Adjust names in the third column.

### Person A — Engineering / Runtime (Josh — head start in repo)

**Owns:** “Inherited app runs” + proxy infrastructure

- [ ] Clone (not fork) + team remote — **done**
- [ ] Flutter Web: landing → reader selection at minimum (`kIsWeb` guards in `main.dart`)
- [ ] Flutter Android: emulator build + demo login flow in video
- [ ] Stand up **your team Firebase project** (replace inherited `readright-2ad31` when ready)
- [ ] Implement & deploy `generateStorySpike` Cloud Function (key in env/secret only)
- [ ] `.env.example`, `.gitignore`, no keys in Dart/JS committed
- [ ] Draft `BACKEND_PROXY_ARCHITECTURE.md` (teammates review → PDF)
- [ ] `engineering_log_joshpage.md` (or your name)
- [ ] Video segment: live app demo (web + Android)

### Person B — Product / PRD / UX

**Owns:** “Locked plan” rubric

- [ ] Lead `PRD_M2_LOCKED.md`: finalize all **three pillars**
  1. Pronunciation maintenance & improvements
  2. AI Story Builder (user flow, Dolch constraints, teacher controls)
  3. Dolch sight-word game(s) — pick 1–2 and spec rules/UI
- [ ] Write **DMMT-style critique** of inherited app (child + teacher hesitation points)
- [ ] Map critique → M3 fixes (prioritized)
- [ ] `prompt_log_<name>.md` + `engineering_log_<name>.md`
- [ ] Video segment: PRD pillars + UX critique (1–2 min)

### Person C — AI Spike / Evidence / Logs

**Owns:** “AI story de-risk spike” rubric

- [ ] Run `scripts/m2_story_spike.mjs` with team key from **private Canvas** (never commit)
- [ ] Save spike output to `docs/milestone2/spike/spike_result_<date>.json` (redact key)
- [ ] Confirm **mini-tier model only** (see `.env.example`)
- [ ] Document prompt template + Dolch word list used
- [ ] `prompt_log_<name>.md` + `engineering_log_<name>.md`
- [ ] Video segment: show spike request/response + explain proxy (no key in app)

### Everyone (same week as due date)

- [ ] Record **one** Kaltura video; each person speaks
- [ ] Canvas: repo URL + Kaltura link
- [ ] Invite graders on GitHub

## Weekly rhythm (2-week runway to M3)

| Week | Focus |
|------|--------|
| **M2 week 1** | App runs both platforms; spike works; PRD 80% draft |
| **M2 week 2** | PRD locked; logs complete; video recorded; PDF submitted |

## Commands cheat sheet

```bash
# Web
cd "/Users/joshpage/4150 Project"
flutter pub get
flutter run -d chrome

# Android (start emulator first)
flutter emulators --launch Pixel_9_API_36
flutter run -d emulator-5554

# AI spike (local, key in .env — never commit .env)
cp .env.example .env   # fill OPENAI_API_KEY from Canvas
node scripts/m2_story_spike.mjs

# Deploy proxy (after team Firebase + billing)
cd functions && npm install
firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions:generateStorySpike
```

## Risks already identified

| Risk | Mitigation |
|------|------------|
| Inherited Firebase project not yours | Create team Firebase; run `flutterfire configure` |
| Web has no `firebase_options` web entry | FlutterFire CLI or skip Firebase on web for M2 demo UI |
| Disk space for Android SDK | Free space; pin NDK to `28.0.12433566` (done in `build.gradle.kts`) |
| API keys in inherited code (Deepgram) | M3: move STT behind proxy; M2: story proxy only |
