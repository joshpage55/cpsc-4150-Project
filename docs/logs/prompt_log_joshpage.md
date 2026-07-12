# Prompt Log — Josh Page

**Course:** CPSC 4150 · M2

---

## Prompt 1

Scaffold our M2 engineering deliverables in the repo: team plan, PRD draft, story proxy Cloud Function, local spike script, .env.example, and gitignore rules so we never commit API keys.

I used the file layout under docs/milestone2/ and functions/storyPrompt.js. I removed any placeholder keys and made sure .env is gitignored before we add our Canvas key locally.

---

## Prompt 2

What do we need to change so ReadRight passes the M2 Flutter Web requirement? Inherited firebase_options has no web config and the app crashes on startup in Chrome.

I used the kIsWeb guards in main.dart to skip FCM and Firestore init on web. I kept full Firebase web setup as a follow-up after we create our team Firebase web app.

---

## Prompt 3

Write a short Android setup guide for our team so we can run flutter run on the Pixel 9 emulator for the milestone video. Include common Gradle and NDK failures.

I used the NDK version pin in android/app/build.gradle.kts and the note to free disk space before launching a second emulator. I tested until ReadRight installed as com.example.readright.

---

## Prompt 4

We need our own Firebase project for M2 instead of the inherited readright-2ad31 config. What steps should I run for Flutter, Android, iOS, and web?

I used the plan to run flutterfire configure on our team project when ready. I did not swap google-services.json yet because we need the team to create the project and invite everyone first.

---

## Prompt 5

How do I deploy the generateStorySpike function so the Gemini key lives only on the server? We have to use the mini-tier model from our Canvas announcement.

I used firebase functions:secrets:set for GEMINI_API_KEY and the allowlist in storyPrompt.js. I will not call the function from Flutter until M3; teammate runs scripts/m2_story_spike.mjs locally for M2 evidence.

---

## Prompt 6

Draft the backend proxy and secret-handling writeup for Canvas PDF submission, and list what I should show in my video segment for Web and Android.

I used docs/milestone2/BACKEND_PROXY_ARCHITECTURE.md as the PDF source. For video I will show Chrome landing flow, Android on emulator, and explain that the API key is only in the proxy not the app.
