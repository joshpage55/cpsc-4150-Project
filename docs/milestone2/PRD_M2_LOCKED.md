# ReadRight — Milestone 2 Locked Plan (PRD-Style Change Proposal)

**Team:** _[Names]_  
**Status:** DRAFT — lock by M2 submission  
**Baseline:** Inherited [readright](https://github.com/ztraboo/readright) @ Release 1.0  
**M3 measures against this document.**

---

## 1. Executive summary

ReadRight helps children practice **Dolch sight-word pronunciation** with feedback, while teachers manage classes and track progress. M2 locks three M3 pillars:

1. **Pronunciation** — maintain and improve scoring, feedback, and reliability  
2. **AI Story Builder** — Dolch-constrained stories via proxied mini-tier LLM  
3. **Dolch games** — at least one sight-word game layered on the same word bank  

---

## 2. Pillar A — Pronunciation (maintain & improve)

### Current inherited behavior
- Dolch curriculum in `data/seed_words.csv` (280 words, Pre-Primer → Fifth Grade)
- Student practice: hear sentence → record → STT (Deepgram online / Cheetah offline) → star feedback → Firestore attempt
- Teacher dashboard: class code, students, progress export

### M3 commitments (locked targets)
| Area | Keep | Improve |
|------|------|---------|
| Scoring | Jaro-Winkler + CMU phoneme hints | Tune thresholds per Dolch level; clearer kid-facing hints |
| STT | Cheetah on-device + cloud fallback | **Move cloud STT behind team proxy** (remove client API keys) |
| Audio | Pre-generated ElevenLabs MP3s | Cache strategy; fallback TTS when asset missing |
| Offline | Attempt queue sync | Surface sync status in student UI |
| Teacher tools | Class code login, progress view | DMMT fixes below (Section 5) |

### Non-goals for M3
- Multi-language support
- Parent portal

---

## 3. Pillar B — AI Story Builder

### User story
> As a **student**, I want a short story that uses my current Dolch words so reading practice feels like a game, not a drill.

### Flow (M3 build; M2 spike proves backend)
1. Student completes a Dolch level (or teacher assigns words)
2. App sends **word list only** (no API key) to `generateStorySpike` Cloud Function
3. Proxy builds Dolch-constrained prompt, calls **mini-tier model** (e.g. `gemini-2.0-flash-lite`)
4. Returns 80–120 word story; student reads aloud in existing practice pipeline

### Constraints (non-negotiable)
- Dolch words from `seed_words.csv` only in prompt; model instructed not to introduce off-list vocabulary where possible
- Reading level: Flesch-Kincaid target **grade 1–2**
- No API key in Flutter binary
- All LLM calls through `functions/generateStorySpike.js`

### M2 spike acceptance
- [ ] One story generated with ≥5 Dolch words from Pre-Primer list
- [ ] Evidence in `docs/milestone2/spike/`
- [ ] Model name + prompt logged in engineering log

### Open decisions (Person B to finalize)
- [ ] Teacher preview/approve before student sees story? **Y / N**
- [ ] Regenerate limit per day? **\_**

---

## 4. Pillar C — Dolch sight-word game(s)

**Pick at least one for M3** (team decision — check one):

- [ ] **Game 1: Word Match** — hear word → tap correct tile among 4 Dolch peers  
- [ ] **Game 2: Sentence Fill** — tap missing Dolch word in a sentence from seed data  
- [ ] **Game 3: Speed Read** — timed flash of level words, streak counter  

### Shared requirements
- Pull words from same Firestore / seed pipeline as practice screen
- Stars or streak map to existing `AttemptModel` or sibling `GameSessionModel` _(decide in M3)_
- Kid-safe: no external links, no chat

### Person B: add wireframe notes or Figma link
_[Link or embed description]_

---

## 5. DMMT-style UX critique (inherited app)

**Method:** Cognitive walkthrough as a **7-year-old student** and a **first-year teacher** on first use.

| Screen | Who | Hesitation / friction | M3 fix |
|--------|-----|----------------------|--------|
| Landing | Child | 3s auto-advance; no control | Add “Tap to start” |
| Reader selection | Child | “Teacher” vs “Student” text-heavy | Bigger icons + audio cue |
| Student login | Child | Username + class code unfamiliar | Illustration + “ask your teacher” |
| Passcode | Child | 6-digit OTP widget feels like phone login | Simplify to class code only if redundant |
| Word dashboard | Child | Levels without celebration context | Show mascot + “you are here” |
| Word practice | Child | Record button small; unclear when listening | Larger mic; “Listening…” state |
| Feedback | Child | Stars without “try again” guidance | One actionable tip per wrong word |
| Teacher register | Teacher | Long form before value shown | Show class code preview earlier |
| Teacher dashboard | Teacher | Dense list; export hidden | Primary actions above fold |
| Student details | Teacher | Audio playback unclear if retention off | Badge for retention + playback help |

### Top 3 M3 UX priorities
1. _[Team fill]_  
2. _[Team fill]_  
3. _[Team fill]_  

---

## 6. Technical dependencies

| System | Owner | Notes |
|--------|-------|-------|
| Team Firebase project | Person A | Replace inherited project ID when ready |
| Cloud Functions proxy | Person A | `generateStorySpike` |
| Flutter Web | Person A | UI demo; full Firebase optional M2 |
| Flutter Android | Person A | Full practice path for video |
| PRD & games spec | Person B | This document |
| Spike evidence | Person C | `docs/milestone2/spike/` |

---

## 7. Sign-off (lock)

| Name | Role | PRD approved | Date |
|------|------|--------------|------|
| | Engineering | ☐ | |
| | Product/UX | ☐ | |
| | AI/Spike | ☐ | |
