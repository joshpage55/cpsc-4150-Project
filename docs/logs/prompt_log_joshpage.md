# Prompt Log — Josh Page

**Course:** CPSC 4150 · M3  
**Rule:** Six prompts. Occasional AI help; I own the engineering judgment.

---

## Prompt 1

How do I turn our M2 `generateStorySpike` into a real teacher-only Story Builder callable? I need studentId, classId, reading level, interest, Dolch words, mini-tier lock, and draft docs in Firestore.

I used the production `generateStory` + `approveStory` shape in `functions/index.js` and kept the spike for old evidence scripts. I rejected putting approve-only on the client without a callable — teacher auth has to be checked server-side.

---

## Prompt 2

What’s a simple content-safety filter we can defend for kids’ stories without overengineering? Also how should soft spend alerts work if the course budget isn’t a hard cap?

I used a blocklist + interest validation in `contentSafety.js`, token logs in `ai_usage_logs` / `ai_usage_daily`, and `ai_spend_alerts` when we cross the soft daily budget. I rejected hard-blocking generation on budget — soft alert only, per the syllabus.

---

## Prompt 3

Show me a Flutter StoryService that calls the proxy for generate/approve and tracks the 3 regenerations per day. Person 2 will build the UI on top.

I used `lib/services/story_service.dart` + `story_repository.dart` + `story_model.dart`. I skipped building teacher screens myself so Person 2 can skin the flow.

---

## Prompt 4

The Deepgram API key is hardcoded in `deepgram_assessor.dart`. How do I move transcription behind a Cloud Function like we did for OpenAI?

I used `transcribeAudio` with Firebase secret `DEEPGRAM_API_KEY` and rewrote the assessor to send base64 audio through the callable. I removed the client key entirely — that was non-negotiable for M3.

---

## Prompt 5

Can you sketch a Word Match game engine (hear word → 4 tiles) that pulls from our Dolch `WordModel` list so the UI person isn’t blocked?

I used `lib/games/word_match_engine.dart` for rounds, distractors, audio asset path, and star scoring. I did not build the Start/Gameplay/Results screens — those stay with Person 2.

---

## Prompt 6

Help me draft the 6150 content-safety and cost-instrumentation writeup from what we actually shipped, and suggest a few unit tests I should run before demo.

I used `docs/milestone3/CONTENT_SAFETY_AND_COST.md` plus `test/unit/m3_person1_smoke_test.dart` and `functions/test/contentSafety.test.js`. I left screenshot polish and Canvas packaging for Person 3.
