# Josh — M2 Video Segment Script (~90 sec)

Use when recording the team Kaltura video. Adjust names and dates.

---

Hi, I'm Josh. I handled getting our inherited ReadRight app running for Milestone 2.

**Web demo**  
[Screen: Chrome with `flutter run -d chrome`]  
On Flutter Web we see the landing screen and reader selection. We added guards so mobile-only Firebase code does not crash the browser. Full login on web needs our team Firebase web config next.

**Android demo**  
[Screen: emulator with ReadRight open]  
On Android we built and installed the app on the Pixel 9 emulator. This is the real mobile target for pronunciation practice and teacher tools.

**Backend proxy**  
[Screen: `docs/milestone2/BACKEND_PROXY_ARCHITECTURE.md` or terminal spike]  
For the AI story spike, API keys never go in the Flutter app. Calls go through our Cloud Function `generateStorySpike` and the mini-tier model. Keys live in Firebase secrets or local `.env` for testing only.

That covers the engineering checkpoint: app runs on web and mobile, proxy is in place, and we're ready for M3.

---

**Before recording:** emulator running, Chrome tab ready, no secrets visible on screen.
