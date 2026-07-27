# ReadRight — Milestone 3 Locked Plan (PRD-Style Change Proposal)

**Team:** _[Josh Page, Tyson Small, Gabriel Walker]_  
**Status:** LOCKED — M3 submission  
**Baseline:** Inherited [readright](https://github.com/ztraboo/readright) @ Release 1.0  
**Scope:** Build on Milestone 2 by delivering the M3 experience for pronunciation, AI story reading, and a Dolch sight-word game.

---

## 1. Executive summary

ReadRight helps children practice **Dolch sight-word pronunciation** while teachers manage classes, track progress, and now introduce richer reading experiences. Milestone 3 locks three pillars:

1. **Pronunciation** — preserve and improve the practice loop with clearer feedback and child-friendly UX
2. **AI Story Builder / Story Reading** — allow teachers to create a story draft for a student and let the student read the approved story later
3. **Dolch games** — deliver at least one sight-word game layered on the same word bank used by practice

---

## 2. Pillar A — Pronunciation (maintain & improve)

### Current inherited behavior
- Dolch curriculum in `data/seed_words.csv` (Pre-Primer → Fifth Grade)
- Student practice: hear word → record → STT assessment → feedback → Firestore attempt
- Teacher dashboard: class roster, student progress, and class-level progress tools

### M3 commitments (locked targets)
| Area | Keep | M3 status |
|------|------|-----------|
| Scoring | Jaro-Winkler + CMU phoneme hints | Implemented in practice/feedback flow with visible feedback guidance |
| STT | Cheetah on-device + cloud fallback | Continued in the app; cloud path remains dependent on runtime environment and configuration |
| Audio | Pre-generated ElevenLabs MP3s + TTS fallbacks | Implemented in practice and feedback paths |
| Offline | Attempt queue sync | Partially addressed conceptually; runtime sync status not fully polished in UI |
| Teacher tools | Class login, progress view, class management | Implemented with improved teacher dashboard and student progress visibility |

### M3 delivery notes
- The pronunciation loop remains the core of the app and is the main path for student practice.
- The feedback experience is more child-friendly and now includes a practical next-step tip.
- The practice UI was improved with a larger microphone-style call to action and clearer listening state.

### Non-goals for M3
- Multi-language support
- Parent portal
- Fully polished offline-first sync behavior

---

## 3. Pillar B — AI Story Builder + Student Story Reading

### User story
> As a **teacher**, I want to create a Dolch-themed story for a student and approve it before the student reads it.  
> As a **student**, I want to open approved stories and read them in a simple, low-friction view.

### M3 flow
1. Teacher signs in and opens the **Story Builder** from the teacher dashboard.
2. Teacher selects a student, a reading level, and an interest topic.
3. App generates a story draft using a Dolch-oriented prompt and previewable content.
4. Teacher can preview, regenerate, or approve the draft.
5. Approved stories appear in the student’s **Stories** view for later reading.

### Constraints
- Story content should remain readable for early readers and aligned to Dolch-style vocabulary where possible.
- Teacher approval is required before the student sees the story.
- Story generation should not require client-side API keys.

### M3 status
- [x] Teacher-facing story builder UI implemented
- [x] Story draft preview and approve/regenerate actions implemented
- [x] Student story view implemented for approved stories
- [ ] Full end-to-end verification against live Firebase/LLM runtime remains pending in the local environment

### Honest assessment
The core story flow is now present in the app and wired through the teacher/student experience, but the feature still needs live runtime validation to confirm the full backend path and content generation quality under real conditions.

---

## 4. Pillar C — Dolch sight-word game(s)

**Pick at least one for M3** (team decision — locked):

- [x] **Game 1: Word Match** — hear word → tap correct tile among Dolch peers  
- [ ] **Game 2: Sentence Fill**  
- [ ] **Game 3: Speed Read**

### Shared requirements
- Pull words from the same Dolch word bank as practice
- Keep interactions simple, visual, and kid-safe
- Provide immediate positive or corrective feedback

### M3 status
- [x] The app now includes a Word Match-style game path conceptually aligned with the PRD
- [x] The experience uses a simple child-friendly interaction model with immediate feedback
- [ ] The full polished game experience and scoring persistence still need deeper runtime validation and refinement

### Honest assessment
The game path is present in the project direction and UI structure, but it should be treated as an initial milestone implementation rather than a fully finished product.

---

## 5. DMMT-style UX critique (M3 review)

**Method:** Cognitive walkthrough as a **7-year-old student** and a **first-year teacher** on first use.

| Screen | Who | Friction observed | M3 fix implemented |
|--------|-----|-------------------|--------------------|
| Landing | Child | No control over startup timing | Added “Tap to start” affordance |
| Reader selection | Child | Role buttons were text-heavy | Larger role buttons with clearer icon cues |
| Word practice | Child | Record button and listening state were unclear | Larger microphone-style button and clearer “Listening…” state |
| Feedback | Child | Score-only feedback felt incomplete | Added a concrete next-step tip card |
| Teacher dashboard | Teacher | Primary actions were not obvious | Added primary actions above the fold |
| Story builder | Teacher | Story flow needed explicit structure | Added clear student/level/interest workflow and preview/approve actions |

### Top 3 M3 UX priorities
1. Make the app easier for young learners with larger buttons, clearer prompts, and more obvious next steps.
2. Make story creation and story reading feel like a natural extension of the reading curriculum.
3. Provide more immediate, encouraging guidance after every activity instead of only showing a score.

---

## 6. Technical dependencies

| System | Owner | Notes |
|--------|-------|-------|
| Team Firebase project | Team | Needed for auth, Firestore, and story backend wiring |
| Cloud Functions / story proxy | Team | Story generation and approval backend path |
| Flutter app | Team | Student/teacher UI and game/story flows |
| PRD + UX notes | Team | This document and milestone 3 documentation |

---

## 7. Sign-off (lock)

| Name | Role | PRD approved | Date |
|------|------|--------------|------|
| Josh Page | Engineering | X | 7/26/26 |
| Tyson Small | Product/UX | X | 7/26/26 |
| Gabriel Walker | AI/Spike | X | 7/26/26 |
